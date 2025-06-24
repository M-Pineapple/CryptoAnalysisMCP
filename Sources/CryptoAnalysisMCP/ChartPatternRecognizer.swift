import Foundation
import Logging

/// Recognizes chart patterns in price data
actor ChartPatternRecognizer {
    private let logger = Logger(label: "ChartPatternRecognizer")
    private let priceTolerancePercent = 0.02 // 2% tolerance for price comparisons
    
    /// Main entry point for pattern detection
    func detectPatterns(data: [CandleData]) async -> [ChartPattern] {
        guard data.count >= 10 else { 
            logger.info("Insufficient data for pattern detection (need at least 10 candles)")
            return [] 
        }
        
        var allPatterns: [ChartPattern] = []
        
        // Find pivot points first
        let pivots = findPivotPoints(data: data)
        
        // Detect various pattern types
        let reversalPatterns = await detectReversalPatterns(data: data, pivots: pivots)
        let continuationPatterns = await detectContinuationPatterns(data: data, pivots: pivots)
        let candlestickPatterns = await detectCandlestickPatterns(data: data)
        
        allPatterns.append(contentsOf: reversalPatterns)
        allPatterns.append(contentsOf: continuationPatterns)
        allPatterns.append(contentsOf: candlestickPatterns)
        
        // Sort by confidence
        allPatterns.sort { $0.confidence > $1.confidence }
        
        logger.info("Detected \(allPatterns.count) patterns")
        
        return allPatterns
    }
    
    // MARK: - Pivot Point Detection
    
    private func findPivotPoints(data: [CandleData]) -> [PatternPoint] {
        var pivots: [PatternPoint] = []
        
        guard data.count >= 3 else { return [] }
        
        for i in 1..<(data.count - 1) {
            let prev = data[i - 1]
            let current = data[i]
            let next = data[i + 1]
            
            // Check for peak (high point)
            if current.high > prev.high && current.high > next.high {
                pivots.append(PatternPoint(
                    timestamp: current.timestamp,
                    price: current.high,
                    type: .peak
                ))
            }
            
            // Check for trough (low point)
            if current.low < prev.low && current.low < next.low {
                pivots.append(PatternPoint(
                    timestamp: current.timestamp,
                    price: current.low,
                    type: .trough
                ))
            }
        }
        
        return pivots
    }
    
    // MARK: - Reversal Pattern Detection
    
    private func detectReversalPatterns(data: [CandleData], pivots: [PatternPoint]) async -> [ChartPattern] {
        var patterns: [ChartPattern] = []
        
        // Head and Shoulders / Inverse Head and Shoulders
        patterns.append(contentsOf: detectHeadAndShoulders(data: data, pivots: pivots))
        
        // Double Top/Bottom
        patterns.append(contentsOf: detectDoubleTopBottom(data: data, pivots: pivots))
        
        // Triple Top/Bottom
        patterns.append(contentsOf: detectTripleTopBottom(data: data, pivots: pivots))
        
        return patterns
    }
    
    private func detectHeadAndShoulders(data: [CandleData], pivots: [PatternPoint]) -> [ChartPattern] {
        var patterns: [ChartPattern] = []
        let peaks = pivots.filter { $0.type == .peak }
        let troughs = pivots.filter { $0.type == .trough }
        
        // Head and Shoulders (bearish reversal)
        if peaks.count >= 3 && troughs.count >= 2 {
            for i in 0..<(peaks.count - 2) {
                let leftShoulder = peaks[i]
                let head = peaks[i + 1]
                let rightShoulder = peaks[i + 2]
                
                // Head should be higher than both shoulders
                if head.price > leftShoulder.price && head.price > rightShoulder.price {
                    // Shoulders should be roughly equal
                    let shoulderDiff = abs(leftShoulder.price - rightShoulder.price) / leftShoulder.price
                    if shoulderDiff <= priceTolerancePercent {
                        // Find the neckline (troughs between shoulders and head)
                        let necklineTroughs = troughs.filter {
                            $0.timestamp > leftShoulder.timestamp && $0.timestamp < rightShoulder.timestamp
                        }
                        
                        if necklineTroughs.count >= 2 {
                            let necklinePrice = necklineTroughs.map { $0.price }.reduce(0, +) / Double(necklineTroughs.count)
                            let patternHeight = head.price - necklinePrice
                            let targetPrice = necklinePrice - patternHeight
                            
                            let pattern = ChartPattern(
                                type: .headAndShoulders,
                                confidence: calculateHeadAndShouldersConfidence(
                                    leftShoulder: leftShoulder,
                                    head: head,
                                    rightShoulder: rightShoulder,
                                    necklineTroughs: necklineTroughs
                                ),
                                startDate: leftShoulder.timestamp,
                                endDate: rightShoulder.timestamp,
                                keyPoints: [leftShoulder, head, rightShoulder] + necklineTroughs,
                                description: "Head and Shoulders pattern detected. Bearish reversal signal.",
                                target: targetPrice,
                                stopLoss: head.price
                            )
                            patterns.append(pattern)
                        }
                    }
                }
            }
        }
        
        // Inverse Head and Shoulders (bullish reversal)
        if troughs.count >= 3 && peaks.count >= 2 {
            for i in 0..<(troughs.count - 2) {
                let leftShoulder = troughs[i]
                let head = troughs[i + 1]
                let rightShoulder = troughs[i + 2]
                
                // Head should be lower than both shoulders
                if head.price < leftShoulder.price && head.price < rightShoulder.price {
                    // Shoulders should be roughly equal
                    let shoulderDiff = abs(leftShoulder.price - rightShoulder.price) / leftShoulder.price
                    if shoulderDiff <= priceTolerancePercent {
                        // Find the neckline (peaks between shoulders and head)
                        let necklinePeaks = peaks.filter {
                            $0.timestamp > leftShoulder.timestamp && $0.timestamp < rightShoulder.timestamp
                        }
                        
                        if necklinePeaks.count >= 2 {
                            let necklinePrice = necklinePeaks.map { $0.price }.reduce(0, +) / Double(necklinePeaks.count)
                            let patternHeight = necklinePrice - head.price
                            let targetPrice = necklinePrice + patternHeight
                            
                            let pattern = ChartPattern(
                                type: .inverseHeadAndShoulders,
                                confidence: calculateHeadAndShouldersConfidence(
                                    leftShoulder: leftShoulder,
                                    head: head,
                                    rightShoulder: rightShoulder,
                                    necklineTroughs: necklinePeaks
                                ),
                                startDate: leftShoulder.timestamp,
                                endDate: rightShoulder.timestamp,
                                keyPoints: [leftShoulder, head, rightShoulder] + necklinePeaks,
                                description: "Inverse Head and Shoulders pattern detected. Bullish reversal signal.",
                                target: targetPrice,
                                stopLoss: head.price
                            )
                            patterns.append(pattern)
                        }
                    }
                }
            }
        }
        
        return patterns
    }
    
    private func detectDoubleTopBottom(data: [CandleData], pivots: [PatternPoint]) -> [ChartPattern] {
        var patterns: [ChartPattern] = []
        let peaks = pivots.filter { $0.type == .peak }
        let troughs = pivots.filter { $0.type == .trough }
        
        // Double Top
        if peaks.count >= 2 {
            for i in 0..<(peaks.count - 1) {
                let firstPeak = peaks[i]
                let secondPeak = peaks[i + 1]
                
                // Peaks should be roughly equal
                let peakDiff = abs(firstPeak.price - secondPeak.price) / firstPeak.price
                if peakDiff <= priceTolerancePercent {
                    // Find valley between peaks
                    let valley = troughs.filter {
                        $0.timestamp > firstPeak.timestamp && $0.timestamp < secondPeak.timestamp
                    }.min { $0.price < $1.price }
                    
                    if let valley = valley {
                        let patternHeight = firstPeak.price - valley.price
                        let targetPrice = valley.price - patternHeight
                        
                        let pattern = ChartPattern(
                            type: .doubleTop,
                            confidence: calculateDoubleTopConfidence(
                                firstPeak: firstPeak,
                                secondPeak: secondPeak,
                                valley: valley
                            ),
                            startDate: firstPeak.timestamp,
                            endDate: secondPeak.timestamp,
                            keyPoints: [firstPeak, valley, secondPeak],
                            description: "Double Top pattern detected. Bearish reversal signal.",
                            target: targetPrice,
                            stopLoss: max(firstPeak.price, secondPeak.price)
                        )
                        patterns.append(pattern)
                    }
                }
            }
        }
        
        // Double Bottom
        if troughs.count >= 2 {
            for i in 0..<(troughs.count - 1) {
                let firstTrough = troughs[i]
                let secondTrough = troughs[i + 1]
                
                // Troughs should be roughly equal
                let troughDiff = abs(firstTrough.price - secondTrough.price) / firstTrough.price
                if troughDiff <= priceTolerancePercent {
                    // Find peak between troughs
                    let peak = peaks.filter {
                        $0.timestamp > firstTrough.timestamp && $0.timestamp < secondTrough.timestamp
                    }.max { $0.price < $1.price }
                    
                    if let peak = peak {
                        let patternHeight = peak.price - firstTrough.price
                        let targetPrice = peak.price + patternHeight
                        
                        let pattern = ChartPattern(
                            type: .doubleBottom,
                            confidence: calculateDoubleBottomConfidence(
                                firstTrough: firstTrough,
                                secondTrough: secondTrough,
                                peak: peak
                            ),
                            startDate: firstTrough.timestamp,
                            endDate: secondTrough.timestamp,
                            keyPoints: [firstTrough, peak, secondTrough],
                            description: "Double Bottom pattern detected. Bullish reversal signal.",
                            target: targetPrice,
                            stopLoss: min(firstTrough.price, secondTrough.price)
                        )
                        patterns.append(pattern)
                    }
                }
            }
        }
        
        return patterns
    }
    
    private func detectTripleTopBottom(data: [CandleData], pivots: [PatternPoint]) -> [ChartPattern] {
        var patterns: [ChartPattern] = []
        let peaks = pivots.filter { $0.type == .peak }
        let troughs = pivots.filter { $0.type == .trough }
        
        // Triple Top
        if peaks.count >= 3 {
            for i in 0..<(peaks.count - 2) {
                let peak1 = peaks[i]
                let peak2 = peaks[i + 1]
                let peak3 = peaks[i + 2]
                
                // All three peaks should be roughly equal
                let variation1 = abs(peak1.price - peak2.price) / peak1.price
                let variation2 = abs(peak2.price - peak3.price) / peak2.price
                let variation3 = abs(peak1.price - peak3.price) / peak1.price
                
                if variation1 <= priceTolerancePercent && 
                   variation2 <= priceTolerancePercent && 
                   variation3 <= priceTolerancePercent {
                    
                    // Find supporting troughs
                    let supportingTroughs = troughs.filter { 
                        $0.timestamp > peak1.timestamp && $0.timestamp < peak3.timestamp 
                    }
                    
                    if supportingTroughs.count >= 2 {
                        let avgPeakPrice = (peak1.price + peak2.price + peak3.price) / 3
                        let lowestTrough = supportingTroughs.min { $0.price < $1.price }!
                        let target = lowestTrough.price - (avgPeakPrice - lowestTrough.price)
                        
                        let pattern = ChartPattern(
                            type: .tripleTop,
                            confidence: 0.75,
                            startDate: peak1.timestamp,
                            endDate: peak3.timestamp,
                            keyPoints: [peak1, peak2, peak3] + supportingTroughs,
                            description: "Triple Top reversal pattern detected.",
                            target: target,
                            stopLoss: avgPeakPrice
                        )
                        patterns.append(pattern)
                    }
                }
            }
        }
        
        // Triple Bottom
        if troughs.count >= 3 {
            for i in 0..<(troughs.count - 2) {
                let trough1 = troughs[i]
                let trough2 = troughs[i + 1]
                let trough3 = troughs[i + 2]
                
                // All three troughs should be roughly equal
                let variation1 = abs(trough1.price - trough2.price) / trough1.price
                let variation2 = abs(trough2.price - trough3.price) / trough2.price
                let variation3 = abs(trough1.price - trough3.price) / trough1.price
                
                if variation1 <= priceTolerancePercent && 
                   variation2 <= priceTolerancePercent && 
                   variation3 <= priceTolerancePercent {
                    
                    // Find resistance peaks
                    let resistancePeaks = peaks.filter { 
                        $0.timestamp > trough1.timestamp && $0.timestamp < trough3.timestamp 
                    }
                    
                    if resistancePeaks.count >= 2 {
                        let avgTroughPrice = (trough1.price + trough2.price + trough3.price) / 3
                        let highestPeak = resistancePeaks.max { $0.price < $1.price }!
                        let target = highestPeak.price + (highestPeak.price - avgTroughPrice)
                        
                        let pattern = ChartPattern(
                            type: .tripleBottom,
                            confidence: 0.75,
                            startDate: trough1.timestamp,
                            endDate: trough3.timestamp,
                            keyPoints: [trough1, trough2, trough3] + resistancePeaks,
                            description: "Triple Bottom reversal pattern detected.",
                            target: target,
                            stopLoss: avgTroughPrice
                        )
                        patterns.append(pattern)
                    }
                }
            }
        }
        
        return patterns
    }
    
    // MARK: - Continuation Pattern Detection
    
    private func detectContinuationPatterns(data: [CandleData], pivots: [PatternPoint]) async -> [ChartPattern] {
        var patterns: [ChartPattern] = []
        
        // Triangles
        patterns.append(contentsOf: detectTriangles(data: data, pivots: pivots))
        
        // Wedges
        patterns.append(contentsOf: detectWedges(data: data, pivots: pivots))
        
        // Rectangles
        patterns.append(contentsOf: detectRectangles(data: data, pivots: pivots))
        
        return patterns
    }
    
    private func detectTriangles(data: [CandleData], pivots: [PatternPoint]) -> [ChartPattern] {
        var patterns: [ChartPattern] = []
        
        let peaks = pivots.filter { $0.type == .peak }
        let troughs = pivots.filter { $0.type == .trough }
        
        guard peaks.count >= 2 && troughs.count >= 2 else { return [] }
        
        // Get recent peaks and troughs for triangle detection
        let recentPeaks = Array(peaks.suffix(3))
        let recentTroughs = Array(troughs.suffix(3))
        
        // Ascending Triangle
        if let pattern = detectAscendingTriangle(peaks: recentPeaks, troughs: recentTroughs) {
            patterns.append(pattern)
        }
        
        // Descending Triangle
        if let pattern = detectDescendingTriangle(peaks: recentPeaks, troughs: recentTroughs) {
            patterns.append(pattern)
        }
        
        // Symmetrical Triangle
        if let pattern = detectSymmetricalTriangle(peaks: recentPeaks, troughs: recentTroughs) {
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    private func detectAscendingTriangle(peaks: [PatternPoint], troughs: [PatternPoint]) -> ChartPattern? {
        guard peaks.count >= 2 && troughs.count >= 2 else { return nil }
        
        // Check for horizontal resistance (peaks at similar levels)
        let peakPrices = peaks.map { $0.price }
        let peakVariation = (peakPrices.max()! - peakPrices.min()!) / peakPrices.min()!
        
        guard peakVariation <= priceTolerancePercent else { return nil }
        
        // Check for rising support (ascending trough trend)
        guard troughs.count >= 2 else { return nil }
        let isRising = troughs.last!.price > troughs.first!.price
        guard isRising else { return nil }
        
        let resistanceLevel = peakPrices.reduce(0, +) / Double(peakPrices.count)
        let target = resistanceLevel + (resistanceLevel * 0.05) // 5% above resistance
        
        return ChartPattern(
            type: .ascendingTriangle,
            confidence: 0.7,
            startDate: troughs.first!.timestamp,
            endDate: peaks.last!.timestamp,
            keyPoints: troughs + peaks,
            description: "Ascending Triangle pattern. Bullish continuation signal.",
            target: target,
            stopLoss: troughs.last!.price
        )
    }
    
    private func detectDescendingTriangle(peaks: [PatternPoint], troughs: [PatternPoint]) -> ChartPattern? {
        guard peaks.count >= 2 && troughs.count >= 2 else { return nil }
        
        // Check for horizontal support (troughs at similar levels)
        let troughPrices = troughs.map { $0.price }
        let troughVariation = (troughPrices.max()! - troughPrices.min()!) / troughPrices.min()!
        
        guard troughVariation <= priceTolerancePercent else { return nil }
        
        // Check for falling resistance (descending peak trend)
        guard peaks.count >= 2 else { return nil }
        let isFalling = peaks.last!.price < peaks.first!.price
        guard isFalling else { return nil }
        
        let supportLevel = troughPrices.reduce(0, +) / Double(troughPrices.count)
        let target = supportLevel - (supportLevel * 0.05) // 5% below support
        
        return ChartPattern(
            type: .descendingTriangle,
            confidence: 0.7,
            startDate: peaks.first!.timestamp,
            endDate: troughs.last!.timestamp,
            keyPoints: peaks + troughs,
            description: "Descending Triangle pattern. Bearish continuation signal.",
            target: target,
            stopLoss: peaks.last!.price
        )
    }
    
    private func detectSymmetricalTriangle(peaks: [PatternPoint], troughs: [PatternPoint]) -> ChartPattern? {
        guard peaks.count >= 2 && troughs.count >= 2 else { return nil }
        
        // Check if peaks are descending and troughs are ascending (converging)
        let peaksDescending = peaks.last!.price < peaks.first!.price
        let troughsAscending = troughs.last!.price > troughs.first!.price
        
        guard peaksDescending && troughsAscending else { return nil }
        
        // Calculate convergence
        let priceRange = peaks.first!.price - troughs.first!.price
        let currentRange = peaks.last!.price - troughs.last!.price
        let compression = (priceRange - currentRange) / priceRange
        
        guard compression > 0.3 else { return nil } // At least 30% compression
        
        let midPoint = (peaks.last!.price + troughs.last!.price) / 2
        let target = midPoint + (priceRange * 0.5) // Breakout target
        
        return ChartPattern(
            type: .symmetricalTriangle,
            confidence: 0.65,
            startDate: min(peaks.first!.timestamp, troughs.first!.timestamp),
            endDate: max(peaks.last!.timestamp, troughs.last!.timestamp),
            keyPoints: peaks + troughs,
            description: "Symmetrical Triangle pattern. Neutral continuation signal.",
            target: target,
            stopLoss: troughs.last!.price
        )
    }
    
    private func detectWedges(data: [CandleData], pivots: [PatternPoint]) -> [ChartPattern] {
        var patterns: [ChartPattern] = []
        
        let peaks = pivots.filter { $0.type == .peak }
        let troughs = pivots.filter { $0.type == .trough }
        
        guard peaks.count >= 2 && troughs.count >= 2 else { return [] }
        
        let recentPeaks = Array(peaks.suffix(3))
        let recentTroughs = Array(troughs.suffix(3))
        
        // Rising Wedge
        if let pattern = detectRisingWedge(peaks: recentPeaks, troughs: recentTroughs) {
            patterns.append(pattern)
        }
        
        // Falling Wedge
        if let pattern = detectFallingWedge(peaks: recentPeaks, troughs: recentTroughs) {
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    private func detectRisingWedge(peaks: [PatternPoint], troughs: [PatternPoint]) -> ChartPattern? {
        guard peaks.count >= 2 && troughs.count >= 2 else { return nil }
        
        // Both trend lines should be rising
        let peaksRising = peaks.last!.price > peaks.first!.price
        let troughsRising = troughs.last!.price > troughs.first!.price
        
        guard peaksRising && troughsRising else { return nil }
        
        // Lines should be converging (getting closer)
        let initialRange = peaks.first!.price - troughs.first!.price
        let currentRange = peaks.last!.price - troughs.last!.price
        
        guard currentRange < initialRange else { return nil }
        
        return ChartPattern(
            type: .risingWedge,
            confidence: 0.6,
            startDate: min(peaks.first!.timestamp, troughs.first!.timestamp),
            endDate: max(peaks.last!.timestamp, troughs.last!.timestamp),
            keyPoints: peaks + troughs,
            description: "Rising Wedge pattern. Bearish reversal signal.",
            target: troughs.first!.price,
            stopLoss: peaks.last!.price
        )
    }
    
    private func detectFallingWedge(peaks: [PatternPoint], troughs: [PatternPoint]) -> ChartPattern? {
        guard peaks.count >= 2 && troughs.count >= 2 else { return nil }
        
        // Both trend lines should be falling
        let peaksFalling = peaks.last!.price < peaks.first!.price
        let troughsFalling = troughs.last!.price < troughs.first!.price
        
        guard peaksFalling && troughsFalling else { return nil }
        
        // Lines should be converging (getting closer)
        let initialRange = peaks.first!.price - troughs.first!.price
        let currentRange = peaks.last!.price - troughs.last!.price
        
        guard currentRange < initialRange else { return nil }
        
        return ChartPattern(
            type: .fallingWedge,
            confidence: 0.6,
            startDate: min(peaks.first!.timestamp, troughs.first!.timestamp),
            endDate: max(peaks.last!.timestamp, troughs.last!.timestamp),
            keyPoints: peaks + troughs,
            description: "Falling Wedge pattern. Bullish reversal signal.",
            target: peaks.first!.price,
            stopLoss: troughs.last!.price
        )
    }
    
    private func detectRectangles(data: [CandleData], pivots: [PatternPoint]) -> [ChartPattern] {
        var patterns: [ChartPattern] = []
        
        let peaks = pivots.filter { $0.type == .peak }
        let troughs = pivots.filter { $0.type == .trough }
        
        guard peaks.count >= 3 && troughs.count >= 3 else { return [] }
        
        // Check for horizontal resistance and support
        let peakPrices = peaks.map { $0.price }
        let troughPrices = troughs.map { $0.price }
        
        let peakVariation = (peakPrices.max()! - peakPrices.min()!) / peakPrices.min()!
        let troughVariation = (troughPrices.max()! - troughPrices.min()!) / troughPrices.min()!
        
        // Both resistance and support should be relatively flat
        if peakVariation <= priceTolerancePercent && troughVariation <= priceTolerancePercent {
            let resistance = peakPrices.reduce(0, +) / Double(peakPrices.count)
            let support = troughPrices.reduce(0, +) / Double(troughPrices.count)
            
            let pattern = ChartPattern(
                type: .rectangle,
                confidence: 0.65,
                startDate: min(peaks.first!.timestamp, troughs.first!.timestamp),
                endDate: max(peaks.last!.timestamp, troughs.last!.timestamp),
                keyPoints: peaks + troughs,
                description: "Rectangle consolidation pattern. Range-bound trading.",
                target: resistance + (resistance - support), // Breakout target
                stopLoss: support
            )
            
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    // MARK: - Candlestick Pattern Detection
    
    private func detectCandlestickPatterns(data: [CandleData]) async -> [ChartPattern] {
        var patterns: [ChartPattern] = []
        
        guard data.count >= 3 else { return [] }
        
        for i in 2..<data.count {
            let current = data[i]
            let previous = data[i-1]
            let beforePrevious = data[i-2]
            
            // Single candle patterns
            if let hammer = detectHammer(candle: current) {
                patterns.append(hammer)
            }
            
            if let shootingStar = detectShootingStar(candle: current) {
                patterns.append(shootingStar)
            }
            
            if let doji = detectDoji(candle: current) {
                patterns.append(doji)
            }
            
            // Two candle patterns
            if let engulfing = detectEngulfing(previous: previous, current: current) {
                patterns.append(engulfing)
            }
            
            // Three candle patterns
            if let star = detectStar(first: beforePrevious, second: previous, third: current) {
                patterns.append(star)
            }
        }
        
        return patterns
    }
    
    private func detectHammer(candle: CandleData) -> ChartPattern? {
        let bodySize = candle.bodySize
        let lowerShadow = candle.lowerShadow
        let upperShadow = candle.upperShadow
        let totalRange = candle.high - candle.low
        
        guard lowerShadow >= bodySize * 2 &&
              upperShadow <= bodySize * 0.1 &&
              totalRange > 0 else { return nil }
        
        return ChartPattern(
            type: .hammer,
            confidence: 0.6,
            startDate: candle.timestamp,
            endDate: candle.timestamp,
            keyPoints: [PatternPoint(timestamp: candle.timestamp, price: candle.close, type: .support)],
            description: "Hammer candlestick. Potential bullish reversal.",
            target: candle.close + (totalRange * 0.5),
            stopLoss: candle.low
        )
    }
    
    private func detectShootingStar(candle: CandleData) -> ChartPattern? {
        let bodySize = candle.bodySize
        let lowerShadow = candle.lowerShadow
        let upperShadow = candle.upperShadow
        let totalRange = candle.high - candle.low
        
        guard upperShadow >= bodySize * 2 &&
              lowerShadow <= bodySize * 0.1 &&
              totalRange > 0 else { return nil }
        
        return ChartPattern(
            type: .shootingStar,
            confidence: 0.6,
            startDate: candle.timestamp,
            endDate: candle.timestamp,
            keyPoints: [PatternPoint(timestamp: candle.timestamp, price: candle.close, type: .resistance)],
            description: "Shooting Star candlestick. Potential bearish reversal.",
            target: candle.close - (totalRange * 0.5),
            stopLoss: candle.high
        )
    }
    
    private func detectDoji(candle: CandleData) -> ChartPattern? {
        guard candle.isDoji else { return nil }
        
        return ChartPattern(
            type: .doji,
            confidence: 0.5,
            startDate: candle.timestamp,
            endDate: candle.timestamp,
            keyPoints: [PatternPoint(timestamp: candle.timestamp, price: candle.close, type: .support)],
            description: "Doji candlestick. Market indecision.",
            target: nil,
            stopLoss: nil
        )
    }
    
    private func detectEngulfing(previous: CandleData, current: CandleData) -> ChartPattern? {
        // Bullish Engulfing
        if previous.isBearish && current.isBullish &&
           current.open < previous.close && current.close > previous.open {
            
            return ChartPattern(
                type: .engulfing,
                confidence: 0.7,
                startDate: previous.timestamp,
                endDate: current.timestamp,
                keyPoints: [
                    PatternPoint(timestamp: previous.timestamp, price: previous.close, type: .support),
                    PatternPoint(timestamp: current.timestamp, price: current.close, type: .resistance)
                ],
                description: "Bullish Engulfing pattern. Strong bullish signal.",
                target: current.close + (current.close - previous.close),
                stopLoss: previous.low
            )
        }
        
        // Bearish Engulfing
        if previous.isBullish && current.isBearish &&
           current.open > previous.close && current.close < previous.open {
            
            return ChartPattern(
                type: .engulfing,
                confidence: 0.7,
                startDate: previous.timestamp,
                endDate: current.timestamp,
                keyPoints: [
                    PatternPoint(timestamp: previous.timestamp, price: previous.close, type: .resistance),
                    PatternPoint(timestamp: current.timestamp, price: current.close, type: .support)
                ],
                description: "Bearish Engulfing pattern. Strong bearish signal.",
                target: current.close - (previous.close - current.close),
                stopLoss: previous.high
            )
        }
        
        return nil
    }
    
    private func detectStar(first: CandleData, second: CandleData, third: CandleData) -> ChartPattern? {
        // Morning Star (bullish)
        if first.isBearish && second.bodySize < first.bodySize * 0.3 && third.isBullish &&
           third.close > (first.open + first.close) / 2 {
            
            return ChartPattern(
                type: .morningStar,
                confidence: 0.8,
                startDate: first.timestamp,
                endDate: third.timestamp,
                keyPoints: [
                    PatternPoint(timestamp: first.timestamp, price: first.close, type: .support),
                    PatternPoint(timestamp: second.timestamp, price: second.close, type: .support),
                    PatternPoint(timestamp: third.timestamp, price: third.close, type: .resistance)
                ],
                description: "Morning Star pattern. Strong bullish reversal.",
                target: third.close + (third.close - first.close),
                stopLoss: min(first.low, second.low, third.low)
            )
        }
        
        // Evening Star (bearish)
        if first.isBullish && second.bodySize < first.bodySize * 0.3 && third.isBearish &&
           third.close < (first.open + first.close) / 2 {
            
            return ChartPattern(
                type: .eveningStar,
                confidence: 0.8,
                startDate: first.timestamp,
                endDate: third.timestamp,
                keyPoints: [
                    PatternPoint(timestamp: first.timestamp, price: first.close, type: .resistance),
                    PatternPoint(timestamp: second.timestamp, price: second.close, type: .resistance),
                    PatternPoint(timestamp: third.timestamp, price: third.close, type: .support)
                ],
                description: "Evening Star pattern. Strong bearish reversal.",
                target: third.close - (first.close - third.close),
                stopLoss: max(first.high, second.high, third.high)
            )
        }
        
        return nil
    }
    
    // MARK: - Confidence Calculation Methods
    
    private func calculateHeadAndShouldersConfidence(
        leftShoulder: PatternPoint,
        head: PatternPoint,
        rightShoulder: PatternPoint,
        necklineTroughs: [PatternPoint]
    ) -> Double {
        var confidence: Double = 0.5
        
        // Check shoulder symmetry
        let shoulderDiff = abs(leftShoulder.price - rightShoulder.price) / leftShoulder.price
        confidence += (priceTolerancePercent - shoulderDiff) * 10
        
        // Check head prominence
        let headProminence = min(head.price - leftShoulder.price, head.price - rightShoulder.price) / head.price
        confidence += headProminence * 5
        
        // Check neckline consistency
        if necklineTroughs.count >= 2 {
            let necklinePrices = necklineTroughs.map { $0.price }
            let necklineVariation = (necklinePrices.max()! - necklinePrices.min()!) / necklinePrices.min()!
            confidence += (priceTolerancePercent - necklineVariation) * 5
        }
        
        return min(confidence, 1.0)
    }
    
    private func calculateDoubleTopConfidence(firstPeak: PatternPoint, secondPeak: PatternPoint, valley: PatternPoint) -> Double {
        var confidence: Double = 0.5
        
        // Check peak similarity
        let peakDiff = abs(firstPeak.price - secondPeak.price) / firstPeak.price
        confidence += (priceTolerancePercent - peakDiff) * 15
        
        // Check valley depth
        let valleyDepth = (firstPeak.price - valley.price) / firstPeak.price
        confidence += min(valleyDepth * 5, 0.3)
        
        return min(confidence, 1.0)
    }
    
    private func calculateDoubleBottomConfidence(firstTrough: PatternPoint, secondTrough: PatternPoint, peak: PatternPoint) -> Double {
        var confidence: Double = 0.5
        
        // Check trough similarity
        let troughDiff = abs(firstTrough.price - secondTrough.price) / firstTrough.price
        confidence += (priceTolerancePercent - troughDiff) * 15
        
        // Check peak height
        let peakHeight = (peak.price - firstTrough.price) / firstTrough.price
        confidence += min(peakHeight * 5, 0.3)
        
        return min(confidence, 1.0)
    }
}
