import Foundation
import Logging
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Advanced DexPaprika features for v1.2
extension DexPaprikaDataProvider {
    
    // MARK: - Pool Operations
    
    /// Get top pools across all networks
    /// NOTE: This endpoint has been deprecated by DexPaprika. Use getNetworkPools instead.
    func getTopPools(limit: Int = 20, orderBy: String = "volume_usd", sort: String = "desc") async throws -> [DexPaprikaPool] {
        // This endpoint is deprecated
        throw CryptoAnalysisError.networkError("The global /pools endpoint has been deprecated. Please use getNetworkPools with a specific network instead.")
    }
    
    /// Get pools on a specific network
    func getNetworkPools(network: String, limit: Int = 20, orderBy: String = "volume_usd") async throws -> [DexPaprikaPool] {
        let networkId = networkMapping[network.lowercased()] ?? network.lowercased()
        let urlString = "\(dexPaprikaBaseURL)/networks/\(networkId)/pools?limit=\(limit)&orderBy=\(orderBy)&sort=desc"
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "") else {
            throw CryptoAnalysisError.networkError("Invalid URL")
        }
        
        logger.info("Fetching pools on \(networkId)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CryptoAnalysisError.networkError("Invalid response")
            }
            
            // Parse the wrapped response
            let poolsResponse = try JSONDecoder().decode(DexPaprikaPoolsResponse.self, from: data)
            logger.info("Found \(poolsResponse.pools.count) pools on \(networkId)")
            return poolsResponse.pools
            
        } catch {
            logger.error("Failed to fetch network pools: \(error)")
            throw error
        }
    }
    
    /// Get pools for a specific DEX
    func getDexPools(network: String, dex: String, limit: Int = 20) async throws -> [DexPaprikaPool] {
        let networkId = networkMapping[network.lowercased()] ?? network.lowercased()
        let urlString = "\(dexPaprikaBaseURL)/networks/\(networkId)/dexes/\(dex)/pools?limit=\(limit)&orderBy=volume_usd&sort=desc"
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "") else {
            throw CryptoAnalysisError.networkError("Invalid URL")
        }
        
        logger.info("Fetching pools for \(dex) on \(networkId)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CryptoAnalysisError.networkError("Invalid response")
            }
            
            // Try parsing as wrapped response first
            if let poolsResponse = try? JSONDecoder().decode(DexPaprikaPoolsResponse.self, from: data) {
                logger.info("Found \(poolsResponse.pools.count) pools for \(dex)")
                return poolsResponse.pools
            }
            
            // Fallback to array response
            let pools = try JSONDecoder().decode([DexPaprikaPool].self, from: data)
            logger.info("Found \(pools.count) pools for \(dex)")
            return pools
            
        } catch {
            logger.error("Failed to fetch DEX pools: \(error)")
            throw error
        }
    }
    
    /// Get detailed pool information
    func getPoolDetails(network: String, poolAddress: String) async throws -> DexPaprikaPoolDetail {
        let networkId = networkMapping[network.lowercased()] ?? network.lowercased()
        let urlString = "\(dexPaprikaBaseURL)/networks/\(networkId)/pools/\(poolAddress)"
        
        guard let url = URL(string: urlString) else {
            throw CryptoAnalysisError.networkError("Invalid URL")
        }
        
        logger.info("Fetching pool details for \(poolAddress) on \(networkId)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CryptoAnalysisError.networkError("Invalid response")
            }
            
            let poolDetail = try JSONDecoder().decode(DexPaprikaPoolDetail.self, from: data)
            logger.info("Retrieved pool details: \(poolDetail.name)")
            return poolDetail
            
        } catch {
            logger.error("Failed to fetch pool details: \(error)")
            throw error
        }
    }
    
    /// Get pools containing a specific token
    func getTokenPools(network: String, tokenAddress: String, limit: Int = 20) async throws -> [DexPaprikaPool] {
        let networkId = networkMapping[network.lowercased()] ?? network.lowercased()
        let urlString = "\(dexPaprikaBaseURL)/networks/\(networkId)/tokens/\(tokenAddress)/pools?limit=\(limit)&orderBy=volume_usd&sort=desc"
        
        guard let url = URL(string: urlString) else {
            throw CryptoAnalysisError.networkError("Invalid URL")
        }
        
        logger.info("Fetching pools for token \(tokenAddress)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CryptoAnalysisError.networkError("Invalid response")
            }
            
            // Try parsing as wrapped response first
            if let poolsResponse = try? JSONDecoder().decode(DexPaprikaPoolsResponse.self, from: data) {
                logger.info("Found \(poolsResponse.pools.count) pools containing token")
                return poolsResponse.pools
            }
            
            // Fallback to array response
            let pools = try JSONDecoder().decode([DexPaprikaPool].self, from: data)
            logger.info("Found \(pools.count) pools containing token")
            return pools
            
        } catch {
            logger.error("Failed to fetch token pools: \(error)")
            throw error
        }
    }
    
    // MARK: - DEX Operations
    
    /// Get list of DEXes on a network
    func getNetworkDexes(network: String) async throws -> [DexPaprikaDex] {
        let networkId = networkMapping[network.lowercased()] ?? network.lowercased()
        let urlString = "\(dexPaprikaBaseURL)/networks/\(networkId)/dexes"
        
        guard let url = URL(string: urlString) else {
            throw CryptoAnalysisError.networkError("Invalid URL")
        }
        
        logger.info("Fetching DEXes on \(networkId)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CryptoAnalysisError.networkError("Invalid response")
            }
            
            let dexResponse = try JSONDecoder().decode(DexPaprikaDexResponse.self, from: data)
            logger.info("Found \(dexResponse.dexes.count) DEXes on \(networkId)")
            return dexResponse.dexes
            
        } catch {
            logger.error("Failed to fetch DEXes: \(error)")
            throw error
        }
    }
    
    // MARK: - Historical Data
    
    /// Get OHLCV data for a pool
    func getPoolOHLCV(network: String, poolAddress: String, start: String, end: String? = nil, interval: String = "1d", limit: Int = 100) async throws -> [DexPaprikaOHLCV] {
        let networkId = networkMapping[network.lowercased()] ?? network.lowercased()
        var urlString = "\(dexPaprikaBaseURL)/networks/\(networkId)/pools/\(poolAddress)/ohlcv?start=\(start)&interval=\(interval)&limit=\(limit)"
        
        if let end = end {
            urlString += "&end=\(end)"
        }
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "") else {
            throw CryptoAnalysisError.networkError("Invalid URL")
        }
        
        logger.info("Fetching OHLCV data for pool \(poolAddress)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CryptoAnalysisError.networkError("Invalid response")
            }
            
            let ohlcvData = try JSONDecoder().decode([DexPaprikaOHLCV].self, from: data)
            logger.info("Retrieved \(ohlcvData.count) OHLCV data points")
            return ohlcvData
            
        } catch {
            logger.error("Failed to fetch OHLCV data: \(error)")
            throw error
        }
    }
    
    // MARK: - Comparison Functions
    
    /// Compare token prices across different DEXes
    func compareTokenAcrossDexes(network: String, tokenAddress: String) async throws -> TokenDexComparison {
        // First get all pools for the token
        let pools = try await getTokenPools(network: network, tokenAddress: tokenAddress, limit: 50)
        
        // Group by DEX
        var dexPrices: [String: [DexPrice]] = [:]
        
        for pool in pools {
            let dexId = pool.dexId
            if dexPrices[dexId] == nil {
                dexPrices[dexId] = []
            }
            
            let price = DexPrice(
                poolAddress: pool.address,
                poolName: pool.name,
                priceUsd: pool.priceUsd,
                liquidityUsd: pool.liquidityUsd,
                volume24h: pool.volumeUsd24h,
                feeRate: pool.feeRate
            )
            
            dexPrices[dexId]?.append(price)
        }
        
        // Find best prices
        var allPrices = dexPrices.values.flatMap { $0 }
        allPrices.sort { $0.priceUsd < $1.priceUsd }
        
        let bestPrice = allPrices.first
        let worstPrice = allPrices.last
        
        // Calculate average
        let avgPrice = allPrices.reduce(0.0) { $0 + $1.priceUsd } / Double(allPrices.count)
        
        return TokenDexComparison(
            tokenAddress: tokenAddress,
            network: network,
            dexPrices: dexPrices,
            bestPrice: bestPrice,
            worstPrice: worstPrice,
            averagePrice: avgPrice,
            priceSpread: (worstPrice?.priceUsd ?? 0) - (bestPrice?.priceUsd ?? 0),
            timestamp: Date()
        )
    }
}

