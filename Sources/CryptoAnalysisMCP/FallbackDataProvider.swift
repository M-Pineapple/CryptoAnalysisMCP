import Foundation
import Logging

/// Tries each `primary` provider in order and falls through to the next
/// on error. The final error is the one from the last provider in the chain.
actor FallbackDataProvider: DataProvider {
    private let providers: [any DataProvider]
    private let logger = Logger(label: "FallbackDataProvider")

    init(_ providers: [any DataProvider]) {
        precondition(!providers.isEmpty, "FallbackDataProvider needs at least one provider")
        self.providers = providers
    }

    var providerName: String { "Fallback" }

    func getCurrentPrice(symbol: String) async throws -> PriceData {
        var lastError: Error = CryptoAnalysisError.invalidSymbol(symbol)
        for provider in providers {
            do {
                let result = try await provider.getCurrentPrice(symbol: symbol)
                let name = await provider.providerName
                logger.info("price \(symbol) resolved via \(name)")
                return result
            } catch {
                let name = await provider.providerName
                logger.info("\(name) failed for \(symbol): \(error.localizedDescription)")
                lastError = error
                continue
            }
        }
        throw lastError
    }

    func getHistoricalData(symbol: String, timeframe: Timeframe, periods: Int) async throws -> [CandleData] {
        var lastError: Error = CryptoAnalysisError.invalidSymbol(symbol)
        for provider in providers {
            do {
                return try await provider.getHistoricalData(symbol: symbol, timeframe: timeframe, periods: periods)
            } catch {
                lastError = error
                continue
            }
        }
        throw lastError
    }
}
