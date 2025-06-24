import Foundation
import Logging

/// Performs technical analysis calculations on cryptocurrency data
actor TechnicalAnalyzer {
    private let logger = Logger(label: "TechnicalAnalyzer")
    
    // MARK: - Moving Averages
    
    /// Calculate Simple Moving Average
    func calculateSMA(data: [CandleData], period: Int) -> [IndicatorResult] {
        guard data.count >= period else { return [] }
        
        var results: [IndicatorResult] = []
        
        for i in (period - 1)..<data.count {
            let slice = Array(data[(i - period + 1)...i])
            let sum = slice.reduce(0) { $0 + $1.close }
            let sma = sum / Double(period)
            
            let signal = determineTrendSignal(currentPrice: data[i].close, ma: sma, previousMA: i > period ? results.last?.value : nil)
            
            results.append(IndicatorResult(
                name: "SMA_\(period)",
                value: sma,
                signal: signal,
                timestamp: data[i].timestamp,
                parameters: ["period": period]
            ))
        }
        
        return results
    }
    
    /// Calculate Exponential Moving Average
    func calculateEMA(data: [CandleData], period: Int) -> [IndicatorResult] {
        guard data.count >= period else { return [] }
        
        let multiplier = 2.0 / (Double(period) + 1.0)
        var results: [IndicatorResult] = []
        
        // Start with SMA for the first value
        let firstSMA = Array(data[0..<period]).reduce(0) { $0 + $1.close } / Double(period)
        var ema = firstSMA
        
        for i in (period - 1)..<data.count {
            if i == period - 1 {
                ema = firstSMA
            } else {
                ema = (data[i].close * multiplier) + (ema * (1 - multiplier))
            }
            
            let signal = determineTrendSignal(currentPrice: data[i].close, ma: ema, previousMA: results.last?.value)
            
            results.append(IndicatorResult(
                name: "EMA_\(period)",
                value: ema,
                signal: signal,
                timestamp: data[i].timestamp,
                parameters: ["period": period, "multiplier": multiplier]
            ))
        }
        
        return results
    }
    
    // MARK: - Oscillators
    
    /// Calculate Relative Strength Index (RSI)
    func calculateRSI(data: [CandleData], period: Int = 14) -> [IndicatorResult] {
        guard data.count > period else { return [] }
        
        var results: [IndicatorResult] = []
        var gains: [Double] = []
        var losses: [Double] = []
        
        // Calculate price changes
        for i in 1..<data.count {
            let change = data[i].close - data[i-1].close
            gains.append(max(change, 0))
            losses.append(max(-change, 0))
        }
        
        // Calculate RSI for each point after the period
        for i in (period - 1)..<gains.count {
            let recentGains = Array(gains[(i - period + 1)...i])
            let recentLosses = Array(losses[(i - period + 1)...i])
            
            let avgGain = recentGains.reduce(0, +) / Double(period)
            let avgLoss = recentLosses.reduce(0, +) / Double(period)
            
            let rs = avgLoss == 0 ? 100 : avgGain / avgLoss
            let rsi = 100 - (100 / (1 + rs))
            
            let signal = determineRSISignal(rsi: rsi)
            
            results.append(IndicatorResult(
                name: "RSI_\(period)",
                value: rsi,
                signal: signal,
                timestamp: data[i + 1].timestamp, // +1 because gains/losses start from index 1
                parameters: ["period": period, "avgGain": avgGain, "avgLoss": avgLoss]
            ))
        }
        
        return results
    }
    
    /// Calculate Stochastic Oscillator
    func calculateStochastic(data: [CandleData], kPeriod: Int = 14, dPeriod: Int = 3) -> [IndicatorResult] {
        guard data.count >= kPeriod else { return [] }
        
        var kValues: [Double] = []
        var results: [IndicatorResult] = []
        
        // Calculate %K values
        for i in (kPeriod - 1)..<data.count {
            let slice = Array(data[(i - kPeriod + 1)...i])
            let highestHigh = slice.map { $0.high }.max() ?? 0
            let lowestLow = slice.map { $0.low }.min() ?? 0
            
            let k = lowestLow == highestHigh ? 50 : ((data[i].close - lowestLow) / (highestHigh - lowestLow)) * 100
            kValues.append(k)
        }
        
        // Calculate %D (SMA of %K)
        for i in (dPeriod - 1)..<kValues.count {
            let dSlice = Array(kValues[(i - dPeriod + 1)...i])
            let d = dSlice.reduce(0, +) / Double(dPeriod)
            
            let k = kValues[i]
            let signal = determineStochasticSignal(k: k, d: d)
            
            results.append(IndicatorResult(
                name: "STOCH_\(kPeriod)_\(dPeriod)",
                value: k,
                signal: signal,
                timestamp: data[i + kPeriod].timestamp,
                parameters: ["kPeriod": kPeriod, "dPeriod": dPeriod, "percentK": k, "percentD": d]
            ))
        }
        
        return results
    }
    
    /// Calculate MACD (Moving Average Convergence Divergence)
    func calculateMACD(data: [CandleData], fastPeriod: Int = 12, slowPeriod: Int = 26, signalPeriod: Int = 9) -> [IndicatorResult] {
        guard data.count >= slowPeriod else { return [] }
        
        let fastEMA = calculateEMA(data: data, period: fastPeriod)
        let slowEMA = calculateEMA(data: data, period: slowPeriod)
        
        guard fastEMA.count >= signalPeriod && slowEMA.count >= signalPeriod else { return [] }
        
        var macdLine: [Double] = []
        var results: [IndicatorResult] = []
        
        // Calculate MACD line (fast EMA - slow EMA)
        let startIndex = slowPeriod - fastPeriod
        for i in 0..<min(fastEMA.count, slowEMA.count) {
            let macd = fastEMA[i + startIndex].value - slowEMA[i].value
            macdLine.append(macd)
        }
        
        // Calculate Signal line (EMA of MACD line)
        guard macdLine.count >= signalPeriod else { return [] }
        
        let multiplier = 2.0 / (Double(signalPeriod) + 1.0)
        var signalLine = macdLine[0..<signalPeriod].reduce(0, +) / Double(signalPeriod)
        
        for i in (signalPeriod - 1)..<macdLine.count {
            if i > signalPeriod - 1 {
                signalLine = (macdLine[i] * multiplier) + (signalLine * (1 - multiplier))
            }
            
            let histogram = macdLine[i] - signalLine
            let signal = determineMACDSignal(macd: macdLine[i], signal: signalLine, histogram: histogram)
            
            results.append(IndicatorResult(
                name: "MACD_\(fastPeriod)_\(slowPeriod)_\(signalPeriod)",
                value: macdLine[i],
                signal: signal,
                timestamp: data[i + slowPeriod].timestamp,
                parameters: [
                    "fastPeriod": fastPeriod,
                    "slowPeriod": slowPeriod,
                    "signalPeriod": signalPeriod,
                    "signalLine": signalLine,
                    "histogram": histogram
                ]
            ))
        }
        
        return results
    }
    
    // MARK: - Bollinger Bands
    
    /// Calculate Bollinger Bands
    func calculateBollingerBands(data: [CandleData], period: Int = 20, standardDeviations: Double = 2.0) -> [IndicatorResult] {
        guard data.count >= period else { return [] }
        
        var results: [IndicatorResult] = []
        
        for i in (period - 1)..<data.count {
            let slice = Array(data[(i - period + 1)...i])
            let closes = slice.map { $0.close }
            
            // Calculate SMA (middle band)
            let sma = closes.reduce(0, +) / Double(period)
            
            // Calculate standard deviation
            let variance = closes.map { pow($0 - sma, 2) }.reduce(0, +) / Double(period)
            let stdDev = sqrt(variance)
            
            // Calculate bands
            let upperBand = sma + (standardDeviations * stdDev)
            let lowerBand = sma - (standardDeviations * stdDev)
            
            let currentPrice = data[i].close
            let signal = determineBollingerSignal(price: currentPrice, upper: upperBand, middle: sma, lower: lowerBand)
            
            results.append(IndicatorResult(
                name: "BB_\(period)_\(standardDeviations)",
                value: sma,
                signal: signal,
                timestamp: data[i].timestamp,
                parameters: [
                    "period": period,
                    "standardDeviations": standardDeviations,
                    "upperBand": upperBand,
                    "lowerBand": lowerBand,
                    "bandwidth": (upperBand - lowerBand) / sma,
                    "percentB": (currentPrice - lowerBand) / (upperBand - lowerBand)
                ]
            ))
        }
        
        return results
    }
    
    // MARK: - Williams %R
    
    /// Calculate Williams %R
    func calculateWilliamsR(data: [CandleData], period: Int = 14) -> [IndicatorResult] {
        guard data.count >= period else { return [] }
        
        var results: [IndicatorResult] = []
        
        for i in (period - 1)..<data.count {
            let slice = Array(data[(i - period + 1)...i])
            let highestHigh = slice.map { $0.high }.max() ?? 0
            let lowestLow = slice.map { $0.low }.min() ?? 0
            
            let williamsR = highestHigh == lowestLow ? -50 : ((highestHigh - data[i].close) / (highestHigh - lowestLow)) * -100
            
            let signal = determineWilliamsRSignal(williamsR: williamsR)
            
            results.append(IndicatorResult(
                name: "WILLIAMS_R_\(period)",
                value: williamsR,
                signal: signal,
                timestamp: data[i].timestamp,
                parameters: [
                    "period": period,
                    "highestHigh": highestHigh,
                    "lowestLow": lowestLow
                ]
            ))
        }
        
        return results
    }
    
    // MARK: - Volume Indicators
    
    /// Calculate On-Balance Volume (OBV)
    func calculateOBV(data: [CandleData]) -> [IndicatorResult] {
        guard data.count > 1 else { return [] }
        
        var results: [IndicatorResult] = []
        var obv: Double = 0
        
        for i in 1..<data.count {
            if data[i].close > data[i-1].close {
                obv += data[i].volume
            } else if data[i].close < data[i-1].close {
                obv -= data[i].volume
            }
            // If equal, OBV remains the same
            
            let signal = determineVolumeSignal(obv: obv, previousOBV: results.last?.value)
            
            results.append(IndicatorResult(
                name: "OBV",
                value: obv,
                signal: signal,
                timestamp: data[i].timestamp,
                parameters: ["volume": data[i].volume, "priceChange": data[i].close - data[i-1].close]
            ))
        }
        
        return results
    }
}

