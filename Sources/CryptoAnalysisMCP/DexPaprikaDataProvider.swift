import Foundation
import Logging

/// Provides cryptocurrency data from DexPaprika API - 7+ million tokens!
/// NO API KEY REQUIRED - Completely free access
actor DexPaprikaDataProvider {
    private let logger = Logger(label: "DexPaprikaDataProvider")
    
    // DexPaprika API configuration
    private let dexPaprikaBaseURL = "https://api.dexpaprika.com"
    
    // Cache for performance
    private var tokenCache: [String: (data: DexPaprikaToken, timestamp: Date)] = [:]
    private var networkCache: [String: [DexPaprikaNetwork]] = [:]
    private let cacheTimeout: TimeInterval = 60 // 1 minute for price data
    
    // Network name to ID mapping for common networks
    private let networkMapping: [String: String] = [
        "ethereum": "ethereum",
        "eth": "ethereum",
        "binance": "binance-smart-chain",
        "bsc": "binance-smart-chain",
        "polygon": "polygon",
        "matic": "polygon",
        "arbitrum": "arbitrum",
        "arb": "arbitrum",
        "optimism": "optimism",
        "op": "optimism",
        "avalanche": "avalanche-c-chain",
        "avax": "avalanche-c-chain",
        "fantom": "fantom",
        "ftm": "fantom",
        "solana": "solana",
        "sol": "solana",
        "base": "base",
        "zksync": "zksync-era",
        "linea": "linea",
        "mantle": "mantle",
        "blast": "blast"
    ]
    
    /// Get available networks
    func getNetworks() async throws -> [DexPaprikaNetwork] {
        // Check cache first
        if let cached = networkCache["all"], !cached.isEmpty {
            return cached
        }
        
        let urlString = "\(dexPaprikaBaseURL)/networks"
        guard let url = URL(string: urlString) else {
            throw CryptoAnalysisError.networkError("Invalid URL")
        }
        
        logger.info("Fetching available networks from DexPaprika")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CryptoAnalysisError.networkError("Invalid response")
            }
            
            let networks = try JSONDecoder().decode([DexPaprikaNetwork].self, from: data)
            
            // Cache the result
            networkCache["all"] = networks
            
            logger.info("Found \(networks.count) networks on DexPaprika")
            return networks
            
        } catch {
            logger.error("Failed to fetch networks: \(error)")
            throw error
        }
    }
    
    /// Search for tokens across all networks
    func searchToken(query: String, limit: Int = 10) async throws -> [DexPaprikaSearchResult] {
        let urlString = "\(dexPaprikaBaseURL)/search?query=\(query)&limit=\(limit)"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            throw CryptoAnalysisError.networkError("Invalid URL")
        }
        
        logger.info("Searching for '\(query)' on DexPaprika")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CryptoAnalysisError.networkError("Invalid response")
            }
            
            let searchResponse = try JSONDecoder().decode(DexPaprikaSearchResponse.self, from: data)
            
            logger.info("Found \(searchResponse.tokens.count) tokens matching '\(query)'")
            return searchResponse.tokens
            
        } catch {
            logger.error("Search failed: \(error)")
            throw error
        }
    }
    
    /// Get token data by network and address
    func getToken(network: String, address: String) async throws -> DexPaprikaToken {
        let cacheKey = "\(network)_\(address)"
        
        // Check cache first
        if let cached = tokenCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            logger.info("Returning cached data for \(cacheKey)")
            return cached.data
        }
        
        // Resolve network name to ID if needed
        let networkId = networkMapping[network.lowercased()] ?? network.lowercased()
        
        let urlString = "\(dexPaprikaBaseURL)/networks/\(networkId)/tokens/\(address)"
        guard let url = URL(string: urlString) else {
            throw CryptoAnalysisError.networkError("Invalid URL")
        }
        
        logger.info("Fetching token data from DexPaprika: \(networkId)/\(address)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CryptoAnalysisError.networkError("Invalid response")
            }
            
            if httpResponse.statusCode == 404 {
                throw CryptoAnalysisError.invalidSymbol("Token not found on DexPaprika: \(address) on \(networkId)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw CryptoAnalysisError.networkError("HTTP Error \(httpResponse.statusCode)")
            }
            
            let token = try JSONDecoder().decode(DexPaprikaToken.self, from: data)
            
            // Cache the result
            tokenCache[cacheKey] = (token, Date())
            
            logger.info("Retrieved token: \(token.name) (\(token.symbol))")
            return token
            
        } catch {
            logger.error("Failed to fetch token data: \(error)")
            throw error
        }
    }
    
    /// Convert DexPaprika token data to standard PriceData format
    func convertToPriceData(token: DexPaprikaToken) -> PriceData {
        let summary = token.summary
        return PriceData(
            symbol: token.symbol.uppercased(),
            price: summary.priceUsd,
            change24h: summary.priceUsd * (summary.priceChange24h / 100),
            changePercent24h: summary.priceChange24h,
            volume24h: summary.volumeUsd24h,
            marketCap: summary.liquidityUsd ?? 0,
            timestamp: Date(),
            rank: 0, // DexPaprika doesn't provide rank
            // Additional time-based changes not available from DexPaprika
            percentChange15m: nil,
            percentChange30m: nil,
            percentChange1h: nil,
            percentChange6h: nil,
            percentChange12h: nil,
            percentChange7d: nil,
            percentChange30d: nil,
            percentChange1y: nil,
            athPrice: nil,
            athDate: nil
        )
    }
    
    /// Get token by symbol (searches across all networks)
    func getTokenBySymbol(_ symbol: String) async throws -> DexPaprikaToken {
        // First, search for the token
        let searchResults = try await searchToken(query: symbol, limit: 20)
        
        // Find exact match or best match
        let upperSymbol = symbol.uppercased()
        
        if let exactMatch = searchResults.first(where: { $0.symbol.uppercased() == upperSymbol }) {
            // Get the full token data
            return try await getToken(network: exactMatch.networkId, address: exactMatch.address)
        } else if let firstResult = searchResults.first {
            logger.info("No exact match for \(upperSymbol), using first result: \(firstResult.name)")
            return try await getToken(network: firstResult.networkId, address: firstResult.address)
        } else {
            throw CryptoAnalysisError.invalidSymbol("\(upperSymbol) - Not found on any DEX")
        }
    }
    
    /// Clear all caches
    func clearCache() async {
        tokenCache.removeAll()
        networkCache.removeAll()
        logger.info("Cleared all DexPaprika caches")
    }
}