// MARK: - Advanced DexPaprika Models

// Wrapper for pools response
struct DexPaprikaPoolsResponse: Codable {
    let pools: [DexPaprikaPool]
    let pageInfo: DexPaprikaPageInfo?
    
    private enum CodingKeys: String, CodingKey {
        case pools
        case pageInfo = "page_info"
    }
}

struct DexPaprikaPageInfo: Codable {
    let limit: Int
    let page: Int
    let totalItems: Int
    let totalPages: Int
    
    private enum CodingKeys: String, CodingKey {
        case limit, page
        case totalItems = "total_items"
        case totalPages = "total_pages"
    }
}

struct DexPaprikaPool: Codable {
    let id: String
    let dexId: String
    let dexName: String
    let chain: String
    let volumeUsd: Double
    let createdAt: String
    let createdAtBlockNumber: Int?
    let transactions: Int
    let priceUsd: Double
    let lastPriceChangeUsd5m: Double?
    let lastPriceChangeUsd1h: Double?
    let lastPriceChangeUsd24h: Double?
    let fee: Double?
    let tokens: [PoolToken]
    
    private enum CodingKeys: String, CodingKey {
        case id, chain, transactions, fee, tokens
        case dexId = "dex_id"
        case dexName = "dex_name"
        case volumeUsd = "volume_usd"
        case createdAt = "created_at"
        case createdAtBlockNumber = "created_at_block_number"
        case priceUsd = "price_usd"
        case lastPriceChangeUsd5m = "last_price_change_usd_5m"
        case lastPriceChangeUsd1h = "last_price_change_usd_1h"
        case lastPriceChangeUsd24h = "last_price_change_usd_24h"
    }
    
