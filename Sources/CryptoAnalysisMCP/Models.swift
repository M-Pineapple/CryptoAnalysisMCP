import Foundation

// MARK: - Core Data Models

/// Represents OHLCV (Open, High, Low, Close, Volume) candle data
struct CandleData {
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    /// Returns the candle body size
    var bodySize: Double {
        abs(close - open)
    }
    
    /// Returns the upper shadow size
    var upperShadow: Double {
        high - max(open, close)
    }
    
    /// Returns the lower shadow size
    var lowerShadow: Double {
        min(open, close) - low
    }
    
    /// True if bullish candle (close > open)
    var isBullish: Bool {
        close > open
    }
    
    /// True if bearish candle (close < open)
    var isBearish: Bool {
        close < open
    }
    
    /// True if doji (very small body)
    var isDoji: Bool {
        bodySize <= (high - low) * 0.1
    }
}

/// Real-time price data with market information
struct PriceData {
    let symbol: String
    let price: Double
    let change24h: Double
    let changePercent24h: Double
    let volume24h: Double
    let marketCap: Double?
    let timestamp: Date
    let rank: Int?
    
    // Additional market data from CoinPaprika
    let percentChange15m: Double?
    let percentChange30m: Double?
    let percentChange1h: Double?
    let percentChange6h: Double?
    let percentChange12h: Double?
    let percentChange7d: Double?
    let percentChange30d: Double?
    let percentChange1y: Double?
    let athPrice: Double?
    let athDate: Date?
}

/// Technical indicator results
struct IndicatorResult {
    let name: String
    let value: Double
    let signal: TradingSignal
    let timestamp: Date
    let parameters: [String: Any]
}

/// Trading signal enumeration
enum TradingSignal: String, CaseIterable {
    case strongBuy = "STRONG_BUY"
    case buy = "BUY"
    case hold = "HOLD"
    case sell = "SELL"
    case strongSell = "STRONG_SELL"
    
    var numericValue: Double {
        switch self {
        case .strongBuy: return 2.0
        case .buy: return 1.0
        case .hold: return 0.0
        case .sell: return -1.0
        case .strongSell: return -2.0
        }
    }
}

/// Chart pattern detection result
struct ChartPattern {
    let type: PatternType
    let confidence: Double
    let startDate: Date
    let endDate: Date
    let keyPoints: [PatternPoint]
    let description: String
    let target: Double?
    let stopLoss: Double?
}

/// Pattern types that can be detected
enum PatternType: String, CaseIterable {
    // Reversal Patterns
    case headAndShoulders = "HEAD_AND_SHOULDERS"
    case inverseHeadAndShoulders = "INVERSE_HEAD_AND_SHOULDERS"
    case doubleTop = "DOUBLE_TOP"
    case doubleBottom = "DOUBLE_BOTTOM"
    case tripleTop = "TRIPLE_TOP"
    case tripleBottom = "TRIPLE_BOTTOM"
    
    // Continuation Patterns
    case ascendingTriangle = "ASCENDING_TRIANGLE"
    case descendingTriangle = "DESCENDING_TRIANGLE"
    case symmetricalTriangle = "SYMMETRICAL_TRIANGLE"
    case flag = "FLAG"
    case pennant = "PENNANT"
    case rectangle = "RECTANGLE"
    case risingWedge = "RISING_WEDGE"
    case fallingWedge = "FALLING_WEDGE"
    
    // Candlestick Patterns
    case hammer = "HAMMER"
    case shootingStar = "SHOOTING_STAR"
    case doji = "DOJI"
    case engulfing = "ENGULFING"
    case harami = "HARAMI"
    case morningStar = "MORNING_STAR"
    case eveningStar = "EVENING_STAR"
    
    var isReversal: Bool {
        switch self {
        case .headAndShoulders, .inverseHeadAndShoulders, .doubleTop, .doubleBottom,
             .tripleTop, .tripleBottom, .hammer, .shootingStar, .doji,
             .engulfing, .harami, .morningStar, .eveningStar:
            return true
        default:
            return false
        }
    }
    