// MARK: - Signal Determination Methods
extension TechnicalAnalyzer {
    
    private func determineTrendSignal(currentPrice: Double, ma: Double, previousMA: Double?) -> TradingSignal {
        let priceAboveMA = currentPrice > ma
        
        if let prevMA = previousMA {
            let maRising = ma > prevMA
            
            if priceAboveMA && maRising {
                return .buy
            } else if !priceAboveMA && !maRising {
                return .sell
            }
        }
        
        return priceAboveMA ? .hold : .hold
    }
    
    private func determineRSISignal(rsi: Double) -> TradingSignal {
        if rsi >= 70 {
            return .sell // Overbought
        } else if rsi <= 30 {
            return .buy // Oversold
        } else if rsi >= 60 {
            return .hold // Approaching overbought
        } else if rsi <= 40 {
            return .hold // Approaching oversold
        }
        return .hold
    }
    
    private func determineStochasticSignal(k: Double, d: Double) -> TradingSignal {
        if k >= 80 && d >= 80 {
            return .sell // Overbought
        } else if k <= 20 && d <= 20 {
            return .buy // Oversold
        } else if k > d && k < 80 {
            return .buy // Bullish crossover
        } else if k < d && k > 20 {
            return .sell // Bearish crossover
        }
        return .hold
    }
    
