import Foundation
import Logging
import MCP

// MARK: - SDK Bridge
//
// Side-by-side opt-in path that wires the existing 16-tool surface onto the
// official `mcp-swift-sdk` (v0.12.1). Selected via `--use-sdk`. Default
// behavior remains the in-tree `SimpleMCP` implementation in `SimpleMCP.swift`.
//
// Note: the SDK exposes its own `MCPError` enum in module `MCP`, which
// collides by name with the local struct of the same name in `SimpleMCP.swift`.
// We disambiguate by qualifying as `MCP.MCPError`.

/// Wraps the SDK's `Server` actor and exposes the same `MCPTool` registration
/// surface used by the legacy path, so `Main.swift` can register both paths
/// against a common `ToolRegistrar` protocol.
///
/// Implemented as a non-Sendable `final class` rather than an actor: every
/// caller (registration during startup; `runStdio()` once) executes in the
/// same isolation domain as the `@main` task, so we don't need actor
/// isolation. The cross-isolation hop happens inside `runStdio()` when the
/// SDK's `Server` actor captures the (Sendable) tool snapshot below.
final class MCPSDKBridge {
    // MARK: - Types

    /// A Sendable snapshot of the bits of `MCPTool` we need across the
    /// `@Sendable` handler boundary. `MCPTool.inputSchema` is `[String: Any]`
    /// and not Sendable; this type holds the SDK's `Value` translation
    /// directly, so nothing untyped escapes into the handler closure.
    private struct ToolEntry: Sendable {
        let name: String
        let description: String
        let inputSchema: Value
        let handler: @Sendable (sending [String: Any]) async -> sending [String: Any]
    }

    // MARK: - Properties

    private let logger = Logger(label: "MCPSDKBridge")
    private let serverName: String
    private let serverVersion: String
    private var tools: [String: ToolEntry] = [:]

    // MARK: - Initialization

    init(name: String, version: String) {
        self.serverName = name
        self.serverVersion = version
    }

    // MARK: - Public Methods

    /// Register a tool. Same shape as `MCPServer.addTool`. We translate the
    /// legacy `[String: Any]` schema into the SDK's `Value` here so the
    /// `@Sendable` handlers below see only Sendable storage.
    func register(_ tool: MCPTool) {
        tools[tool.name] = ToolEntry(
            name: tool.name,
            description: tool.description,
            inputSchema: Self.bridgeAnyToValue(tool.inputSchema),
            handler: tool.handler
        )
    }

    /// Start the SDK server on stdio and run until the transport closes.
    func runStdio() async throws {
        let server = Server(
            name: serverName,
            version: serverVersion,
            capabilities: .init(tools: .init(listChanged: false))
        )

        // Snapshot the registered tools into a Sendable local so the handler
        // closures don't capture `self` (which is non-Sendable on purpose).
        let toolMap = self.tools

        // tools/list — emit the same name/description/inputSchema we registered.
        await server.withMethodHandler(ListTools.self) { _ in
            let toolList = toolMap.values.map { entry in
                Tool(
                    name: entry.name,
                    description: entry.description,
                    inputSchema: entry.inputSchema
                )
            }
            return .init(tools: toolList)
        }

        // tools/call — look up the registered handler, dispatch, and re-wrap
        // the result as JSON text content.
        await server.withMethodHandler(CallTool.self) { params in
            guard let entry = toolMap[params.name] else {
                throw MCP.MCPError.methodNotFound("Tool not found: \(params.name)")
            }
            let arguments = Self.bridgeArgsToAnyDict(params.arguments)
            let result = await entry.handler(arguments)
            if let json = try? JSONSerialization.data(withJSONObject: result, options: []),
               let text = String(data: json, encoding: .utf8) {
                return .init(
                    content: [.text(text: text, annotations: nil, _meta: nil)],
                    isError: false
                )
            } else {
                let fallback = "{\"error\": \"failed to encode tool result\"}"
                return .init(
                    content: [.text(text: fallback, annotations: nil, _meta: nil)],
                    isError: true
                )
            }
        }

        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }

    // MARK: - Private Methods (Value <-> Any bridging)

    /// Convert the SDK's `[String: Value]?` arguments into the existing
    /// `[String: Any]` dictionary the legacy tool handlers expect.
    private static func bridgeArgsToAnyDict(_ args: [String: Value]?) -> [String: Any] {
        guard let args else { return [:] }
        var out: [String: Any] = [:]
        for (key, value) in args {
            out[key] = bridgeValueToAny(value)
        }
        return out
    }

    /// Recursively unwrap `MCP.Value` into a JSON-compatible `Any`.
    /// Mirrors the JSON leaf set used by `JSONSerialization`.
    private static func bridgeValueToAny(_ value: Value) -> Any {
        switch value {
        case .null:
            return NSNull()
        case .bool(let b):
            return b
        case .int(let i):
            return i
        case .double(let d):
            return d
        case .string(let s):
            return s
        case .data(_, let d):
            // Preserve as base64 to keep the JSON-able invariant.
            return d.base64EncodedString()
        case .array(let arr):
            return arr.map { bridgeValueToAny($0) }
        case .object(let dict):
            var out: [String: Any] = [:]
            for (k, v) in dict {
                out[k] = bridgeValueToAny(v)
            }
            return out
        }
    }

    /// Convert the legacy `[String: Any]` schema into a `Value` for the SDK's
    /// `Tool(inputSchema:)` parameter. Inverse of `bridgeValueToAny`. Drops
    /// any leaf that isn't a JSON-compatible primitive.
    private static func bridgeAnyToValue(_ any: Any) -> Value {
        switch any {
        case is NSNull:
            return .null
        case let v as Bool:
            return .bool(v)
        case let v as Int:
            return .int(v)
        case let v as Double:
            return .double(v)
        case let v as String:
            return .string(v)
        case let v as [Any]:
            return .array(v.map { bridgeAnyToValue($0) })
        case let v as [String: Any]:
            var out: [String: Value] = [:]
            for (k, value) in v {
                out[k] = bridgeAnyToValue(value)
            }
            return .object(out)
        default:
            // Unknown — represent as null rather than crashing. Schema leaves
            // are well-defined JSON in our usage so this branch is unreachable.
            return .null
        }
    }
}

// MARK: - ToolRegistrar Protocol

/// Common registration surface used by `registerTools` / `registerDexPaprikaTools`
/// so the same call sites can target either backend. Declared `async` so an
/// actor-isolated implementation could conform; both current conformers
/// (`MCPServer` and `MCPSDKBridge`) are non-isolated classes and run their
/// register synchronously.
protocol ToolRegistrar {
    func register(_ tool: MCPTool) async
}

extension MCPServer: ToolRegistrar {
    /// Async-front the existing synchronous `addTool` for protocol parity.
    func register(_ tool: MCPTool) async {
        addTool(tool)
    }
}

extension MCPSDKBridge: ToolRegistrar {}