    var isBullish: Bool {
        switch self {
        case .inverseHeadAndShoulders, .doubleBottom, .tripleBottom, .hammer,
             .engulfing, .harami, .morningStar:
            return true
        case .headAndShoulders, .doubleTop, .tripleTop, .shootingStar, .eveningStar:
            return false
        default:
            return false // Neutral or depends on context
        }
    }
}

/// Key point in a chart pattern
struct PatternPoint {
    let timestamp: Date
    let price: Double
    let type: PointType
}

enum PointType: String {
    case peak = "PEAK"
    case trough = "TROUGH"
    case breakout = "BREAKOUT"
    case support = "SUPPORT"
    case resistance = "RESISTANCE"
}

/// Support and resistance level
struct SupportResistanceLevel {
    let price: Double
    let strength: Double // 0.0 to 1.0
    let type: LevelType
    let touches: Int
    let lastTouch: Date
    let isActive: Bool
}

enum LevelType: String {
    case support = "SUPPORT"
    case resistance = "RESISTANCE"
    case pivotPoint = "PIVOT_POINT"
    case fibonacciLevel = "FIBONACCI_LEVEL"
}

/// Timeframe enumeration
enum Timeframe: String, CaseIterable {
    case fourHour = "4h"
    case daily = "1d"
    case weekly = "1w"
    case monthly = "1M"
    
    var minutes: Int {
        switch self {
        case .fourHour: return 240
        case .daily: return 1440
        case .weekly: return 10080
        case .monthly: return 43200
        }
    }
    
    var seconds: TimeInterval {
        return TimeInterval(minutes * 60)
    }
}

/// Multi-timeframe analysis result
struct MultiTimeframeAnalysis {
    let symbol: String
    let timestamp: Date
    let timeframes: [Timeframe: TimeframeAnalysis]
    let overallSignal: TradingSignal
    let confidence: Double
    let recommendation: String
}

struct TimeframeAnalysis {
    let timeframe: Timeframe
    let trend: TrendDirection
    let indicators: [IndicatorResult]
    let patterns: [ChartPattern]
    let keyLevels: [SupportResistanceLevel]
    let signal: TradingSignal
}

enum TrendDirection: String {
    case strongUptrend = "STRONG_UPTREND"
    case uptrend = "UPTREND"
    case sideways = "SIDEWAYS"
    case downtrend = "DOWNTREND"
    case strongDowntrend = "STRONG_DOWNTREND"
}

/// Comprehensive analysis result
struct AnalysisResult {
    let symbol: String
    let timestamp: Date
    let currentPrice: Double
    let indicators: [IndicatorResult]
    let patterns: [ChartPattern]
    let supportResistance: [SupportResistanceLevel]
    let signals: [TradingSignal]
    let overallSignal: TradingSignal
    let confidence: Double
    let summary: String
    let recommendations: [String]
}

/// Risk level for trading signals
enum RiskLevel: String, CaseIterable {
    case conservative = "CONSERVATIVE"
    case moderate = "MODERATE"
    case aggressive = "AGGRESSIVE"
    
    var signalThreshold: Double {
        switch self {
        case .conservative: return 0.8
        case .moderate: return 0.6
        case .aggressive: return 0.4
        }
    }
}

/// API Error types
enum CryptoAnalysisError: Error, LocalizedError {
    case invalidSymbol(String)
    case networkError(String)
    case dataParsingError(String)
    case insufficientData(String)
    case rateLimitExceeded
    case apiKeyMissing
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidSymbol(let symbol):
            return "Invalid cryptocurrency symbol: \(symbol)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .dataParsingError(let message):
            return "Data parsing error: \(message)"
        case .insufficientData(let message):
            return "Insufficient data: \(message)"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again later."
        case .apiKeyMissing:
            return "API key is missing or invalid"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
