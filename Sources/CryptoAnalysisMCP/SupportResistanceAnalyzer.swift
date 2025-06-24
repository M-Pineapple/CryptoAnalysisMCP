import Foundation
import Logging

/// Analyzes price data to identify support and resistance levels
actor SupportResistanceAnalyzer {
    private let logger = Logger(label: "SupportResistanceAnalyzer")
    
    /// Minimum touches required for a level to be considered significant
    private let minTouches = 2
    
    /// Price tolerance for grouping similar levels
    private let priceTolerance = 0.02 // 2%
    
    /// Main method to find key support and resistance levels
    func findKeyLevels(data: [CandleData], timeframe: Timeframe = .daily) async -> [SupportResistanceLevel] {
        guard data.count >= 20 else {
            logger.info("Insufficient data for support/resistance analysis")
            return []
        }
        
        var allLevels: [SupportResistanceLevel] = []
        
        // Method 1: Pivot-based levels
        let pivotLevels = findPivotBasedLevels(data: data)
        allLevels.append(contentsOf: pivotLevels)
        
        // Method 2: Volume profile levels
        let volumeLevels = findVolumeProfileLevels(data: data)
        allLevels.append(contentsOf: volumeLevels)
        
        // Method 3: Fibonacci levels
        let fiboLevels = findFibonacciLevels(data: data)
        allLevels.append(contentsOf: fiboLevels)
        
        // Method 4: Psychological levels (round numbers)
        let psychoLevels = findPsychologicalLevels(data: data)
        allLevels.append(contentsOf: psychoLevels)
        
        // Consolidate and rank levels
        let consolidatedLevels = consolidateLevels(allLevels)
        
        // Sort by strength and filter active levels
        let sortedLevels = consolidatedLevels
            .filter { $0.isActive }
            .sorted { $0.strength > $1.strength }
        
        logger.info("Found \(sortedLevels.count) key support/resistance levels")
        
        return sortedLevels
    }
    
    // MARK: - Pivot-based Support/Resistance
    
    private func findPivotBasedLevels(data: [CandleData]) -> [SupportResistanceLevel] {
        var levels: [SupportResistanceLevel] = []
        
        // Find local highs and lows
        var localHighs: [(price: Double, timestamp: Date, touches: Int)] = []
        var localLows: [(price: Double, timestamp: Date, touches: Int)] = []
        
        for i in 1..<(data.count - 1) {
            let prev = data[i - 1]
            let current = data[i]
            let next = data[i + 1]
            
            // Local high
            if current.high > prev.high && current.high > next.high {
                localHighs.append((price: current.high, timestamp: current.timestamp, touches: 1))
            }
            
            // Local low
            if current.low < prev.low && current.low < next.low {
                localLows.append((price: current.low, timestamp: current.timestamp, touches: 1))
            }
        }
        
        // Group similar price levels and count touches
        let groupedHighs = groupSimilarPriceLevels(localHighs)
        let groupedLows = groupSimilarPriceLevels(localLows)
        
        // Create resistance levels from highs
        for high in groupedHighs where high.touches >= minTouches {
            let level = SupportResistanceLevel(
                price: high.price,
                strength: calculateStrength(touches: high.touches, recency: high.timestamp),
                type: .resistance,
                touches: high.touches,
                lastTouch: high.timestamp,
                isActive: isLevelActive(price: high.price, currentPrice: data.last!.close)
            )
            levels.append(level)
        }
        
        // Create support levels from lows
        for low in groupedLows where low.touches >= minTouches {
            let level = SupportResistanceLevel(
                price: low.price,
                strength: calculateStrength(touches: low.touches, recency: low.timestamp),
                type: .support,
                touches: low.touches,
                lastTouch: low.timestamp,
                isActive: isLevelActive(price: low.price, currentPrice: data.last!.close)
            )
            levels.append(level)
        }
        
        return levels
    }
    
    // MARK: - Volume Profile Levels
    
    private func findVolumeProfileLevels(data: [CandleData]) -> [SupportResistanceLevel] {
        var levels: [SupportResistanceLevel] = []
        
        // Create price buckets
        let priceRange = data.map { $0.high }.max()! - data.map { $0.low }.min()!
        let bucketSize = priceRange / 50 // 50 price buckets
        let minPrice = data.map { $0.low }.min()!
        
        var volumeProfile: [Int: Double] = [:]
        
        // Accumulate volume in price buckets
        for candle in data {
            let avgPrice = (candle.high + candle.low + candle.close) / 3
            let bucketIndex = Int((avgPrice - minPrice) / bucketSize)
            volumeProfile[bucketIndex, default: 0] += candle.volume
        }
        
        // Find high volume nodes (potential support/resistance)
        let sortedBuckets = volumeProfile.sorted { $0.value > $1.value }
        let topBuckets = Array(sortedBuckets.prefix(10)) // Top 10 volume nodes
        
        for (bucketIndex, volume) in topBuckets {
            let price = minPrice + (Double(bucketIndex) + 0.5) * bucketSize
            let currentPrice = data.last!.close
            
            let levelType: LevelType = price < currentPrice ? .support : .resistance
            
            // Count how many times price touched this level
            let touches = countPriceTouches(price: price, data: data)
            
            if touches >= minTouches {
                let level = SupportResistanceLevel(
                    price: price,
                    strength: calculateVolumeStrength(volume: volume, totalVolume: volumeProfile.values.reduce(0, +)),
                    type: levelType,
                    touches: touches,
                    lastTouch: findLastTouch(price: price, data: data) ?? Date(),
                    isActive: true
                )
                levels.append(level)
            }
        }
        
        return levels
    }
    
    // MARK: - Fibonacci Levels
    
    private func findFibonacciLevels(data: [CandleData]) -> [SupportResistanceLevel] {
        var levels: [SupportResistanceLevel] = []
        
        // Find swing high and low
        let high = data.map { $0.high }.max()!
        let low = data.map { $0.low }.min()!
        let range = high - low
        
        // Fibonacci ratios
        let fibRatios = [0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0]
        
        for ratio in fibRatios {
            let price = low + (range * ratio)
            let currentPrice = data.last!.close
            
            // Count actual touches at this level
            let touches = countPriceTouches(price: price, data: data)
            
            if touches >= 1 { // Lower threshold for Fibonacci levels
                let levelType: LevelType = price < currentPrice ? .support : .resistance
                
                let level = SupportResistanceLevel(
                    price: price,
                    strength: 0.5 + (Double(touches) * 0.1), // Base strength + touch bonus
                    type: levelType,
                    touches: touches,
                    lastTouch: findLastTouch(price: price, data: data) ?? Date(),
                    isActive: true
                )
                levels.append(level)
            }
        }
        
        return levels
    }
    
    // MARK: - Psychological Levels
    
    private func findPsychologicalLevels(data: [CandleData]) -> [SupportResistanceLevel] {
        var levels: [SupportResistanceLevel] = []
        
        let currentPrice = data.last!.close
        
        // Determine appropriate round number interval based on price
        let interval: Double
        if currentPrice < 1 {
            interval = 0.1
        } else if currentPrice < 10 {
            interval = 1
        } else if currentPrice < 100 {
            interval = 10
        } else if currentPrice < 1000 {
            interval = 100
        } else if currentPrice < 10000 {
            interval = 1000
        } else {
            interval = 10000
        }
        
        // Find round numbers within the data range
        let minPrice = data.map { $0.low }.min()!
        let maxPrice = data.map { $0.high }.max()!
        
        var price = floor(minPrice / interval) * interval
        
        while price <= maxPrice {
            if price >= minPrice {
                // Count how many times price touched this level
                let touches = countPriceTouches(price: price, data: data)
                
                if touches >= 1 {
                    let levelType: LevelType = price < currentPrice ? .support : .resistance
                    
                    let level = SupportResistanceLevel(
                        price: price,
                        strength: 0.4 + (Double(touches) * 0.15), // Psychological levels have base strength
                        type: levelType,
                        touches: touches,
                        lastTouch: findLastTouch(price: price, data: data) ?? Date(),
                        isActive: true
                    )
                    levels.append(level)
                }
            }
            price += interval
        }
        
        return levels
    }
    
    // MARK: - Helper Methods
    
    private func groupSimilarPriceLevels(_ levels: [(price: Double, timestamp: Date, touches: Int)]) -> [(price: Double, timestamp: Date, touches: Int)] {
        guard !levels.isEmpty else { return [] }
        
        var grouped: [(price: Double, timestamp: Date, touches: Int)] = []
        var used = Set<Int>()
        
        for i in 0..<levels.count {
            if used.contains(i) { continue }
            
            var groupPrices: [Double] = [levels[i].price]
            var latestTimestamp = levels[i].timestamp
            var totalTouches = levels[i].touches
            
            for j in (i + 1)..<levels.count {
                if used.contains(j) { continue }
                
                let priceDiff = abs(levels[i].price - levels[j].price) / levels[i].price
                if priceDiff <= priceTolerance {
                    groupPrices.append(levels[j].price)
                    totalTouches += levels[j].touches
                    if levels[j].timestamp > latestTimestamp {
                        latestTimestamp = levels[j].timestamp
                    }
                    used.insert(j)
                }
            }
            
            let avgPrice = groupPrices.reduce(0, +) / Double(groupPrices.count)
            grouped.append((price: avgPrice, timestamp: latestTimestamp, touches: totalTouches))
        }
        
        return grouped
    }
    
    private func countPriceTouches(price: Double, data: [CandleData]) -> Int {
        var touches = 0
        
        for candle in data {
            let tolerance = price * priceTolerance
            
            // Check if high touched the level
            if abs(candle.high - price) <= tolerance {
                touches += 1
            }
            // Check if low touched the level
            else if abs(candle.low - price) <= tolerance {
                touches += 1
            }
            // Check if price passed through the level
            else if candle.low < price && candle.high > price {
                touches += 1
            }
        }
        
        return touches
    }
    
    private func findLastTouch(price: Double, data: [CandleData]) -> Date? {
        for candle in data.reversed() {
            let tolerance = price * priceTolerance
            
            if abs(candle.high - price) <= tolerance ||
               abs(candle.low - price) <= tolerance ||
               (candle.low < price && candle.high > price) {
                return candle.timestamp
            }
        }
        
        return nil
    }
    
    private func calculateStrength(touches: Int, recency: Date) -> Double {
        // Base strength from number of touches
        var strength = min(Double(touches) / 10.0, 0.5)
        
        // Recency bonus (more recent = stronger)
        let daysSinceTouch = Date().timeIntervalSince(recency) / (24 * 60 * 60)
        if daysSinceTouch < 7 {
            strength += 0.3
        } else if daysSinceTouch < 30 {
            strength += 0.2
        } else if daysSinceTouch < 90 {
            strength += 0.1
        }
        
        // Additional touches bonus
        if touches >= 5 {
            strength += 0.2
        } else if touches >= 3 {
            strength += 0.1
        }
        
        return min(strength, 1.0)
    }
    
    private func calculateVolumeStrength(volume: Double, totalVolume: Double) -> Double {
        let volumeRatio = volume / totalVolume
        return min(volumeRatio * 10, 1.0) // Scale up as volume nodes are typically small percentages
    }
    
    private func isLevelActive(price: Double, currentPrice: Double) -> Bool {
        // A level is active if it's within 10% of current price
        let distance = abs(price - currentPrice) / currentPrice
        return distance <= 0.1
    }
    
    private func consolidateLevels(_ levels: [SupportResistanceLevel]) -> [SupportResistanceLevel] {
        guard !levels.isEmpty else { return [] }
        
        var consolidated: [SupportResistanceLevel] = []
        var used = Set<Int>()
        
        let sortedLevels = levels.sorted { $0.price < $1.price }
        
        for i in 0..<sortedLevels.count {
            if used.contains(i) { continue }
            
            var groupedLevels = [sortedLevels[i]]
            
            for j in (i + 1)..<sortedLevels.count {
                if used.contains(j) { continue }
                
                let priceDiff = abs(sortedLevels[i].price - sortedLevels[j].price) / sortedLevels[i].price
                if priceDiff <= priceTolerance {
                    groupedLevels.append(sortedLevels[j])
                    used.insert(j)
                }
            }
            
            // Merge grouped levels
            let avgPrice = groupedLevels.map { $0.price }.reduce(0, +) / Double(groupedLevels.count)
            let maxStrength = groupedLevels.map { $0.strength }.max()!
            let totalTouches = groupedLevels.map { $0.touches }.reduce(0, +)
            let latestTouch = groupedLevels.map { $0.lastTouch }.max()!
            let levelType = groupedLevels.first!.type
            
            let consolidatedLevel = SupportResistanceLevel(
                price: avgPrice,
                strength: min(maxStrength + (Double(groupedLevels.count - 1) * 0.1), 1.0),
                type: levelType,
                touches: totalTouches,
                lastTouch: latestTouch,
                isActive: groupedLevels.contains { $0.isActive }
            )
            
            consolidated.append(consolidatedLevel)
        }
        
        return consolidated
    }
}

