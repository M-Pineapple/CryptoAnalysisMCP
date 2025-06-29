import Foundation
import Logging

// MARK: - v1.1 DexPaprika Tool Registration

extension CryptoAnalysisMCP {
    func registerDexPaprikaTools(server: MCPServer, handler: CryptoAnalysisHandler) async {
        
        // MARK: - Token Liquidity Tool
        server.addTool(MCPTool(
            name: "get_token_liquidity",
            description: "Get liquidity information for a token across all DEXes",
            inputSchema: createToolSchema(
                properties: [
                    "symbol": createProperty(
                        type: "string",
                        description: "Token symbol (e.g., PEPE, BOBO)"
                    ),
                    "network": createProperty(
                        type: "string",
                        description: "Network name (e.g., ethereum, solana, bsc) - optional"
                    )
                ],
                required: ["symbol"]
            )
        ) { arguments in
            await handler.getTokenLiquidity(arguments: arguments)
        })
        
        // MARK: - Search Tokens by Network
        server.addTool(MCPTool(
            name: "search_tokens_by_network",
            description: "Search for tokens on a specific blockchain network",
            inputSchema: createToolSchema(
                properties: [
                    "network": createProperty(
                        type: "string",
                        description: "Network name (e.g., ethereum, solana, bsc, polygon)"
                    ),
                    "query": createProperty(
                        type: "string",
                        description: "Search query for token name or symbol (optional)"
                    ),
                    "limit": createProperty(
                        type: "integer",
                        description: "Number of results (default: 20, max: 100)"
                    )
                ],
                required: ["network"]
            )
        ) { arguments in
            await handler.searchTokensByNetwork(arguments: arguments)
        })
        
        // MARK: - Compare DEX Prices
        server.addTool(MCPTool(
            name: "compare_dex_prices",
            description: "Compare token prices across different DEXes on the same network",
            inputSchema: createToolSchema(
                properties: [
                    "symbol": createProperty(
                        type: "string",
                        description: "Token symbol"
                    ),
                    "network": createProperty(
                        type: "string",
                        description: "Network name (e.g., ethereum, solana)"
                    )
                ],
                required: ["symbol", "network"]
            )
        ) { arguments in
            await handler.compareDexPrices(arguments: arguments)
        })
        
        // MARK: - Get Network Pools
        server.addTool(MCPTool(
            name: "get_network_pools",
            description: "Get top liquidity pools on a specific network",
            inputSchema: createToolSchema(
                properties: [
                    "network": createProperty(
                        type: "string",
                        description: "Network name (e.g., ethereum, solana, bsc)"
                    ),
                    "sort_by": createProperty(
                        type: "string",
                        description: "Sort by: volume_usd, liquidity_usd, price_change (default: volume_usd)"
                    ),
                    "limit": createProperty(
                        type: "integer",
                        description: "Number of pools (default: 20)"
                    )
                ],
                required: ["network"]
            )
        ) { arguments in
            await handler.getNetworkPools(arguments: arguments)
        })
        
        // MARK: - Get DEX Info
        server.addTool(MCPTool(
            name: "get_dex_info",
            description: "Get information about DEXes available on a network",
            inputSchema: createToolSchema(
                properties: [
                    "network": createProperty(
                        type: "string",
                        description: "Network name (e.g., ethereum, solana)"
                    )
                ],
                required: ["network"]
            )
        ) { arguments in
            await handler.getDexInfo(arguments: arguments)
        })
        
        // MARK: - Get Pool Analytics
        server.addTool(MCPTool(
            name: "get_pool_analytics",
            description: "Get detailed analytics for a specific liquidity pool",
            inputSchema: createToolSchema(
                properties: [
                    "network": createProperty(
                        type: "string",
                        description: "Network name"
                    ),
                    "pool_address": createProperty(
                        type: "string",
                        description: "Pool contract address"
                    )
                ],
                required: ["network", "pool_address"]
            )
        ) { arguments in
            await handler.getPoolAnalytics(arguments: arguments)
        })
        
        // MARK: - Get Pool OHLCV
        server.addTool(MCPTool(
            name: "get_pool_ohlcv",
            description: "Get historical OHLCV (candlestick) data for a liquidity pool",
            inputSchema: createToolSchema(
                properties: [
                    "network": createProperty(
                        type: "string",
                        description: "Network name"
                    ),
                    "pool_address": createProperty(
                        type: "string",
                        description: "Pool contract address"
                    ),
                    "start_date": createProperty(
                        type: "string",
                        description: "Start date (YYYY-MM-DD)"
                    ),
                    "end_date": createProperty(
                        type: "string",
                        description: "End date (YYYY-MM-DD) - optional"
                    ),
                    "interval": createProperty(
                        type: "string",
                        description: "Time interval: 5m, 15m, 30m, 1h, 4h, 1d, 1w (default: 1d)"
                    )
                ],
                required: ["network", "pool_address", "start_date"]
            )
        ) { arguments in
            await handler.getPoolOHLCV(arguments: arguments)
        })
        
        // MARK: - Get Available Networks
        server.addTool(MCPTool(
            name: "get_available_networks",
            description: "Get list of all supported blockchain networks",
            inputSchema: createToolSchema(
                properties: [:],
                required: []
            )
        ) { arguments in
            await handler.getAvailableNetworks(arguments: arguments)
        })
        
        // MARK: - Advanced Token Search
        server.addTool(MCPTool(
            name: "search_tokens_advanced",
            description: "Advanced token search across all networks with filters",
            inputSchema: createToolSchema(
                properties: [
                    "query": createProperty(
                        type: "string",
                        description: "Search query for token name or symbol"
                    ),
                    "min_liquidity": createProperty(
                        type: "number",
                        description: "Minimum liquidity in USD (optional)"
                    ),
                    "min_volume": createProperty(
                        type: "number",
                        description: "Minimum 24h volume in USD (optional)"
                    ),
                    "limit": createProperty(
                        type: "integer",
                        description: "Number of results (default: 20)"
                    )
                ],
                required: ["query"]
            )
        ) { arguments in
            await handler.searchTokensAdvanced(arguments: arguments)
        })
    }
}

