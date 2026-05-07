// AuthPathTests.swift
//
// Locks in the donbagger-fixed auth-path semantics for CoinPaprika:
//   * Free tier hits api.coinpaprika.com and never sends Authorization.
//   * Paid tier hits api-pro.coinpaprika.com and sends the bare API key
//     (NO `Bearer ` prefix — that triggers a Cloudflare 403).
//   * The /search endpoint is requested with a trailing slash so that
//     the 301 redirect (which strips Authorization on URLSession) is
//     avoided.
//
// The stub is a `URLProtocol` registered globally so that
// `URLSession.shared` requests are captured without the actor knowing.

import Testing
import Foundation
@testable import CryptoAnalysisMCP

// MARK: - URLProtocol stub

final class CapturingURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var captured: [URLRequest] = []
    nonisolated(unsafe) static var stubBody: Data = Data("{}".utf8)
    nonisolated(unsafe) static var stubStatus: Int = 200

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.captured.append(request)
        let resp = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.stubStatus,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.stubBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        captured = []
        stubBody = Data("{}".utf8)
        stubStatus = 200
    }
}

// MARK: - Fixtures

private enum Fixture {
    /// A minimal-but-complete `CoinPaprikaTickerResponse`. All required
    /// non-optional fields are present so JSONDecoder succeeds.
    static let btcTickerJSON: Data = Data("""
    {
      "id": "btc-bitcoin",
      "name": "Bitcoin",
      "symbol": "BTC",
      "rank": 1,
      "quotes": {
        "USD": {
          "price": 50000.0,
          "volume_24h": 1000000.0,
          "percent_change_24h": 1.5,
          "percent_change_7d": 2.0,
          "percent_change_30d": 3.0,
          "percent_change_1y": 4.0,
          "market_cap": 950000000000.0
        }
      }
    }
    """.utf8)

    /// A minimal `CoinPaprikaSearchResponse` containing one currency that
    /// matches the symbol "ZZZ". The test uses an unmapped symbol so that
    /// `getCurrentPrice` falls through to `searchCrypto`.
    static let zzzSearchJSON: Data = Data("""
    {
      "currencies": [
        {
          "id": "zzz-zzz",
          "name": "ZZZ Token",
          "symbol": "ZZZ",
          "rank": 9999
        }
      ]
    }
    """.utf8)
}

// MARK: - Suite

@Suite(.serialized)
struct AuthPathTests {

    init() {
        URLProtocol.registerClass(CapturingURLProtocol.self)
        CapturingURLProtocol.reset()
    }

    @Test func freeTierUsesPublicHostNoAuthHeader() async throws {
        // Ensure no API key is in the environment when the actor reads
        // `ProcessInfo.processInfo.environment` during property init.
        unsetenv("COINPAPRIKA_API_KEY")
        CapturingURLProtocol.stubBody = Fixture.btcTickerJSON
        CapturingURLProtocol.stubStatus = 200

        let provider = CryptoDataProvider()
        // BTC is in the static symbol mapping, so this is a single-hop
        // call to /tickers/btc-bitcoin — no search round-trip needed.
        let price = try await provider.getCurrentPrice(symbol: "BTC")

        #expect(price.symbol == "BTC")
        #expect(price.price == 50000.0)

        let captured = CapturingURLProtocol.captured
        try #require(!captured.isEmpty, "Expected at least one captured request")

        let req = try #require(captured.first)
        let url = try #require(req.url)
        #expect(
            url.host == "api.coinpaprika.com",
            "Free tier should use api.coinpaprika.com, got \(url.host ?? "nil")"
        )
        #expect(
            req.value(forHTTPHeaderField: "Authorization") == nil,
            "Free tier must not send an Authorization header"
        )
    }

    @Test func paidTierUsesProHostBareAuthHeader() async throws {
        setenv("COINPAPRIKA_API_KEY", "test-key-123", 1)
        defer { unsetenv("COINPAPRIKA_API_KEY") }

        CapturingURLProtocol.stubBody = Fixture.btcTickerJSON
        CapturingURLProtocol.stubStatus = 200

        let provider = CryptoDataProvider()
        _ = try await provider.getCurrentPrice(symbol: "BTC")

        let captured = CapturingURLProtocol.captured
        try #require(!captured.isEmpty, "Expected at least one captured request")

        let req = try #require(captured.first)
        let url = try #require(req.url)
        #expect(
            url.host == "api-pro.coinpaprika.com",
            "Paid tier should use api-pro.coinpaprika.com, got \(url.host ?? "nil")"
        )
        let authHeader = req.value(forHTTPHeaderField: "Authorization")
        #expect(
            authHeader == "test-key-123",
            "Paid tier should send bare API key (no Bearer prefix), got \(authHeader ?? "nil")"
        )
        #expect(
            authHeader?.hasPrefix("Bearer ") == false,
            "Authorization must NOT start with `Bearer ` — that triggers a Cloudflare 403"
        )
    }

    @Test func searchUsesTrailingSlashEndpoint() async throws {
        // No API key needed for this assertion — we only care about path
        // shape. Use the public host to keep things simple.
        unsetenv("COINPAPRIKA_API_KEY")
        CapturingURLProtocol.stubBody = Fixture.zzzSearchJSON
        CapturingURLProtocol.stubStatus = 200

        let provider = CryptoDataProvider()
        _ = try await provider.searchCrypto(query: "ZZZ")

        let captured = CapturingURLProtocol.captured
        try #require(!captured.isEmpty, "Expected at least one captured request")

        // Find the /search request (there should be exactly one).
        let searchReq = try #require(
            captured.first(where: { $0.url?.path.contains("/search") == true }),
            "Expected a request to a /search path"
        )
        let url = try #require(searchReq.url)

        // The trailing slash MUST be present. Without it, CoinPaprika
        // responds with a 301 to the trailing-slash form, and URLSession
        // strips the Authorization header on the redirect — which then
        // fails with a Cloudflare 403 against api-pro. Hitting the
        // trailing-slash form directly avoids the redirect entirely.
        //
        // Foundation's `URL.path` accessor normalises away a trailing
        // slash, so we assert against the full `absoluteString` to see
        // the slash that's actually on the wire.
        let absolute = url.absoluteString
        #expect(
            absolute.contains("/search/?"),
            "Expected `/search/?...` (with trailing slash before `?`) on the wire, got \(absolute)"
        )
        #expect(
            !absolute.contains("/search?"),
            "URL must not be the trailing-slash-less `/search?...` form — that hits the 301-strips-Authorization redirect"
        )
        // Sanity: the query is on the URL, not the path.
        let query = url.query ?? ""
        #expect(query.contains("q=ZZZ"), "Expected ?q=ZZZ in query, got \(query)")
    }
}
