// StdioIntegrationTests.swift
//
// End-to-end integration tests for the stdio MCP transports. Spawns the
// built `CryptoAnalysisMCP` binary as a subprocess, feeds it JSON-RPC
// requests on stdin, and asserts the JSON-RPC responses on stdout match
// the protocol contract.
//
// This is the only suite that exercises the real `mcp-swift-sdk`
// `Server` + `StdioTransport` (via `--use-sdk`); URLProtocol-mocked
// suites cover the HTTP layer but never the wire-format MCP plumbing.
//
// The legacy `SimpleMCP` path is also covered for parity — both
// transports must agree on the 16-tool surface even though the
// specific JSON wire format may differ (key ordering, etc.).
//
// Tests are `.serialized` because all subprocesses share the same
// binary path and we don't want concurrent spawns fighting over file
// handles or interleaved stdout reads.
//
// Tests are skipped (rather than failing) if the binary hasn't been
// built so that `swift test` works on a fresh checkout — the skip
// reason tells the user to run `swift build` first.

import Testing
import Foundation
@testable import CryptoAnalysisMCP

// MARK: - Binary Path

private enum Binary {
    /// Absolute path to the debug build of the executable.
    /// Resolved relative to the package root, which is the working
    /// directory `swift test` invokes tests from.
    static let path: String = {
        let cwd = FileManager.default.currentDirectoryPath
        return "\(cwd)/.build/debug/CryptoAnalysisMCP"
    }()

    static var exists: Bool {
        FileManager.default.fileExists(atPath: path)
    }
}

// MARK: - Subprocess Helper

/// Spawn the MCP binary, feed it JSON-RPC `requests` (one per line) on
/// stdin, give it a chance to respond, then close stdin to trigger a
/// clean shutdown. Returns the parsed JSON-RPC response lines from
/// stdout (trimmed, blanks dropped).
///
/// Both transports terminate when stdin closes:
///   * Legacy `SimpleMCP` — `readLine()` returns nil on EOF, breaks loop.
///   * SDK `StdioTransport` — closes the transport, server exits.
///
/// We deliberately do NOT close stdin before the responses arrive: the
/// SDK transport tears down immediately on EOF and may exit before
/// servicing buffered requests. The pattern is:
///   1. write all requests with newlines
///   2. wait for the responses (drain stdout in a background task)
///   3. close stdin to terminate the process cleanly
///   4. wait for exit
private func runMCP(
    args: [String],
    requests: [String],
    timeout: TimeInterval = 10.0
) async throws -> [[String: Any]] {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: Binary.path)
    process.arguments = args

    let inputPipe = Pipe()
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardInput = inputPipe
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    try process.run()

    // Write all requests up front, separated by newlines. Don't close
    // stdin yet — both transports exit on EOF, which would cut off
    // unflushed responses on the SDK path in particular.
    let payload = requests.joined(separator: "\n") + "\n"
    if let data = payload.data(using: .utf8) {
        inputPipe.fileHandleForWriting.write(data)
    }

    // Drain stdout in the background so the pipe never fills up. The
    // server emits one JSON object per line; we accumulate until we
    // have one line per request, then signal completion.
    let stdoutHandle = outputPipe.fileHandleForReading
    let expectedLines = requests.count

    let collector = ResponseCollector()

    let drainTask = Task.detached {
        var buffer = Data()
        while !Task.isCancelled {
            let chunk = stdoutHandle.availableData
            if chunk.isEmpty {
                // Brief pause; the writer may not have flushed yet.
                try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
                if await collector.isComplete(expected: expectedLines) {
                    break
                }
                continue
            }
            buffer.append(chunk)
            // Split on newlines; keep the trailing partial chunk for
            // the next iteration if the data ends mid-line.
            while let nlRange = buffer.range(of: Data([0x0A])) {
                let lineData = buffer.subdata(in: 0..<nlRange.lowerBound)
                buffer.removeSubrange(0..<nlRange.upperBound)
                if let line = String(data: lineData, encoding: .utf8) {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        await collector.append(trimmed)
                    }
                }
            }
            if await collector.isComplete(expected: expectedLines) {
                break
            }
        }
    }

    // Wait for either the expected number of responses or the timeout.
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if await collector.isComplete(expected: expectedLines) {
            break
        }
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
    }

    drainTask.cancel()

    // Close stdin → trigger graceful shutdown.
    try? inputPipe.fileHandleForWriting.close()

    // Best-effort exit wait. If the process has already responded and
    // is just slow to notice EOF, we don't want to hang the suite.
    let waitDeadline = Date().addingTimeInterval(2.0)
    while process.isRunning && Date() < waitDeadline {
        try? await Task.sleep(nanoseconds: 50_000_000)
    }
    if process.isRunning {
        process.terminate()
    }

    let lines = await collector.lines

    // Parse each line as JSON. Skip any that don't parse — both
    // transports may emit blank lines on shutdown that we ignored
    // above, but be defensive in case stderr leaked into stdout.
    var parsed: [[String: Any]] = []
    for line in lines {
        guard let data = line.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let dict = obj as? [String: Any]
        else { continue }
        parsed.append(dict)
    }
    return parsed
}

