import ArgumentParser
import Foundation
import Logging

@main
struct CryptoAnalysisMCP: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "crypto-analysis-mcp",
        abstract: "A Model Context Protocol server for cryptocurrency technical analysis",
        version: "1.1.0"
    )
    
    @Option(help: "Transport method")
    var transport: String = "stdio"
    
    @Flag(help: "Enable debug logging to stderr")
    var debug = false
    
    func run() async throws {
        // Set up logging - only if debug flag is set
        if debug {
            LoggingSystem.bootstrap { label in
                var handler = StreamLogHandler.standardError(label: label)
                handler.logLevel = .info
                return handler
            }
        } else {
            // Silent logger for production
            LoggingSystem.bootstrap { label in
                return SwiftLogNoOpLogHandler()
            }
        }
        
        let logger = Logger(label: "CryptoAnalysisMCP")
        logger.info("🚀 Starting Crypto Analysis MCP Server v1.1.0")
        
        // Create the analysis handler
        let analysisHandler = CryptoAnalysisHandler()
        
        // Create the MCP server
        let server = MCPServer(
            name: "crypto-analysis",
            version: "1.1.0",
            debugMode: debug
        )
        
        // Register all analysis tools
        await registerTools(server: server, handler: analysisHandler)
        
        // Register v1.1 DexPaprika tools
        await registerDexPaprikaTools(server: server, handler: analysisHandler)
        
        logger.info("✅ Registered crypto analysis tools (v1.1 with full DexPaprika integration)")
        
        // Start the server based on transport
        switch transport {
        case "stdio":
            await server.runStdio()
        default:
            throw ValidationError("Unsupported transport: \(transport)")
        }
    }
    
    private func registerTools(server: MCPServer, handler: CryptoAnalysisHandler) async {
        // Price tool
        server.addTool(MCPTool(
            name: "get_crypto_price",
            description: "Get current price and market data for a cryptocurrency",
            inputSchema: createToolSchema(
                properties: [
                    "symbol": createProperty(
                        type: "string",
                        description: "Cryptocurrency symbol (e.g., BTC, ETH, ADA)"
                    )
                ],
                required: ["symbol"]
            )
        ) { arguments in
            await handler.getCurrentPrice(arguments: arguments)
        })
        
        // Technical indicators tool
        server.addTool(MCPTool(
            name: "get_technical_indicators",
            description: "Calculate technical indicators (RSI, MACD, SMA, EMA, Bollinger Bands)",
            inputSchema: createToolSchema(
                properties: [
                    "symbol": createProperty(
                        type: "string",
                        description: "Cryptocurrency symbol"
                    ),
                    "timeframe": createProperty(
                        type: "string",
                        description: "Timeframe: 4h, daily, weekly (default: daily)"
                    ),
                    "indicators": createProperty(
                        type: "array",
                        description: "Specific indicators to calculate (optional)",
                        items: ["type": "string"]
                    )
                ],
                required: ["symbol"]
            )
        ) { arguments in
            await handler.getTechnicalIndicators(arguments: arguments)
        })
        
        // Chart patterns tool
        server.addTool(MCPTool(
            name: "detect_chart_patterns",
            description: "Detect chart patterns like head & shoulders, triangles, double tops/bottoms",
            inputSchema: createToolSchema(
                properties: [
                    "symbol": createProperty(
                        type: "string",
                        description: "Cryptocurrency symbol"
                    ),
                    "timeframe": createProperty(
                        type: "string",
                        description: "Timeframe: 4h, daily, weekly (default: daily)"
                    )
                ],
                required: ["symbol"]
            )
        ) { arguments in
            await handler.detectChartPatterns(arguments: arguments)
        })
        
        // Multi-timeframe analysis tool
        server.addTool(MCPTool(
            name: "multi_timeframe_analysis",
            description: "Analyze trends and signals across multiple timeframes",
            inputSchema: createToolSchema(
                properties: [
                    "symbol": createProperty(
                        type: "string",
                        description: "Cryptocurrency symbol"
                    )
                ],
                required: ["symbol"]
            )
        ) { arguments in
            await handler.getMultiTimeframeAnalysis(arguments: arguments)
        })
        
        // Trading signals tool
        server.addTool(MCPTool(
            name: "get_trading_signals",
            description: "Generate buy/sell/hold signals based on technical analysis",
            inputSchema: createToolSchema(
                properties: [
                    "symbol": createProperty(
                        type: "string",
                        description: "Cryptocurrency symbol"
                    ),
                    "risk_level": createProperty(
                        type: "string",
                        description: "Risk level: conservative, moderate, aggressive (default: moderate)"
                    ),
                    "timeframe": createProperty(
                        type: "string",
                        description: "Timeframe: 4h, daily, weekly (default: daily)"
                    )
                ],
                required: ["symbol"]
            )
        ) { arguments in
            await handler.getTradingSignals(arguments: arguments)
        })
        
        // Support/Resistance tool
        server.addTool(MCPTool(
            name: "get_support_resistance",
            description: "Find key support and resistance levels",
            inputSchema: createToolSchema(
                properties: [
                    "symbol": createProperty(
                        type: "string",
                        description: "Cryptocurrency symbol"
                    ),
                    "timeframe": createProperty(
                        type: "string",
                        description: "Timeframe: 4h, daily, weekly (default: daily)"
                    )
                ],
                required: ["symbol"]
            )
        ) { arguments in
            await handler.getSupportResistance(arguments: arguments)
        })
        
        // Full analysis tool
        server.addTool(MCPTool(
            name: "get_full_analysis",
            description: "Get comprehensive technical analysis including all indicators, patterns, and signals",
            inputSchema: createToolSchema(
                properties: [
                    "symbol": createProperty(
                        type: "string",
                        description: "Cryptocurrency symbol"
                    ),
                    "timeframe": createProperty(
                        type: "string",
                        description: "Timeframe: 4h, daily, weekly (default: daily)"
                    ),
                    "risk_level": createProperty(
                        type: "string",
                        description: "Risk level: conservative, moderate, aggressive (default: moderate)"
                    )
                ],
                required: ["symbol"]
            )
        ) { arguments in
            await handler.getFullAnalysis(arguments: arguments)
        })
    }
}