// MARK: - v1.1 DexPaprika Handler Methods

extension CryptoAnalysisHandler {
    
    func getTokenLiquidity(arguments: [String: Any]) async -> [String: Any] {
        guard let symbol = arguments["symbol"] as? String else {
            return ["error": "Symbol is required"]
        }
        
        let network = arguments["network"] as? String
        
        do {
            // Try to get token data with liquidity info
            let dexProvider = await dexPaprikaProvider
            
            if let network = network {
                // Search on specific network
                let searchResults = try await dexProvider.searchToken(query: symbol, limit: 10)
                
                // Filter by network if specified
                let filtered = searchResults.filter { 
                    $0.networkId == network.lowercased() && 
                    $0.symbol.uppercased() == symbol.uppercased() 
                }
                
                if let result = filtered.first {
                    let token = try await dexProvider.getToken(network: result.networkId, address: result.address)
                    let pools = try await dexProvider.getTokenPools(network: result.networkId, tokenAddress: result.address, limit: 10)
                    
                    let totalLiquidity = pools.reduce(0.0) { $0 + $1.liquidityUsd }
                    
                    return [
                        "symbol": symbol.uppercased(),
                        "network": result.networkId,
                        "total_liquidity_usd": totalLiquidity,
                        "liquidity_from_token_data": token.summary.liquidityUsd,
                        "pool_count": pools.count,
                        "top_pools": pools.prefix(5).map { pool in
                            [
                                "name": pool.name,
                                "address": pool.address,
                                "liquidity_usd": pool.liquidityUsd,
                                "volume_24h": pool.volumeUsd24h,
                                "dex": pool.dexId
                            ]
                        },
                        "timestamp": ISO8601DateFormatter().string(from: Date())
                    ]
                }
            }
            
            // Search across all networks
            let token = try await dexProvider.getTokenBySymbol(symbol)
            let totalLiquidity = token.summary.liquidityUsd
            
            return [
                "symbol": symbol.uppercased(),
                "network": token.network.id,
                "total_liquidity_usd": totalLiquidity,
                "price_usd": token.summary.priceUsd,
                "volume_24h": token.summary.volumeUsd24h,
                "holders": token.summary.holders ?? 0,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
        } catch {
            logger.error("Failed to get liquidity for \(symbol): \(error)")
            return ["error": error.localizedDescription]
        }
    }
    
    func searchTokensByNetwork(arguments: [String: Any]) async -> [String: Any] {
        guard let network = arguments["network"] as? String else {
            return ["error": "Network is required"]
        }
        
        let query = arguments["query"] as? String
        let limit = arguments["limit"] as? Int ?? 20
        
        do {
            let dexProvider = await dexPaprikaProvider
            
            // Get pools on the network - try to get more pools to find tokens
            let pools = try await dexProvider.getNetworkPools(network: network, limit: 100, orderBy: "volume_usd")
            
            // Extract unique tokens
            var uniqueTokens: [String: [String: Any]] = [:]
            
            for pool in pools {
                // Add token0
                let token0Key = "\(pool.token0.address)"
                if uniqueTokens[token0Key] == nil {
                    uniqueTokens[token0Key] = [
                        "address": pool.token0.address,
                        "symbol": pool.token0.symbol,
                        "name": pool.token0.name,
                        "network": network,
                        "pools_count": 1,
                        "total_liquidity": pool.liquidityUsd
                    ]
                } else {
                    if var existing = uniqueTokens[token0Key] {
                        existing["pools_count"] = (existing["pools_count"] as? Int ?? 0) + 1
                        existing["total_liquidity"] = (existing["total_liquidity"] as? Double ?? 0) + pool.liquidityUsd
                        uniqueTokens[token0Key] = existing
                    }
                }
                
                // Add token1
                let token1Key = "\(pool.token1.address)"
                if uniqueTokens[token1Key] == nil {
                    uniqueTokens[token1Key] = [
                        "address": pool.token1.address,
                        "symbol": pool.token1.symbol,
                        "name": pool.token1.name,
                        "network": network,
                        "pools_count": 1,
                        "total_liquidity": pool.liquidityUsd
                    ]
                } else {
                    if var existing = uniqueTokens[token1Key] {
                        existing["pools_count"] = (existing["pools_count"] as? Int ?? 0) + 1
                        existing["total_liquidity"] = (existing["total_liquidity"] as? Double ?? 0) + pool.liquidityUsd
                        uniqueTokens[token1Key] = existing
                    }
                }
            }
            
            var tokenList = Array(uniqueTokens.values)
            
            // Filter by query if provided
            if let query = query, !query.isEmpty {
                tokenList = tokenList.filter { token in
                    let symbol = (token["symbol"] as? String ?? "").lowercased()
                    let name = (token["name"] as? String ?? "").lowercased()
                    let queryLower = query.lowercased()
                    return symbol.contains(queryLower) || name.contains(queryLower)
                }
            }
            
            // Sort by liquidity
            tokenList.sort { 
                ($0["total_liquidity"] as? Double ?? 0) > ($1["total_liquidity"] as? Double ?? 0)
            }
            
            return [
                "network": network,
                "token_count": tokenList.count,
                "tokens": Array(tokenList.prefix(limit)),
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
        } catch {
            logger.error("Failed to search tokens on \(network): \(error)")
            return ["error": error.localizedDescription]
        }
    }
    
    func compareDexPrices(arguments: [String: Any]) async -> [String: Any] {
        guard let symbol = arguments["symbol"] as? String,
              let network = arguments["network"] as? String else {
            return ["error": "Both symbol and network are required"]
        }
        
        do {
            let dexProvider = await dexPaprikaProvider
            
            // Search for the token
            let searchResults = try await dexProvider.searchToken(query: symbol, limit: 20)
            let filtered = searchResults.filter { 
                $0.networkId == network.lowercased() && 
                $0.symbol.uppercased() == symbol.uppercased() 
            }
            
            guard let tokenResult = filtered.first else {
                return ["error": "Token \(symbol) not found on \(network)"]
            }
            
            // Get comparison data
            let comparison = try await dexProvider.compareTokenAcrossDexes(
                network: network,
                tokenAddress: tokenResult.address
            )
            
            // Format results
            var dexPricesFormatted: [String: Any] = [:]
            for (dexId, prices) in comparison.dexPrices {
                dexPricesFormatted[dexId] = prices.map { price in
                    [
                        "pool_name": price.poolName,
                        "price_usd": price.priceUsd,
                        "liquidity_usd": price.liquidityUsd,
                        "volume_24h": price.volume24h,
                        "fee_rate": price.feeRate ?? 0
                    ]
                }
            }
            
            return [
                "symbol": symbol.uppercased(),
                "network": network,
                "token_address": tokenResult.address,
                "dex_prices": dexPricesFormatted,
                "best_price": comparison.bestPrice != nil ? [
                    "dex": comparison.bestPrice!.poolName.components(separatedBy: " on ").last ?? "unknown",
                    "price": comparison.bestPrice!.priceUsd,
                    "pool": comparison.bestPrice!.poolName,
                    "liquidity": comparison.bestPrice!.liquidityUsd
                ] : nil,
                "worst_price": comparison.worstPrice != nil ? [
                    "dex": comparison.worstPrice!.poolName.components(separatedBy: " on ").last ?? "unknown",
                    "price": comparison.worstPrice!.priceUsd,
                    "pool": comparison.worstPrice!.poolName,
                    "liquidity": comparison.worstPrice!.liquidityUsd
                ] : nil,
                "average_price": comparison.averagePrice,
                "price_spread": comparison.priceSpread,
                "price_spread_percent": comparison.priceSpread / comparison.averagePrice * 100,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
        } catch {
            logger.error("Failed to compare DEX prices: \(error)")
            return ["error": error.localizedDescription]
        }
    }
    
    func getNetworkPools(arguments: [String: Any]) async -> [String: Any] {
        guard let network = arguments["network"] as? String else {
            return ["error": "Network is required"]
        }
        
        let sortBy = arguments["sort_by"] as? String ?? "volume_usd"
        let limit = arguments["limit"] as? Int ?? 20
        
        do {
            let dexProvider = await dexPaprikaProvider
            let pools = try await dexProvider.getNetworkPools(network: network, limit: limit, orderBy: sortBy)
            
            return [
                "network": network,
                "pool_count": pools.count,
                "sort_by": sortBy,
                "pools": pools.map { pool in
                    [
                        "name": pool.name,
                        "address": pool.address,
                        "dex": pool.dexId,
                        "price_usd": pool.priceUsd,
                        "liquidity_usd": pool.liquidityUsd,
                        "volume_24h": pool.volumeUsd24h,
                        "fee_rate": pool.feeRate ?? 0,
                        "token0": [
                            "symbol": pool.token0.symbol,
                            "name": pool.token0.name,
                            "address": pool.token0.address
                        ],
                        "token1": [
                            "symbol": pool.token1.symbol,
                            "name": pool.token1.name,
                            "address": pool.token1.address
                        ]
                    ]
                },
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
        } catch {
            logger.error("Failed to get network pools: \(error)")
            return ["error": error.localizedDescription]
        }
    }
    
    func getDexInfo(arguments: [String: Any]) async -> [String: Any] {
        guard let network = arguments["network"] as? String else {
            return ["error": "Network is required"]
        }
        
        do {
            let dexProvider = await dexPaprikaProvider
            let dexes = try await dexProvider.getNetworkDexes(network: network)
            
            // Since the DEX endpoint doesn't provide volume/liquidity data,
            // we'll just return the basic info
            
            return [
                "network": network,
                "dex_count": dexes.count,
                "dexes": dexes.map { dex in
                    [
                        "id": dex.id,
                        "name": dex.name,
                        "protocol": dex.`protocol`
                    ]
                },
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
        } catch {
            logger.error("Failed to get DEX info: \(error)")
            return ["error": error.localizedDescription]
        }
    }
    
    func getPoolAnalytics(arguments: [String: Any]) async -> [String: Any] {
        guard let network = arguments["network"] as? String,
              let poolAddress = arguments["pool_address"] as? String else {
            return ["error": "Both network and pool_address are required"]
        }
        
        do {
            let dexProvider = await dexPaprikaProvider
            let poolDetail = try await dexProvider.getPoolDetails(network: network, poolAddress: poolAddress)
            
            return [
                "pool": [
                    "address": poolDetail.address,
                    "name": poolDetail.name,
                    "dex": poolDetail.dexName,
                    "network": poolDetail.networkName,
                    "created_at": poolDetail.createdAt
                ],
                "pricing": [
                    "price_usd": poolDetail.priceUsd,
                    "price_token0": poolDetail.priceToken0,
                    "price_token1": poolDetail.priceToken1,
                    "price_change_24h": poolDetail.priceChange24h
                ],
                "liquidity": [
                    "total_usd": poolDetail.liquidityUsd,
                    "token0_amount": poolDetail.liquidityToken0,
                    "token1_amount": poolDetail.liquidityToken1,
                    "change_24h": poolDetail.liquidityChange24h
                ],
                "volume": [
                    "volume_usd_24h": poolDetail.volumeUsd24h,
                    "volume_token0_24h": poolDetail.volumeToken0_24h,
                    "volume_token1_24h": poolDetail.volumeToken1_24h,
                    "volume_change_24h": poolDetail.volumeChange24h
                ],
                "fee_rate": poolDetail.feeRate ?? 0,
                "tokens": [
                    [
                        "position": "token0",
                        "symbol": poolDetail.token0.symbol,
                        "name": poolDetail.token0.name,
                        "address": poolDetail.token0.address
                    ],
                    [
                        "position": "token1",
                        "symbol": poolDetail.token1.symbol,
                        "name": poolDetail.token1.name,
                        "address": poolDetail.token1.address
                    ]
                ],
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
        } catch {
            logger.error("Failed to get pool analytics: \(error)")
            return ["error": error.localizedDescription]
        }
    }
    
    func getPoolOHLCV(arguments: [String: Any]) async -> [String: Any] {
        guard let network = arguments["network"] as? String,
              let poolAddress = arguments["pool_address"] as? String,
              let startDate = arguments["start_date"] as? String else {
            return ["error": "Network, pool_address, and start_date are required"]
        }
        
        let endDate = arguments["end_date"] as? String
        let interval = arguments["interval"] as? String ?? "1d"
        
        do {
            let dexProvider = await dexPaprikaProvider
            let ohlcvData = try await dexProvider.getPoolOHLCV(
                network: network,
                poolAddress: poolAddress,
                start: startDate,
                end: endDate,
                interval: interval,
                limit: 1000
            )
            
            // Calculate some basic statistics
            let prices = ohlcvData.map { $0.close }
            let highestPrice = prices.max() ?? 0
            let lowestPrice = prices.min() ?? 0
            let avgPrice = prices.reduce(0, +) / Double(prices.count)
            let totalVolume = ohlcvData.reduce(0) { $0 + $1.volume }
            
            return [
                "pool_address": poolAddress,
                "network": network,
                "interval": interval,
                "start_date": startDate,
                "end_date": endDate ?? "current",
                "data_points": ohlcvData.count,
                "statistics": [
                    "highest_price": highestPrice,
                    "lowest_price": lowestPrice,
                    "average_price": avgPrice,
                    "total_volume": totalVolume,
                    "price_range": highestPrice - lowestPrice,
                    "volatility": (highestPrice - lowestPrice) / avgPrice * 100
                ],
                "ohlcv": ohlcvData.map { candle in
                    [
                        "timestamp": candle.timestamp,
                        "open": candle.open,
                        "high": candle.high,
                        "low": candle.low,
                        "close": candle.close,
                        "volume": candle.volume
                    ]
                },
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
        } catch {
            logger.error("Failed to get pool OHLCV: \(error)")
            return ["error": error.localizedDescription]
        }
    }
    
    func getAvailableNetworks(arguments: [String: Any]) async -> [String: Any] {
        do {
            let dexProvider = await dexPaprikaProvider
            let networks = try await dexProvider.getNetworks()
            
            return [
                "network_count": networks.count,
                "networks": networks.map { network in
                    [
                        "id": network.id,
                        "name": network.name,
                        "short_name": network.shortName
                    ]
                },
                "popular_networks": [
                    "ethereum", "solana", "binance-smart-chain", "polygon", 
                    "arbitrum", "optimism", "avalanche-c-chain", "base"
                ],
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
        } catch {
            logger.error("Failed to get available networks: \(error)")
            return ["error": error.localizedDescription]
        }
    }
    
    func searchTokensAdvanced(arguments: [String: Any]) async -> [String: Any] {
        guard let query = arguments["query"] as? String else {
            return ["error": "Query is required"]
        }
        
        let minLiquidity = arguments["min_liquidity"] as? Double
        let minVolume = arguments["min_volume"] as? Double
        let limit = arguments["limit"] as? Int ?? 20
        
        do {
            let dexProvider = await dexPaprikaProvider
            let searchResults = try await dexProvider.searchToken(query: query, limit: 100)
            
            // Get detailed token data for filtering
            var detailedTokens: [[String: Any]] = []
            
            for result in searchResults.prefix(50) { // Limit to prevent rate limiting
                do {
                    let token = try await dexProvider.getToken(
                        network: result.networkId,
                        address: result.address
                    )
                    
                    // Apply filters
                    var passesFilter = true
                    
                    if let minLiq = minLiquidity {
                        passesFilter = passesFilter && token.summary.liquidityUsd >= minLiq
                    }
                    
                    if let minVol = minVolume {
                        passesFilter = passesFilter && token.summary.volumeUsd24h >= minVol
                    }
                    
                    if passesFilter {
                        detailedTokens.append([
                            "symbol": token.symbol,
                            "name": token.name,
                            "address": token.address,
                            "network": token.network.name,
                            "network_id": token.network.id,
                            "price_usd": token.summary.priceUsd,
                            "liquidity_usd": token.summary.liquidityUsd,
                            "volume_24h": token.summary.volumeUsd24h,
                            "price_change_24h": token.summary.priceChange24h,
                            "holders": token.summary.holders ?? 0,
                            "logo_url": token.logoUrl ?? ""
                        ])
                    }
                    
                    if detailedTokens.count >= limit {
                        break
                    }
                    
                } catch {
                    // Skip tokens that fail to load
                    continue
                }
            }
            
            // Sort by liquidity
            detailedTokens.sort { 
                ($0["liquidity_usd"] as? Double ?? 0) > ($1["liquidity_usd"] as? Double ?? 0)
            }
            
            return [
                "query": query,
                "filters": [
                    "min_liquidity": minLiquidity ?? 0,
                    "min_volume": minVolume ?? 0
                ],
                "result_count": detailedTokens.count,
                "tokens": Array(detailedTokens.prefix(limit)),
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
        } catch {
            logger.error("Failed to perform advanced token search: \(error)")
            return ["error": error.localizedDescription]
        }
    }
}