// MARK: - DexPaprika Response Models

struct DexPaprikaNetwork: Codable {
    let id: String
    let name: String
    let shortName: String
    let chainId: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortName = "short_name"
        case chainId = "chain_id"
    }
}

struct DexPaprikaSearchResponse: Codable {
    let tokens: [DexPaprikaSearchResult]
}

struct DexPaprikaSearchResult: Codable {
    let name: String
    let symbol: String
    let address: String
    let networkId: String
    let networkName: String
    let logoUrl: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case symbol
        case address
        case networkId = "network_id"
        case networkName = "network_name"
        case logoUrl = "logo_url"
    }
}

struct DexPaprikaToken: Codable {
    let name: String
    let symbol: String
    let address: String
    let decimals: Int
    let logoUrl: String?
    let summary: DexPaprikaSummary
    let network: DexPaprikaNetworkInfo
    
    private enum CodingKeys: String, CodingKey {
        case name
        case symbol
        case address
        case decimals
        case logoUrl = "logo_url"
        case summary
        case network
    }
}

struct DexPaprikaSummary: Codable {
    let priceUsd: Double
    let priceChange24h: Double
    let volumeUsd24h: Double
    let liquidityUsd: Double?
    let totalSupply: Double?
    let circulatingSupply: Double?
    let holders: Int?
    
    private enum CodingKeys: String, CodingKey {
        case priceUsd = "price_usd"
        case priceChange24h = "price_change_24h"
        case volumeUsd24h = "volume_usd_24h"
        case liquidityUsd = "liquidity_usd"
        case totalSupply = "total_supply"
        case circulatingSupply = "circulating_supply"
        case holders
    }
}

struct DexPaprikaNetworkInfo: Codable {
    let id: String
    let name: String
    let shortName: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortName = "short_name"
    }
}