// MARK: - Crypto Analysis Handler

actor CryptoAnalysisHandler {
    private let dataProvider = CryptoDataProvider()
    private let technicalAnalyzer = TechnicalAnalyzer()
    private let patternRecognizer = ChartPatternRecognizer()
    private let supportResistanceAnalyzer = SupportResistanceAnalyzer()
    private let logger = Logger(label: "CryptoAnalysisHandler")
    
    // Cache for performance
    private var analysisCache: [String: (data: AnalysisResult, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 120 // 2 minutes
    
    // Accessor for DexPaprika provider
    var dexPaprikaProvider: DexPaprikaDataProvider {
        get async {
            await dataProvider.dexPaprikaProvider
        }
    }
    
    // MARK: - Tool Implementation Methods
    
    func getCurrentPrice(arguments: [String: Any]) async -> [String: Any] {
        guard let symbol = arguments["symbol"] as? String else {
            return ["error": "Symbol is required"]
        }
        
        do {
            let priceData = try await dataProvider.getCurrentPrice(symbol: symbol.uppercased())
            logger.info("Retrieved price data for \(symbol): $\(String(format: "%.2f", priceData.price))")
            return formatPriceData(priceData)
        } catch {
            logger.error("Failed to get price for \(symbol): \(error)")
            return ["error": "Failed to fetch price data: \(error.localizedDescription)"]
        }
    }
    
    func getTechnicalIndicators(arguments: [String: Any]) async -> [String: Any] {
        guard let symbol = arguments["symbol"] as? String else {
            return ["error": "Symbol is required"]
        }
        
        let timeframe = parseTimeframe(arguments["timeframe"] as? String)
        
        do {
            let historicalData = try await dataProvider.getHistoricalData(
                symbol: symbol.uppercased(),
                timeframe: timeframe,
                periods: 200
            )
            
            guard !historicalData.isEmpty else {
                return ["error": "No historical data available for \(symbol)"]
            }
            
            let indicators = await technicalAnalyzer.calculateAllIndicators(data: historicalData)
            let latestIndicators = getLatestIndicatorValues(indicators)
            
            logger.info("Calculated \(indicators.count) indicators for \(symbol)")
            
            return [
                "symbol": symbol.uppercased(),
                "timeframe": timeframe.rawValue,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "indicators": latestIndicators,
                "data_points": historicalData.count
            ]
        } catch {
            logger.error("Failed to calculate indicators: \(error)")
            return ["error": error.localizedDescription]
        }
    }
    
    func detectChartPatterns(arguments: [String: Any]) async -> [String: Any] {
        guard let symbol = arguments["symbol"] as? String else {
            return ["error": "Symbol is required"]
        }
        
        let timeframe = parseTimeframe(arguments["timeframe"] as? String)
        
        do {
            let historicalData = try await dataProvider.getHistoricalData(
                symbol: symbol.uppercased(),
                timeframe: timeframe,
                periods: 100
            )
            
            guard !historicalData.isEmpty else {
                return ["error": "No historical data available for \(symbol)"]
            }
            
            let patterns = await patternRecognizer.detectPatterns(data: historicalData)
            
            logger.info("Detected \(patterns.count) patterns for \(symbol)")
            
            return [
                "symbol": symbol.uppercased(),
                "timeframe": timeframe.rawValue,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "patterns": patterns.map(formatPattern),
                "pattern_count": patterns.count
            ]
        } catch {
            logger.error("Failed to detect patterns: \(error)")
            return ["error": error.localizedDescription]
        }
    }
    
    func getMultiTimeframeAnalysis(arguments: [String: Any]) async -> [String: Any] {
        guard let symbol = arguments["symbol"] as? String else {
            return ["error": "Symbol is required"]
        }
        
        var timeframeResults: [String: [String: Any]] = [:]
        let timeframes: [Timeframe] = [.fourHour, .daily, .weekly]
        
        for timeframe in timeframes {
            do {
                let data = try await dataProvider.getHistoricalData(
                    symbol: symbol.uppercased(),
                    timeframe: timeframe,
                    periods: 100
                )
                
                if !data.isEmpty {
                    let indicators = await technicalAnalyzer.calculateAllIndicators(data: data)
                    let patterns = await patternRecognizer.detectPatterns(data: data)
                    let levels = await supportResistanceAnalyzer.findKeyLevels(data: data, timeframe: timeframe)
                    
                    let (overallSignal, confidence) = await technicalAnalyzer.generateOverallSignal(indicators: indicators)
                    
                    timeframeResults[timeframe.rawValue] = [
                        "indicators": getLatestIndicatorValues(indicators),
                        "patterns": patterns.map(formatPattern),
                        "key_levels": levels.prefix(5).map(formatSupportResistance),
                        "overall_signal": overallSignal.rawValue,
                        "confidence": confidence,
                        "trend": determineTrend(from: indicators)
                    ]
                }
            } catch {
                logger.warning("Failed to analyze \(timeframe.rawValue): \(error)")
            }
        }
        
        return [
            "symbol": symbol.uppercased(),
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "timeframes": timeframeResults,
            "analysis_summary": generateMultiTimeframeSummary(timeframeResults)
        ]
    }
    
    func getTradingSignals(arguments: [String: Any]) async -> [String: Any] {
        guard let symbol = arguments["symbol"] as? String else {
            return ["error": "Symbol is required"]
        }
        
        let riskLevel = parseRiskLevel(arguments["risk_level"] as? String)
        let timeframe = parseTimeframe(arguments["timeframe"] as? String)
        
        do {
            let data = try await dataProvider.getHistoricalData(
                symbol: symbol.uppercased(),
                timeframe: timeframe,
                periods: 100
            )
            
            let currentPrice = try await dataProvider.getCurrentPrice(symbol: symbol.uppercased())
            let indicators = await technicalAnalyzer.calculateAllIndicators(data: data)
            let patterns = await patternRecognizer.detectPatterns(data: data)
            let levels = await supportResistanceAnalyzer.findKeyLevels(data: data)
            
            let signals = await generateTradingSignals(
                indicators: indicators,
                patterns: patterns,
                levels: levels,
                currentPrice: currentPrice,
                riskLevel: riskLevel
            )
            
            return [
                "symbol": symbol.uppercased(),
                "timeframe": timeframe.rawValue,
                "risk_level": riskLevel.rawValue,
                "current_price": currentPrice.price,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "signals": signals
            ]
        } catch {
            logger.error("Failed to generate signals: \(error)")
            return ["error": error.localizedDescription]
        }
    }
    
    func getSupportResistance(arguments: [String: Any]) async -> [String: Any] {
        guard let symbol = arguments["symbol"] as? String else {
            return ["error": "Symbol is required"]
        }
        
        let timeframe = parseTimeframe(arguments["timeframe"] as? String)
        
        do {
            let data = try await dataProvider.getHistoricalData(
                symbol: symbol.uppercased(),
                timeframe: timeframe,
                periods: 100
            )
            
            let levels = await supportResistanceAnalyzer.findKeyLevels(data: data, timeframe: timeframe)
            let currentPrice = try await dataProvider.getCurrentPrice(symbol: symbol.uppercased())
            
            return [
                "symbol": symbol.uppercased(),
                "timeframe": timeframe.rawValue,
                "current_price": currentPrice.price,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "support_levels": levels.filter { $0.type == .support }.map(formatSupportResistance),
                "resistance_levels": levels.filter { $0.type == .resistance }.map(formatSupportResistance),
                "nearest_support": findNearestLevel(levels.filter { $0.type == .support }, to: currentPrice.price) as Any,
                "nearest_resistance": findNearestLevel(levels.filter { $0.type == .resistance }, to: currentPrice.price) as Any
            ]
        } catch {
            logger.error("Failed to find levels: \(error)")
            return ["error": error.localizedDescription]
        }
    }
    
    func getFullAnalysis(arguments: [String: Any]) async -> [String: Any] {
        guard let symbol = arguments["symbol"] as? String else {
            return ["error": "Symbol is required"]
        }
        
        let timeframe = parseTimeframe(arguments["timeframe"] as? String)
        let riskLevel = parseRiskLevel(arguments["risk_level"] as? String)
        let cacheKey = "\(symbol.uppercased())_\(timeframe.rawValue)_\(riskLevel.rawValue)"
        
        // Check cache
        if let cached = analysisCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            logger.info("Returning cached analysis for \(symbol)")
            return formatAnalysisResult(cached.data)
        }
        
        do {
            logger.info("Performing full analysis for \(symbol)")
            
            let currentPrice = try await dataProvider.getCurrentPrice(symbol: symbol.uppercased())
            let historicalData = try await dataProvider.getHistoricalData(
                symbol: symbol.uppercased(),
                timeframe: timeframe,
                periods: 200
            )
            
            // Perform all analyses
            async let indicators = technicalAnalyzer.calculateAllIndicators(data: historicalData)
            async let patterns = patternRecognizer.detectPatterns(data: historicalData)
            async let levels = supportResistanceAnalyzer.findKeyLevels(data: historicalData, timeframe: timeframe)
            
            let (calculatedIndicators, detectedPatterns, keyLevels) = await (indicators, patterns, levels)
            
            let (overallSignal, confidence) = await technicalAnalyzer.generateOverallSignal(indicators: calculatedIndicators)
            
            let analysisResult = AnalysisResult(
                symbol: symbol.uppercased(),
                timestamp: Date(),
                currentPrice: currentPrice.price,
                indicators: calculatedIndicators,
                patterns: detectedPatterns,
                supportResistance: keyLevels,
                signals: [overallSignal],
                overallSignal: overallSignal,
                confidence: confidence,
                summary: generateComprehensiveSummary(
                    symbol: symbol,
                    price: currentPrice,
                    indicators: calculatedIndicators,
                    patterns: detectedPatterns,
                    levels: keyLevels,
                    signal: overallSignal,
                    confidence: confidence
                ),
                recommendations: generateRecommendations(
                    indicators: calculatedIndicators,
                    patterns: detectedPatterns,
                    levels: keyLevels,
                    riskLevel: riskLevel
                )
            )
            
            // Cache the result
            analysisCache[cacheKey] = (analysisResult, Date())
            
            logger.info("Completed full analysis for \(symbol)")
            
            return formatAnalysisResult(analysisResult)
        } catch {
            logger.error("Full analysis failed: \(error)")
            return ["error": error.localizedDescription]
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateTradingSignals(
        indicators: [IndicatorResult],
        patterns: [ChartPattern],
        levels: [SupportResistanceLevel],
        currentPrice: PriceData,
        riskLevel: RiskLevel
    ) async -> [String: Any] {
        
        let (indicatorSignal, indicatorConfidence) = await technicalAnalyzer.generateOverallSignal(indicators: indicators)
        
        // Pattern-based signals
        let recentPatterns = patterns.filter { $0.confidence >= riskLevel.signalThreshold }
        let patternSignals = recentPatterns.map { $0.type.isBullish ? TradingSignal.buy : TradingSignal.sell }
        
        // Support/Resistance signals
        let nearestSupport = findNearestLevel(levels.filter { $0.type == .support }, to: currentPrice.price)
        let nearestResistance = findNearestLevel(levels.filter { $0.type == .resistance }, to: currentPrice.price)
        
        var levelSignal = TradingSignal.hold
        if let support = nearestSupport, abs(currentPrice.price - support) / currentPrice.price < 0.02 {
            levelSignal = .buy
        } else if let resistance = nearestResistance, abs(currentPrice.price - resistance) / currentPrice.price < 0.02 {
            levelSignal = .sell
        }
        
        // Combine signals
        let allSignals = [indicatorSignal, levelSignal] + patternSignals
        let signalCounts = allSignals.reduce(into: [TradingSignal: Int]()) { counts, signal in
            counts[signal, default: 0] += 1
        }
        
        let totalSignals = allSignals.count
        let buySignals = signalCounts[.buy, default: 0] + signalCounts[.strongBuy, default: 0]
        let sellSignals = signalCounts[.sell, default: 0] + signalCounts[.strongSell, default: 0]
        
        let finalSignal: TradingSignal
        let confidence: Double
        
        if Double(buySignals) / Double(totalSignals) >= 0.6 {
            finalSignal = .buy
            confidence = Double(buySignals) / Double(totalSignals)
        } else if Double(sellSignals) / Double(totalSignals) >= 0.6 {
            finalSignal = .sell
            confidence = Double(sellSignals) / Double(totalSignals)
        } else {
            finalSignal = .hold
            confidence = 0.5
        }
        
        return [
            "primary_signal": finalSignal.rawValue,
            "confidence": confidence,
            "signal_breakdown": [
                "indicator_signal": indicatorSignal.rawValue,
                "indicator_confidence": indicatorConfidence,
                "pattern_signals": patternSignals.map { $0.rawValue },
                "level_signal": levelSignal.rawValue
            ],
            "risk_adjusted": confidence >= riskLevel.signalThreshold,
            "entry_price": currentPrice.price,
            "stop_loss": calculateStopLoss(signal: finalSignal, price: currentPrice.price, levels: levels) as Any,
            "take_profit": calculateTakeProfit(signal: finalSignal, price: currentPrice.price, levels: levels) as Any,
            "reasoning": generateSignalReasoning(
                signal: finalSignal,
                indicators: indicators,
                patterns: recentPatterns,
                levels: levels,
                currentPrice: currentPrice.price
            )
        ]
    }
    
    private func generateMultiTimeframeSummary(_ timeframeResults: [String: [String: Any]]) -> String {
        let timeframes = timeframeResults.keys.sorted()
        let summary = "Multi-timeframe analysis shows: "
        
        let summaryParts = timeframes.compactMap { timeframe -> String? in
            guard let results = timeframeResults[timeframe],
                  let trend = results["trend"] as? String,
                  let signal = results["overall_signal"] as? String else { return nil }
            
            return "\(timeframe) \(trend.lowercased()) with \(signal.lowercased()) signal"
        }
        
        return summary + summaryParts.joined(separator: ", ")
    }
}
