import Foundation

// MARK: - Analysis Formatters Extension

extension Date {
    /// Format date for display
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Formatting Functions

/// Parse timeframe string to enum
func parseTimeframe(_ timeframeString: String?) -> Timeframe {
    guard let timeframe = timeframeString else { return .daily }
    
    switch timeframe.lowercased() {
    case "4h", "4hour", "4-hour":
        return .fourHour
    case "daily", "1d", "day":
        return .daily
    case "weekly", "1w", "week":
        return .weekly
    case "monthly", "1m", "month":
        return .monthly
    default:
        return .daily
    }
}

/// Parse risk level string to enum
func parseRiskLevel(_ riskString: String?) -> RiskLevel {
    guard let risk = riskString else { return .moderate }
    
    switch risk.lowercased() {
    case "conservative", "low":
        return .conservative
    case "moderate", "medium", "mid":
        return .moderate
    case "aggressive", "high":
        return .aggressive
    default:
        return .moderate
    }
}

/// Format price data for JSON response
func formatPriceData(_ priceData: PriceData) -> [String: Any] {
    var result: [String: Any] = [
        "symbol": priceData.symbol,
        "price": priceData.price,
        "change_24h": priceData.change24h,
        "change_percent_24h": priceData.changePercent24h,
        "volume_24h": priceData.volume24h,
        "timestamp": ISO8601DateFormatter().string(from: priceData.timestamp)
    ]
    
    if let marketCap = priceData.marketCap {
        result["market_cap"] = marketCap
    }
    
    if let rank = priceData.rank {
        result["rank"] = rank
    }
    
    // Add additional timeframe changes
    var changes: [String: Any] = [:]
    if let change15m = priceData.percentChange15m { changes["15m"] = change15m }
    if let change30m = priceData.percentChange30m { changes["30m"] = change30m }
    if let change1h = priceData.percentChange1h { changes["1h"] = change1h }
    if let change6h = priceData.percentChange6h { changes["6h"] = change6h }
    if let change12h = priceData.percentChange12h { changes["12h"] = change12h }
    if let change7d = priceData.percentChange7d { changes["7d"] = change7d }
    if let change30d = priceData.percentChange30d { changes["30d"] = change30d }
    if let change1y = priceData.percentChange1y { changes["1y"] = change1y }
    
    if !changes.isEmpty {
        result["percent_changes"] = changes
    }
    
    // Add ATH information
    if let athPrice = priceData.athPrice {
        result["ath_price"] = athPrice
        if let athDate = priceData.athDate {
            result["ath_date"] = ISO8601DateFormatter().string(from: athDate)
        }
    }
    
    return result
}

/// Format chart pattern for JSON response
func formatPattern(_ pattern: ChartPattern) -> [String: Any] {
    var result: [String: Any] = [
        "type": pattern.type.rawValue,
        "confidence": pattern.confidence,
        "start_date": ISO8601DateFormatter().string(from: pattern.startDate),
        "end_date": ISO8601DateFormatter().string(from: pattern.endDate),
        "description": pattern.description,
        "is_reversal": pattern.type.isReversal,
        "is_bullish": pattern.type.isBullish
    ]
    
    if let target = pattern.target {
        result["target_price"] = target
    }
    
    if let stopLoss = pattern.stopLoss {
        result["stop_loss"] = stopLoss
    }
    
    result["key_points"] = pattern.keyPoints.map { point in
        [
            "timestamp": ISO8601DateFormatter().string(from: point.timestamp),
            "price": point.price,
            "type": point.type.rawValue
        ]
    }
    
    return result
}

/// Format support/resistance level for JSON response
func formatSupportResistance(_ level: SupportResistanceLevel) -> [String: Any] {
    return [
        "price": level.price,
        "strength": level.strength,
        "type": level.type.rawValue,
        "touches": level.touches,
        "last_touch": ISO8601DateFormatter().string(from: level.lastTouch),
        "is_active": level.isActive
    ]
}

/// Format analysis result for JSON response
func formatAnalysisResult(_ result: AnalysisResult) -> [String: Any] {
    return [
        "symbol": result.symbol,
        "timestamp": ISO8601DateFormatter().string(from: result.timestamp),
        "current_price": result.currentPrice,
        "overall_signal": result.overallSignal.rawValue,
        "confidence": result.confidence,
        "summary": result.summary,
        "recommendations": result.recommendations,
        "indicators": [
            "latest_values": getLatestIndicatorValues(result.indicators),
            "signals": result.indicators.map { [
                "name": $0.name,
                "value": $0.value,
                "signal": $0.signal.rawValue,
                "timestamp": ISO8601DateFormatter().string(from: $0.timestamp)
            ]}
        ],
        "patterns": [
            "count": result.patterns.count,
            "detected": result.patterns.map(formatPattern)
        ],
        "support_resistance": [
            "support_levels": result.supportResistance.filter { $0.type == .support }.map(formatSupportResistance),
            "resistance_levels": result.supportResistance.filter { $0.type == .resistance }.map(formatSupportResistance),
            "key_levels_count": result.supportResistance.count
        ]
    ]
}

/// Get latest values for each indicator type
func getLatestIndicatorValues(_ indicators: [IndicatorResult]) -> [String: Any] {
    var latest: [String: Any] = [:]
    
    // Group indicators by name and get the latest value for each
    let groupedIndicators = Dictionary(grouping: indicators) { $0.name }
    
    for (name, indicatorGroup) in groupedIndicators {
        if let latestIndicator = indicatorGroup.max(by: { $0.timestamp < $1.timestamp }) {
            latest[name] = [
                "value": latestIndicator.value,
                "signal": latestIndicator.signal.rawValue,
                "parameters": latestIndicator.parameters
            ]
        }
    }
    
    return latest
}

/// Find nearest price level
func findNearestLevel(_ levels: [SupportResistanceLevel], to price: Double) -> Double? {
    return levels.min { abs($0.price - price) < abs($1.price - price) }?.price
}

/// Calculate stop loss based on signal and levels
func calculateStopLoss(signal: TradingSignal, price: Double, levels: [SupportResistanceLevel]) -> Double? {
    switch signal {
    case .buy, .strongBuy:
        // Stop loss below nearest support
        if let support = findNearestLevel(levels.filter { $0.type == .support && $0.price < price }, to: price) {
            return support * 0.98 // 2% below support
        }
        return price * 0.95 // Default 5% stop loss
    case .sell, .strongSell:
        // Stop loss above nearest resistance
        if let resistance = findNearestLevel(levels.filter { $0.type == .resistance && $0.price > price }, to: price) {
            return resistance * 1.02 // 2% above resistance
        }
        return price * 1.05 // Default 5% stop loss
    default:
        return nil
    }
}

/// Calculate take profit based on signal and levels
func calculateTakeProfit(signal: TradingSignal, price: Double, levels: [SupportResistanceLevel]) -> Double? {
    switch signal {
    case .buy, .strongBuy:
        // Take profit at nearest resistance
        if let resistance = findNearestLevel(levels.filter { $0.type == .resistance && $0.price > price }, to: price) {
            return resistance * 0.98 // Just below resistance
        }
        return price * 1.10 // Default 10% profit target
    case .sell, .strongSell:
        // Take profit at nearest support
        if let support = findNearestLevel(levels.filter { $0.type == .support && $0.price < price }, to: price) {
            return support * 1.02 // Just above support
        }
        return price * 0.90 // Default 10% profit target
    default:
        return nil
    }
}

/// Generate trading signal reasoning
func generateSignalReasoning(
    signal: TradingSignal,
    indicators: [IndicatorResult],
    patterns: [ChartPattern],
    levels: [SupportResistanceLevel],
    currentPrice: Double
) -> String {
    var reasons: [String] = []
    
    // Indicator reasoning
    let latestIndicators = getLatestIndicatorValues(indicators)
    if let rsi = latestIndicators["RSI_14"] as? [String: Any],
       let rsiValue = rsi["value"] as? Double {
        if rsiValue > 70 {
            reasons.append("RSI shows overbought conditions (\(String(format: "%.1f", rsiValue)))")
        } else if rsiValue < 30 {
            reasons.append("RSI shows oversold conditions (\(String(format: "%.1f", rsiValue)))")
        }
    }
    
    // Pattern reasoning
    if !patterns.isEmpty {
        let patternTypes = patterns.map { $0.type.rawValue }.joined(separator: ", ")
        reasons.append("Chart patterns detected: \(patternTypes)")
    }
    
    // Level reasoning
    let nearestSupport = findNearestLevel(levels.filter { $0.type == .support }, to: currentPrice)
    let nearestResistance = findNearestLevel(levels.filter { $0.type == .resistance }, to: currentPrice)
    
    if let support = nearestSupport {
        let distance = abs(currentPrice - support) / currentPrice
        if distance < 0.03 {
            reasons.append("Price near key support level at \(String(format: "%.2f", support))")
        }
    }
    
    if let resistance = nearestResistance {
        let distance = abs(currentPrice - resistance) / currentPrice
        if distance < 0.03 {
            reasons.append("Price near key resistance level at \(String(format: "%.2f", resistance))")
        }
    }
    
    return reasons.isEmpty ? "Analysis based on overall technical indicators" : reasons.joined(separator: ". ")
}

/// Determine overall trend from indicators
func determineTrend(from indicators: [IndicatorResult]) -> String {
    let latest = getLatestIndicatorValues(indicators)
    
    var bullishCount = 0
    var bearishCount = 0
    
    // Check EMA alignment
    if let ema20 = latest["EMA_20"] as? [String: Any],
       let ema50 = latest["EMA_50"] as? [String: Any],
       let ema20Value = ema20["value"] as? Double,
       let ema50Value = ema50["value"] as? Double {
        if ema20Value > ema50Value {
            bullishCount += 1
        } else {
            bearishCount += 1
        }
    }
    
    // Check MACD
    if let macd = latest["MACD_12_26_9"] as? [String: Any],
       let signal = macd["signal"] as? String {
        if signal == "BUY" {
            bullishCount += 1
        } else if signal == "SELL" {
            bearishCount += 1
        }
    }
    
    if bullishCount > bearishCount {
        return "UPTREND"
    } else if bearishCount > bullishCount {
        return "DOWNTREND"
    } else {
        return "SIDEWAYS"
    }
}

/// Generate comprehensive summary
func generateComprehensiveSummary(
    symbol: String,
    price: PriceData,
    indicators: [IndicatorResult],
    patterns: [ChartPattern],
    levels: [SupportResistanceLevel],
    signal: TradingSignal,
    confidence: Double
) -> String {
    
    let trend = determineTrend(from: indicators)
    let patternCount = patterns.count
    let levelCount = levels.count
    
    return """
    \(symbol) is currently trading at $\(String(format: "%.2f", price.price)) with a \(trend.lowercased()) bias. 
    Technical analysis shows \(signal.rawValue.lowercased()) signal with \(String(format: "%.1f", confidence * 100))% confidence. 
    \(patternCount) chart patterns detected and \(levelCount) key support/resistance levels identified. 
    24h change: \(String(format: "%.2f", price.changePercent24h))%.
    """
}

/// Generate recommendations based on analysis
func generateRecommendations(
    indicators: [IndicatorResult],
    patterns: [ChartPattern],
    levels: [SupportResistanceLevel],
    riskLevel: RiskLevel
) -> [String] {
    
    var recommendations: [String] = []
    
    // Risk-based recommendations
    switch riskLevel {
    case .conservative:
        recommendations.append("Wait for strong confirmation signals before entering positions")
        recommendations.append("Use tight stop losses and smaller position sizes")
    case .moderate:
        recommendations.append("Consider entering positions on pullbacks to support levels")
        recommendations.append("Use standard risk management with 2% position risk")
    case .aggressive:
        recommendations.append("Can take positions on early signals with larger size")
        recommendations.append("Use wider stops to avoid getting stopped out by volatility")
    }
    
    // Pattern-based recommendations
    if !patterns.isEmpty {
        let highConfidencePatterns = patterns.filter { $0.confidence > 0.7 }
        if !highConfidencePatterns.isEmpty {
            recommendations.append("Strong chart patterns suggest potential price movement")
        }
    }
    
    // Level-based recommendations
    let strongLevels = levels.filter { $0.strength > 0.7 }
    if !strongLevels.isEmpty {
        recommendations.append("Monitor key support/resistance levels for breakout opportunities")
    }
    
    recommendations.append("Always use proper risk management and position sizing")
    
    return recommendations
}