/// Actor that accumulates response lines. Used so the drain task and
/// the polling loop can safely share state without a lock.
private actor ResponseCollector {
    private(set) var lines: [String] = []

    func append(_ line: String) {
        lines.append(line)
    }

    func isComplete(expected: Int) -> Bool {
        lines.count >= expected
    }
}

// MARK: - Expected Tool Surface

/// The 16-tool surface as of v1.2.1. Both transports must expose
/// exactly this set — order doesn't matter, but the names do.
private let expectedTools: Set<String> = [
    // Crypto analysis (CoinPaprika-backed)
    "get_crypto_price",
    "get_technical_indicators",
    "detect_chart_patterns",
    "multi_timeframe_analysis",
    "get_trading_signals",
    "get_support_resistance",
    "get_full_analysis",
    // DexPaprika tools
    "get_token_liquidity",
    "search_tokens_by_network",
    "compare_dex_prices",
    "get_network_pools",
    "get_dex_info",
    "get_pool_analytics",
    "get_pool_ohlcv",
    "get_available_networks",
    "search_tokens_advanced"
]

// MARK: - JSON-RPC Request Fixtures

private enum JSONRPCRequest {
    static let initialize = """
    {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"StdioIntegrationTests","version":"0.1"}}}
    """

    static let toolsList = """
    {"jsonrpc":"2.0","id":2,"method":"tools/list"}
    """

    static let getAvailableNetworks = """
    {"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_available_networks","arguments":{}}}
    """
}

// MARK: - Helpers

/// Pull the response with the given id out of a parsed response array.
private func response(id: Int, in responses: [[String: Any]]) -> [String: Any]? {
    responses.first { ($0["id"] as? Int) == id }
}

/// Extract `result.tools[].name` set from a tools/list response.
private func toolNames(from response: [String: Any]) -> Set<String> {
    guard let result = response["result"] as? [String: Any],
          let tools = result["tools"] as? [[String: Any]]
    else { return [] }
    return Set(tools.compactMap { $0["name"] as? String })
}

// MARK: - Suite

@Suite(
    "Stdio Integration",
    .serialized,
    .disabled(if: !Binary.exists, "Binary not built — run `swift build` first")
)
struct StdioIntegrationTests {

    // MARK: - Test 1: legacy transport

