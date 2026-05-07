import Foundation

/// Minimal cross-provider surface used by the analysis handler.
/// Concrete actors (`CryptoDataProvider`, `DexPaprikaDataProvider`) keep
/// their richer per-provider APIs unchanged; this protocol is the
/// portable subset the handler relies on for primary + fallback flow.
protocol DataProvider: Sendable {
    /// Stable diagnostic name; surfaces in logs (e.g. "CoinPaprika", "DexPaprika").
    var providerName: String { get async }

    /// Fetch the latest price snapshot for a symbol (uppercased by caller).
    /// Throws `CryptoAnalysisError.invalidSymbol` for unresolvable input,
    /// `CryptoAnalysisError.networkError` for transport failures.
    func getCurrentPrice(symbol: String) async throws -> PriceData

    /// Fetch historical OHLCV. May throw `CryptoAnalysisError.networkError`
    /// (e.g. a 402 Payment Required from CoinPaprika's free tier).
    func getHistoricalData(symbol: String, timeframe: Timeframe, periods: Int) async throws -> [CandleData]
}