    // Computed properties for compatibility
    var address: String { id }
    var name: String { "\(tokens.first?.symbol ?? "?") / \(tokens.last?.symbol ?? "?")" }
    var networkId: String { chain }
    var volumeUsd24h: Double { volumeUsd }
    var liquidityUsd: Double { 0 }  // Not provided in this endpoint
    var feeRate: Double? { fee }
    var token0: PoolToken { tokens.first ?? PoolToken(id: "", name: "", symbol: "", chain: "") }
    var token1: PoolToken { tokens.last ?? PoolToken(id: "", name: "", symbol: "", chain: "") }
}

struct PoolToken: Codable {
    let id: String
    let name: String
    let symbol: String
    let chain: String
    let type: String?
    let status: String?
    let decimals: Int?
    let totalSupply: Double?
    let description: String?
    let website: String?
    let addedAt: String?
    let fdv: Double?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, symbol, chain, type, status, decimals, description, website, fdv
        case totalSupply = "total_supply"
        case addedAt = "added_at"
    }
    
    // Computed properties for compatibility
    var address: String { id }
    var logoUrl: String? { nil }
    
    // Initializer for empty token
    init(id: String, name: String, symbol: String, chain: String) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.chain = chain
        self.type = nil
        self.status = nil
        self.decimals = nil
        self.totalSupply = nil
        self.description = nil
        self.website = nil
        self.addedAt = nil
        self.fdv = nil
    }
}

struct DexPaprikaPoolDetail: Codable {
    let address: String
    let name: String
    let dexId: String
    let dexName: String
    let networkId: String
    let networkName: String
    let priceUsd: Double
    let priceToken0: Double
    let priceToken1: Double
    let volumeUsd24h: Double
    let volumeToken0_24h: Double
    let volumeToken1_24h: Double
    let liquidityUsd: Double
    let liquidityToken0: Double
    let liquidityToken1: Double
    let feeRate: Double?
    let priceChange24h: Double
    let volumeChange24h: Double
    let liquidityChange24h: Double
    let token0: PoolToken
    let token1: PoolToken
    let createdAt: String
    
    private enum CodingKeys: String, CodingKey {
        case address
        case name
        case dexId = "dex_id"
        case dexName = "dex_name"
        case networkId = "network_id"
        case networkName = "network_name"
        case priceUsd = "price_usd"
        case priceToken0 = "price_token_0"
        case priceToken1 = "price_token_1"
        case volumeUsd24h = "volume_usd_24h"
        case volumeToken0_24h = "volume_token_0_24h"
        case volumeToken1_24h = "volume_token_1_24h"
        case liquidityUsd = "liquidity_usd"
        case liquidityToken0 = "liquidity_token_0"
        case liquidityToken1 = "liquidity_token_1"
        case feeRate = "fee_rate"
        case priceChange24h = "price_change_24h"
        case volumeChange24h = "volume_change_24h"
        case liquidityChange24h = "liquidity_change_24h"
        case token0 = "token_0"
        case token1 = "token_1"
        case createdAt = "created_at"
    }
}

// Wrapper for DEX response
struct DexPaprikaDexResponse: Codable {
    let dexes: [DexPaprikaDex]
}

struct DexPaprikaDex: Codable {
    let dexId: String
    let dexName: String
    let chain: String
    let `protocol`: String
    
    private enum CodingKeys: String, CodingKey {
        case dexId = "dex_id"
        case dexName = "dex_name"
        case chain
        case `protocol` = "protocol"
    }
    
    // Computed properties for compatibility
    var id: String { dexId }
    var name: String { dexName }
    var volumeUsd24h: Double { 0 }  // Not provided in this endpoint
    var liquidityUsd: Double { 0 }  // Not provided in this endpoint
    var poolCount: Int { 0 }  // Not provided in this endpoint
    var logoUrl: String? { nil }  // Not provided in this endpoint
}

struct DexPaprikaOHLCV: Codable {
    let timestamp: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

// MARK: - Comparison Models

struct TokenDexComparison {
    let tokenAddress: String
    let network: String
    let dexPrices: [String: [DexPrice]]
    let bestPrice: DexPrice?
    let worstPrice: DexPrice?
    let averagePrice: Double
    let priceSpread: Double
    let timestamp: Date
}

struct DexPrice {
    let poolAddress: String
    let poolName: String
    let priceUsd: Double
    let liquidityUsd: Double
    let volume24h: Double
    let feeRate: Double?
}