    @Test("Legacy SimpleMCP transport lists all 16 tools")
    func legacyTransportListsAllSixteenTools() async throws {
        let responses = try await runMCP(
            args: ["--transport", "stdio"],
            requests: [JSONRPCRequest.initialize, JSONRPCRequest.toolsList]
        )

        // Two requests in → two responses out.
        try #require(responses.count >= 2, "Expected ≥2 responses, got \(responses.count): \(responses)")

        // initialize response
        let initResp = try #require(response(id: 1, in: responses), "No initialize response")
        let initResult = try #require(initResp["result"] as? [String: Any], "initialize missing result")
        #expect(initResult["protocolVersion"] as? String == "2024-11-05")
        let serverInfo = try #require(initResult["serverInfo"] as? [String: Any], "missing serverInfo")
        #expect(serverInfo["name"] as? String == "crypto-analysis")
        #expect(serverInfo["version"] as? String == "1.2.1")

        // tools/list response
        let listResp = try #require(response(id: 2, in: responses), "No tools/list response")
        let names = toolNames(from: listResp)
        #expect(
            names == expectedTools,
            "Legacy tool surface mismatch.\n  expected: \(expectedTools.sorted())\n  got: \(names.sorted())\n  missing: \(expectedTools.subtracting(names).sorted())\n  extra: \(names.subtracting(expectedTools).sorted())"
        )
        #expect(names.count == 16, "Expected exactly 16 tools, got \(names.count)")
    }

    // MARK: - Test 2: SDK transport

    @Test("SDK transport (--use-sdk) lists all 16 tools")
    func sdkTransportListsAllSixteenTools() async throws {
        let responses = try await runMCP(
            args: ["--use-sdk"],
            requests: [JSONRPCRequest.initialize, JSONRPCRequest.toolsList]
        )

        try #require(responses.count >= 2, "Expected ≥2 responses, got \(responses.count): \(responses)")

        let initResp = try #require(response(id: 1, in: responses), "No initialize response")
        let initResult = try #require(initResp["result"] as? [String: Any], "initialize missing result")
        #expect(initResult["protocolVersion"] as? String == "2024-11-05")
        let serverInfo = try #require(initResult["serverInfo"] as? [String: Any], "missing serverInfo")
        #expect(serverInfo["name"] as? String == "crypto-analysis")
        #expect(serverInfo["version"] as? String == "1.2.1")

        let listResp = try #require(response(id: 2, in: responses), "No tools/list response")
        let names = toolNames(from: listResp)
        #expect(
            names == expectedTools,
            "SDK tool surface mismatch.\n  expected: \(expectedTools.sorted())\n  got: \(names.sorted())\n  missing: \(expectedTools.subtracting(names).sorted())\n  extra: \(names.subtracting(expectedTools).sorted())"
        )
        #expect(names.count == 16, "Expected exactly 16 tools, got \(names.count)")
    }

    // MARK: - Test 3: SDK transport tools/call

    @Test("SDK transport responds to tools/call with content array")
    func sdkTransportRespondsToToolsCall() async throws {
        // get_available_networks takes no args and is the lightest
        // tool to exercise — a single GET to api.dexpaprika.com.
        // We assert on the *shape* of the response, not the body,
        // because the body depends on whether the network is reachable.
        let responses = try await runMCP(
            args: ["--use-sdk"],
            requests: [
                JSONRPCRequest.initialize,
                JSONRPCRequest.getAvailableNetworks
            ],
            // Bumped — `get_available_networks` issues a real HTTP
            // call, so we need to allow for network latency.
            timeout: 15.0
        )

        try #require(responses.count >= 2, "Expected ≥2 responses, got \(responses.count): \(responses)")

        let callResp = try #require(response(id: 3, in: responses), "No tools/call response")
        let result = try #require(callResp["result"] as? [String: Any], "tools/call missing result")

        let content = try #require(result["content"] as? [[String: Any]], "result.content not an array of dicts")
        try #require(!content.isEmpty, "content array is empty")

        let first = content[0]
        #expect(first["type"] as? String == "text", "Expected first content element type=text")
        let text = try #require(first["text"] as? String, "first content element missing text field")
        #expect(!text.isEmpty, "text field is empty")

        // The text payload should itself be JSON-parseable. We don't
        // assert anything about its contents — that depends on whether
        // the upstream API was reachable when the test ran. If it was
        // reachable we get a `networks` list; if not, an `error` key.
        // Either way, valid JSON is the contract.
        let textData = try #require(text.data(using: .utf8))
        let parsedText = try #require(
            try? JSONSerialization.jsonObject(with: textData),
            "tools/call result text was not valid JSON: \(text.prefix(200))"
        )
        #expect(parsedText is [String: Any], "tools/call result text should be a JSON object")

        // result.isError is optional in the spec but the SDK emits it
        // explicitly as false on success. Don't assert; the network may
        // be unreachable in CI and the handler still returns content.
    }
}
