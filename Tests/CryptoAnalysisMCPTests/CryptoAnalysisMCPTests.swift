import XCTest
@testable import CryptoAnalysisMCP

final class CryptoAnalysisMCPTests: XCTestCase {
    
    func testTechnicalIndicatorCalculations() async throws {
        // Test data - simple ascending price pattern
        let testData = createTestCandleData()
        let analyzer = TechnicalAnalyzer()
        
        // Test SMA calculation
        let smaResults = analyzer.calculateSMA(data: testData, period: 5)
        XCTAssertFalse(smaResults.isEmpty, "SMA results should not be empty")
        
        // Test RSI calculation
        let rsiResults = analyzer.calculateRSI(data: testData, period: 14)
        XCTAssertFalse(rsiResults.isEmpty, "RSI results should not be empty")
        
        if let lastRSI = rsiResults.last {
            XCTAssertTrue(lastRSI.value >= 0 && lastRSI.value <= 100, "RSI should be between 0 and 100")
        }
    }
    
    func testChartPatternDetection() async throws {
        let testData = createHeadAndShouldersPattern()
        let recognizer = ChartPatternRecognizer()
        
        let patterns = await recognizer.detectPatterns(data: testData)
        
        // Should detect at least some patterns in structured test data
        XCTAssertFalse(patterns.isEmpty, "Should detect patterns in test data")
        
        // Check pattern confidence
        for pattern in patterns {
            XCTAssertTrue(pattern.confidence >= 0.0 && pattern.confidence <= 1.0, 
                         "Pattern confidence should be between 0 and 1")
        }
    }
    
    func testSupportResistanceAnalysis() async throws {
        let testData = createTestCandleData()
        let analyzer = SupportResistanceAnalyzer()
        
        let levels = await analyzer.findKeyLevels(data: testData)
        
        // Should find some levels
        XCTAssertFalse(levels.isEmpty, "Should find support/resistance levels")
        
        // Check level properties
        for level in levels {
            XCTAssertTrue(level.strength >= 0.0 && level.strength <= 1.0, 
                         "Level strength should be between 0 and 1")
            XCTAssertTrue(level.touches >= 2, "Levels should have at least 2 touches")
        }
    }
    
    func testDataProvider() async throws {
        let provider = CryptoDataProvider()
        
        // Test with a known cryptocurrency
        do {
            let priceData = try await provider.getCurrentPrice(symbol: "BTC")
            
            XCTAssertEqual(priceData.symbol, "BTC")
            XCTAssertTrue(priceData.price > 0, "Price should be positive")
            XCTAssertTrue(priceData.volume24h >= 0, "Volume should be non-negative")
        } catch {
            // This test might fail due to network issues or API limits
            // In a real test environment, you'd use mock data
            print("Network test failed (expected in some environments): \(error)")
        }
    }
    
    func testModelCreation() {
        let timestamp = Date()
        let candle = CandleData(
            timestamp: timestamp,
            open: 100.0,
            high: 110.0,
            low: 95.0,
            close: 105.0,
            volume: 1000.0
        )
        
        XCTAssertEqual(candle.bodySize, 5.0, "Body size should be |close - open|")
        XCTAssertTrue(candle.isBullish, "Candle should be bullish when close > open")
        XCTAssertFalse(candle.isBearish, "Candle should not be bearish when close > open")
        XCTAssertEqual(candle.upperShadow, 5.0, "Upper shadow should be high - max(open, close)")
        XCTAssertEqual(candle.lowerShadow, 5.0, "Lower shadow should be min(open, close) - low")
    }
    
    func testTradingSignalGeneration() {
        let signal = TradingSignal.buy
        XCTAssertEqual(signal.numericValue, 1.0, "Buy signal should have numeric value of 1.0")
        
        let strongSell = TradingSignal.strongSell
        XCTAssertEqual(strongSell.numericValue, -2.0, "Strong sell should have numeric value of -2.0")
    }
    
    func testTimeframeConversion() {
        let daily = Timeframe.daily
        XCTAssertEqual(daily.minutes, 1440, "Daily timeframe should be 1440 minutes")
        
        let fourHour = Timeframe.fourHour
        XCTAssertEqual(fourHour.minutes, 240, "4-hour timeframe should be 240 minutes")
    }
    
    // MARK: - Helper Methods for Test Data
    
    private func createTestCandleData() -> [CandleData] {
        var candles: [CandleData] = []
        let baseTime = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        
        for i in 0..<30 {
            let timestamp = baseTime.addingTimeInterval(Double(i) * 24 * 60 * 60)
            let basePrice = 100.0 + Double(i) // Ascending trend
            let volatility = Double.random(in: 0.95...1.05)
            
            let open = basePrice * volatility
            let close = basePrice * Double.random(in: 0.98...1.02)
            let high = max(open, close) * Double.random(in: 1.0...1.03)
            let low = min(open, close) * Double.random(in: 0.97...1.0)
            let volume = Double.random(in: 1000...10000)
            
            candles.append(CandleData(
                timestamp: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
        }
        
        return candles
    }
    
    private func createHeadAndShouldersPattern() -> [CandleData] {
        var candles: [CandleData] = []
        let baseTime = Date().addingTimeInterval(-20 * 24 * 60 * 60)
        
        // Create a head and shoulders pattern
        let prices: [Double] = [
            100, 105, 110, 108, 105, // Left shoulder
            110, 115, 120, 118, 115, // Head formation
            110, 108, 112, 110, 108, // Right shoulder
            105, 102, 100, 98, 95    // Breakdown
        ]
        
        for (i, price) in prices.enumerated() {
            let timestamp = baseTime.addingTimeInterval(Double(i) * 24 * 60 * 60)
            let volatility = Double.random(in: 0.98...1.02)
            
            let close = price * volatility
            let open = close * Double.random(in: 0.99...1.01)
            let high = max(open, close) * Double.random(in: 1.0...1.02)
            let low = min(open, close) * Double.random(in: 0.98...1.0)
            let volume = Double.random(in: 1000...5000)
            
            candles.append(CandleData(
                timestamp: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
        }
        
        return candles
    }
}