// MARK: - Extended Analysis Methods
extension SupportResistanceAnalyzer {
    
    /// Find dynamic support/resistance (trend lines)
    func findDynamicLevels(data: [CandleData]) async -> [(slope: Double, intercept: Double, type: LevelType)] {
        var trendLines: [(slope: Double, intercept: Double, type: LevelType)] = []
        
        // Find peaks and troughs
        var peaks: [(index: Int, price: Double)] = []
        var troughs: [(index: Int, price: Double)] = []
        
        for i in 1..<(data.count - 1) {
            if data[i].high > data[i-1].high && data[i].high > data[i+1].high {
                peaks.append((index: i, price: data[i].high))
            }
            if data[i].low < data[i-1].low && data[i].low < data[i+1].low {
                troughs.append((index: i, price: data[i].low))
            }
        }
        
        // Find resistance trend lines (connecting peaks)
        if peaks.count >= 2 {
            for i in 0..<(peaks.count - 1) {
                for j in (i + 1)..<peaks.count {
                    let slope = (peaks[j].price - peaks[i].price) / Double(peaks[j].index - peaks[i].index)
                    let intercept = peaks[i].price - slope * Double(peaks[i].index)
                    
                    // Validate trend line
                    if isTrendLineValid(slope: slope, intercept: intercept, points: peaks, data: data) {
                        trendLines.append((slope: slope, intercept: intercept, type: .resistance))
                    }
                }
            }
        }
        
        // Find support trend lines (connecting troughs)
        if troughs.count >= 2 {
            for i in 0..<(troughs.count - 1) {
                for j in (i + 1)..<troughs.count {
                    let slope = (troughs[j].price - troughs[i].price) / Double(troughs[j].index - troughs[i].index)
                    let intercept = troughs[i].price - slope * Double(troughs[i].index)
                    
                    // Validate trend line
                    if isTrendLineValid(slope: slope, intercept: intercept, points: troughs, data: data) {
                        trendLines.append((slope: slope, intercept: intercept, type: .support))
                    }
                }
            }
        }
        
        return trendLines
    }
    
    private func isTrendLineValid(slope: Double, intercept: Double, points: [(index: Int, price: Double)], data: [CandleData]) -> Bool {
        var touchCount = 0
        let tolerance = priceTolerance
        
        for point in points {
            let expectedPrice = slope * Double(point.index) + intercept
            let actualPrice = point.price
            
            if abs(actualPrice - expectedPrice) / actualPrice <= tolerance {
                touchCount += 1
            }
        }
        
        return touchCount >= 3 // Require at least 3 touches for a valid trend line
    }
}