    private func determineMACDSignal(macd: Double, signal: Double, histogram: Double) -> TradingSignal {
        if macd > signal && histogram > 0 {
            return .buy // Bullish
        } else if macd < signal && histogram < 0 {
            return .sell // Bearish
        }
        return .hold
    }
    
    private func determineBollingerSignal(price: Double, upper: Double, middle: Double, lower: Double) -> TradingSignal {
        let percentB = (price - lower) / (upper - lower)
        
        if percentB >= 1.0 {
            return .sell // Price above upper band (overbought)
        } else if percentB <= 0.0 {
            return .buy // Price below lower band (oversold)
        } else if percentB > 0.8 {
            return .hold // Approaching upper band
        } else if percentB < 0.2 {
            return .hold // Approaching lower band
        }
        return .hold
    }
    
    private func determineWilliamsRSignal(williamsR: Double) -> TradingSignal {
        if williamsR >= -20 {
            return .sell // Overbought
        } else if williamsR <= -80 {
            return .buy // Oversold
        }
        return .hold
    }
    
    private func determineVolumeSignal(obv: Double, previousOBV: Double?) -> TradingSignal {
        guard let prevOBV = previousOBV else { return .hold }
        
        if obv > prevOBV {
            return .buy // Volume supporting upward movement
        } else if obv < prevOBV {
            return .sell // Volume supporting downward movement
        }
        return .hold
    }
}

