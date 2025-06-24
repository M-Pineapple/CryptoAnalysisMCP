import Foundation
import Logging

/// Provides cryptocurrency data from various sources
actor CryptoDataProvider {
    private let logger = Logger(label: "CryptoDataProvider")
    
    // CoinPaprika API configuration
    private let coinPaprikaBaseURL = "https://api.coinpaprika.com/v1"
    
    // API Key - Set this if you have a paid CoinPaprika subscription
    // You can also set the COINPAPRIKA_API_KEY environment variable
    private let apiKey: String? = ProcessInfo.processInfo.environment["COINPAPRIKA_API_KEY"]
    
    // Cache for performance
    private var priceCache: [String: (data: PriceData, timestamp: Date)] = [:]
    private var historicalCache: [String: (data: [CandleData], timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 60 // 1 minute for price data
    private let historicalCacheTimeout: TimeInterval = 300 // 5 minutes for historical data
    
    // Symbol mapping for CoinPaprika - commonly used coins for performance
    private let symbolMapping: [String: String] = [
        "BTC": "btc-bitcoin",
        "ETH": "eth-ethereum",
        "ADA": "ada-cardano",
        "DOT": "dot-polkadot",
        "LINK": "link-chainlink",
        "SOL": "sol-solana",
        "MATIC": "matic-polygon",
        "AVAX": "avax-avalanche",
        "ATOM": "atom-cosmos",
        "XRP": "xrp-xrp",
        "BNB": "bnb-binance-coin",
        "DOGE": "doge-dogecoin",
        "SHIB": "shib-shiba-inu",
        "UNI": "uni-uniswap",
        "LTC": "ltc-litecoin",
        "ALGO": "algo-algorand",
        "VET": "vet-vechain",
        "FTM": "ftm-fantom",
        "NEAR": "near-near-protocol",
        "AAVE": "aave-aave",
        "RNDR": "rndr-render-token",
        "RENDER": "rndr-render-token",
        "SUI": "sui-sui",
        "APT": "apt-aptos",
        "ARB": "arb-arbitrum",
        "OP": "op-optimism"
    ]
    
    // Cache for dynamically resolved coin IDs
    private var coinIdCache: [String: String] = [:]
    
    /// Resolve a symbol to a CoinPaprika coin ID
    private func resolveCoinId(for symbol: String) async throws -> String {
        let upperSymbol = symbol.uppercased()
        
        // Check static mapping first
        if let mappedId = symbolMapping[upperSymbol] {
            return mappedId
        }
        
        // Check dynamic cache
        if let cachedId = coinIdCache[upperSymbol] {
            return cachedId
        }
        
        // Search for the coin dynamically
        logger.info("Symbol \(upperSymbol) not in mapping, searching dynamically...")
        let searchResults = try await searchCrypto(query: upperSymbol)
        
        // Find exact match or first result with matching symbol
        let coinId: String
        if let exactMatch = searchResults.first(where: { $0.symbol.uppercased() == upperSymbol }) {
            coinId = exactMatch.id
            logger.info("Found exact match: \(exactMatch.name) (\(coinId))")
        } else if let firstResult = searchResults.first {
            // Use first result if no exact match
            coinId = firstResult.id
            logger.info("Using first search result: \(firstResult.name) (\(coinId))")
        } else {
            throw CryptoAnalysisError.invalidSymbol("\(upperSymbol) - No results found")
        }
        
        // Cache the result
        coinIdCache[upperSymbol] = coinId
        
        return coinId
    }
    
    /// Get current price data for a cryptocurrency
    func getCurrentPrice(symbol: String) async throws -> PriceData {
        let upperSymbol = symbol.uppercased()
        
        // Check cache first
        if let cached = priceCache[upperSymbol],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            logger.info("Returning cached price for \(upperSymbol)")
            return cached.data
        }
        
        // Get CoinPaprika ID dynamically
        let coinId = try await resolveCoinId(for: upperSymbol)
        
        // Fetch from CoinPaprika ticker endpoint
        let urlString = "\(coinPaprikaBaseURL)/tickers/\(coinId)"
        guard let url = URL(string: urlString) else {
            throw CryptoAnalysisError.networkError("Invalid URL")
        }
        
        logger.info("Fetching price data for \(upperSymbol) from CoinPaprika")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CryptoAnalysisError.networkError("Invalid response")
            }
            
            // Check for payment required error
            if httpResponse.statusCode == 402 {
                throw CryptoAnalysisError.networkError("This endpoint requires a paid CoinPaprika API subscription. Free tier includes 1 year of daily historical data - try using 'daily' timeframe.")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw CryptoAnalysisError.networkError("HTTP Error \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let tickerResponse = try decoder.decode(CoinPaprikaTickerResponse.self, from: data)
            
            let priceData = PriceData(
                symbol: upperSymbol,
                price: tickerResponse.quotes.USD.price,
                change24h: tickerResponse.quotes.USD.price - (tickerResponse.quotes.USD.price / (1 + tickerResponse.quotes.USD.percentChange24h / 100)),
                changePercent24h: tickerResponse.quotes.USD.percentChange24h,
                volume24h: tickerResponse.quotes.USD.volume24h,
                marketCap: tickerResponse.quotes.USD.marketCap,
                timestamp: Date(),
                rank: tickerResponse.rank,
                percentChange15m: tickerResponse.quotes.USD.percentChange15m,
                percentChange30m: tickerResponse.quotes.USD.percentChange30m,
                percentChange1h: tickerResponse.quotes.USD.percentChange1h,
                percentChange6h: tickerResponse.quotes.USD.percentChange6h,
                percentChange12h: tickerResponse.quotes.USD.percentChange12h,
                percentChange7d: tickerResponse.quotes.USD.percentChange7d,
                percentChange30d: tickerResponse.quotes.USD.percentChange30d,
                percentChange1y: tickerResponse.quotes.USD.percentChange1y,
                athPrice: tickerResponse.quotes.USD.athPrice,
                athDate: tickerResponse.quotes.USD.athDate != nil ? ISO8601DateFormatter().date(from: tickerResponse.quotes.USD.athDate!) : nil
            )
            
            // Cache the result
            priceCache[upperSymbol] = (priceData, Date())
            
            return priceData
            
        } catch {
            logger.error("Failed to fetch price data: \(error)")
            throw CryptoAnalysisError.networkError(error.localizedDescription)
        }
    }
    
    /// Get historical OHLCV data
    func getHistoricalData(symbol: String, timeframe: Timeframe, periods: Int = 100) async throws -> [CandleData] {
        let upperSymbol = symbol.uppercased()
        let cacheKey = "\(upperSymbol)_\(timeframe.rawValue)_\(periods)"
        
        // Check cache first
        if let cached = historicalCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < historicalCacheTimeout {
            logger.info("Returning cached historical data for \(upperSymbol)")
            return cached.data
        }
        
        // Get CoinPaprika ID dynamically
        let coinId = try await resolveCoinId(for: upperSymbol)
        
        // Calculate date range
        let endDate = Date()
        let startDate: Date
        
        switch timeframe {
        case .fourHour:
            startDate = endDate.addingTimeInterval(-Double(periods) * 4 * 60 * 60)
        case .daily:
            startDate = endDate.addingTimeInterval(-Double(periods) * 24 * 60 * 60)
        case .weekly:
            startDate = endDate.addingTimeInterval(-Double(periods) * 7 * 24 * 60 * 60)
        case .monthly:
            startDate = endDate.addingTimeInterval(-Double(periods) * 30 * 24 * 60 * 60)
        }
        
        // Format dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        // Construct URL for OHLCV data
        let interval: String
        switch timeframe {
        case .fourHour:
            interval = "4h"
        case .daily:
            interval = "1d"
        case .weekly:
            interval = "7d"
        case .monthly:
            interval = "30d"
        }
        
        var urlString = "\(coinPaprikaBaseURL)/coins/\(coinId)/ohlcv/historical?start=\(startDateString)&end=\(endDateString)&interval=\(interval)"
        
        // Add API key if available
        if let apiKey = apiKey {
            urlString += "&apikey=\(apiKey)"
        }
        
        guard let url = URL(string: urlString) else {
            throw CryptoAnalysisError.networkError("Invalid URL")
        }
        
        logger.info("Fetching historical data for \(upperSymbol) from \(startDateString) to \(endDateString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CryptoAnalysisError.networkError("Invalid response")
            }
            
            // Check for payment required error
            if httpResponse.statusCode == 402 {
                throw CryptoAnalysisError.networkError("This endpoint requires a paid CoinPaprika API subscription. Free tier includes 1 year of daily historical data - try using 'daily' timeframe.")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw CryptoAnalysisError.networkError("HTTP Error \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let ohlcvResponse = try decoder.decode([CoinPaprikaOHLCVResponse].self, from: data)
            
            // Convert to CandleData
            let candles = ohlcvResponse.map { ohlcv in
                CandleData(
                    timestamp: ISO8601DateFormatter().date(from: ohlcv.timeOpen) ?? Date(),
                    open: ohlcv.open,
                    high: ohlcv.high,
                    low: ohlcv.low,
                    close: ohlcv.close,
                    volume: ohlcv.volume
                )
            }.sorted { $0.timestamp < $1.timestamp }
            
            // Cache the result
            historicalCache[cacheKey] = (candles, Date())
            
            logger.info("Retrieved \(candles.count) candles for \(upperSymbol)")
            
            return candles
            
        } catch {
            logger.error("Failed to fetch historical data: \(error)")
            throw error
        }
    }
    

}

// MARK: - CoinPaprika Response Models

private struct CoinPaprikaTickerResponse: Codable {
    let id: String
    let name: String
    let symbol: String
    let rank: Int
    let quotes: CoinPaprikaQuotes
}

private struct CoinPaprikaQuotes: Codable {
    let USD: CoinPaprikaQuoteData
}

private struct CoinPaprikaQuoteData: Codable {
    let price: Double
    let volume24h: Double
    let percentChange24h: Double
    let percentChange7d: Double
    let percentChange30d: Double
    let percentChange1y: Double
    let marketCap: Double
    let athPrice: Double?
    let athDate: String?
    let percentChange15m: Double?
    let percentChange30m: Double?
    let percentChange1h: Double?
    let percentChange6h: Double?
    let percentChange12h: Double?
    
    private enum CodingKeys: String, CodingKey {
        case price
        case volume24h = "volume_24h"
        case percentChange24h = "percent_change_24h"
        case percentChange7d = "percent_change_7d"
        case percentChange30d = "percent_change_30d"
        case percentChange1y = "percent_change_1y"
        case marketCap = "market_cap"
        case athPrice = "ath_price"
        case athDate = "ath_date"
        case percentChange15m = "percent_change_15m"
        case percentChange30m = "percent_change_30m"
        case percentChange1h = "percent_change_1h"
        case percentChange6h = "percent_change_6h"
        case percentChange12h = "percent_change_12h"
    }
}

private struct CoinPaprikaOHLCVResponse: Codable {
    let timeOpen: String
    let timeClose: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    let marketCap: Double
    
    private enum CodingKeys: String, CodingKey {
        case timeOpen = "time_open"
        case timeClose = "time_close"
        case open
        case high
        case low
        case close
        case volume
        case marketCap = "market_cap"
    }
}

// MARK: - Additional Data Methods
extension CryptoDataProvider {
    
    /// Get list of available cryptocurrencies
    func getAvailableSymbols() async -> [String] {
        return Array(symbolMapping.keys).sorted()
    }
    
    /// Search for cryptocurrency by name or symbol
    func searchCrypto(query: String) async throws -> [(symbol: String, name: String, id: String)] {
        let urlString = "\(coinPaprikaBaseURL)/search?q=\(query)&limit=10"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            throw CryptoAnalysisError.networkError("Invalid URL")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CryptoAnalysisError.networkError("Invalid response")
            }
            
            let searchResponse = try JSONDecoder().decode(CoinPaprikaSearchResponse.self, from: data)
            
            return searchResponse.currencies.map { currency in
                (symbol: currency.symbol, name: currency.name, id: currency.id)
            }
        } catch {
            logger.error("Search failed: \(error)")
            throw CryptoAnalysisError.networkError(error.localizedDescription)
        }
    }
    
    /// Clear all caches
    func clearCache() async {
        priceCache.removeAll()
        historicalCache.removeAll()
        logger.info("Cleared all caches")
    }
}

private struct CoinPaprikaSearchResponse: Codable {
    let currencies: [CoinPaprikaSearchResult]
}

private struct CoinPaprikaSearchResult: Codable {
    let id: String
    let name: String
    let symbol: String
    let rank: Int
}