// MARK: - Comprehensive Analysis
extension TechnicalAnalyzer {
    
    /// Calculate all major technical indicators for a dataset
    func calculateAllIndicators(data: [CandleData]) async -> [IndicatorResult] {
        guard !data.isEmpty else { return [] }
        
        var allIndicators: [IndicatorResult] = []
        
        // Moving Averages
        allIndicators.append(contentsOf: calculateSMA(data: data, period: 5))
        allIndicators.append(contentsOf: calculateSMA(data: data, period: 10))
        allIndicators.append(contentsOf: calculateSMA(data: data, period: 20))
        allIndicators.append(contentsOf: calculateSMA(data: data, period: 50))
        allIndicators.append(contentsOf: calculateSMA(data: data, period: 200))
        
        allIndicators.append(contentsOf: calculateEMA(data: data, period: 5))
        allIndicators.append(contentsOf: calculateEMA(data: data, period: 10))
        allIndicators.append(contentsOf: calculateEMA(data: data, period: 20))
        allIndicators.append(contentsOf: calculateEMA(data: data, period: 50))
        
        // Oscillators
        allIndicators.append(contentsOf: calculateRSI(data: data, period: 14))
        allIndicators.append(contentsOf: calculateRSI(data: data, period: 21))
        allIndicators.append(contentsOf: calculateStochastic(data: data, kPeriod: 14, dPeriod: 3))
        allIndicators.append(contentsOf: calculateWilliamsR(data: data, period: 14))
        
        // MACD
        allIndicators.append(contentsOf: calculateMACD(data: data, fastPeriod: 12, slowPeriod: 26, signalPeriod: 9))
        
        // Bollinger Bands
        allIndicators.append(contentsOf: calculateBollingerBands(data: data, period: 20, standardDeviations: 2.0))
        
        // Volume
        allIndicators.append(contentsOf: calculateOBV(data: data))
        
        logger.info("Calculated \(allIndicators.count) technical indicators")
        
        return allIndicators
    }
    
    /// Generate an overall trading signal based on multiple indicators
    func generateOverallSignal(indicators: [IndicatorResult]) -> (signal: TradingSignal, confidence: Double) {
        guard !indicators.isEmpty else { return (.hold, 0.0) }
        
        let signalCounts = indicators.reduce(into: [TradingSignal: Double]()) { counts, indicator in
            counts[indicator.signal, default: 0] += 1
        }
        
        let totalCount = Double(indicators.count)
        var weightedScore: Double = 0
        
        for (signal, count) in signalCounts {
            let weight = count / totalCount
            weightedScore += signal.numericValue * weight
        }
        
        let confidence = abs(weightedScore) / 2.0 // Normalize to 0-1 scale
        
        let finalSignal: TradingSignal
        if weightedScore >= 0.5 {
            finalSignal = .buy
        } else if weightedScore <= -0.5 {
            finalSignal = .sell
        } else {
            finalSignal = .hold
        }
        
        return (finalSignal, min(confidence, 1.0))
    }
}
