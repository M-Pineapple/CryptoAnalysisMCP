// GoldenVectorTests.swift
//
// Regression vectors for the technical-indicator math. The expected values
// are captured from the actual implementation on 2026-05-07 (post-bundle
// quality fixes on `fix/quality-bundle-2026-05-07`) using a TA-Lib-style
// canonical input series. They are intentionally "current behavior" — the
// goal is to detect silent drift in SMA / EMA / RSI / MACD math, not to
// validate against an external oracle.
//
// If you intentionally change the math, re-capture the values via the
// `_capture_*` probe tests below (currently commented out).

import Testing
import Foundation
@testable import CryptoAnalysisMCP

@Suite("Golden Vectors")
struct GoldenVectorTests {

    // MARK: - Canonical input series

    /// 37 daily closes — the standard TA-Lib reference series used to
    /// document SMA / EMA / RSI / MACD behaviour.
    static let closes: [Double] = [
        22.27, 22.19, 22.08, 22.17, 22.18, 22.13, 22.23, 22.43, 22.24, 22.29,
        22.15, 22.39, 22.38, 22.61, 23.36, 24.05, 23.75, 23.83, 23.95, 23.63,
        23.82, 23.87, 23.65, 23.19, 23.10, 23.33, 22.68, 23.10, 22.40, 22.17,
        22.04, 22.20, 22.36, 22.52, 22.69, 22.85, 23.00,
    ]

    /// Build OHLC = close, volume = 0 candles starting at epoch 0 with a
    /// daily cadence. This yields deterministic timestamps so off-by-one
    /// indexing regressions are caught explicitly.
    static func candles() -> [CandleData] {
        let base = Date(timeIntervalSince1970: 0)
        return closes.enumerated().map { i, c in
            CandleData(
                timestamp: base.addingTimeInterval(Double(i) * 86_400),
                open: c, high: c, low: c, close: c, volume: 0
            )
        }
    }

    static let tolerance: Double = 1e-6

    // MARK: - Captured reference values
    //
    // Captured 2026-05-07 from the `fix/quality-bundle-2026-05-07` branch
    // implementation. To re-capture, uncomment the `_capture_*` tests
    // below, run `swift test --filter GoldenVectorTests`, and copy the
    // printed values back into these arrays.

    // SMA-10 result indices map to input indices [9, 10, ..., 36] (28 results).
    // Probe indices 0, 5, 10, 19, 27 (last).
    static let expectedSMA10: [(resultIdx: Int, value: Double)] = [
        (0,  22.220999999999997),
        (5,  22.421000000000003),
        (10, 23.209999999999997),
        (19, 23.276999999999997),
        (27, 22.533),
    ]

    // EMA-10 result indices map to input indices [9, 10, ..., 36] (28 results).
    static let expectedEMA10: [(resultIdx: Int, value: Double)] = [
        (0,  22.220999999999997),
        (5,  22.516355744453616),
        (10, 23.339801121099782),
        (19, 23.080560974929284),
        (27, 22.713456421295966),
    ]

    // RSI-14 result indices map to input indices [14, 15, ..., 36] (23 results).
    // Note: the implementation uses simple-average smoothing (not Wilder's),
    // so values differ from a textbook TA-Lib reference — these are the
    // canonical values for *this* implementation.
    static let expectedRSI14: [(resultIdx: Int, value: Double)] = [
        (0,  74.2222222222221),
        (5,  71.92982456140345),
        (10, 62.666666666666686),
        (15, 26.847290640394107),
        (22, 41.602067183462545),
    ]

    // MACD(12, 26, 9) — value is the MACD line. With 37 input bars,
    // macdLine has length 12 and signal smoothing yields 4 emitted
    // results. Result indices map to macdLine indices [8, 9, 10, 11],
    // i.e. input indices [33, 34, 35, 36].
    static let expectedMACD: [(resultIdx: Int, value: Double)] = [
        (0, -0.028645891689603076),
        (1, -0.022799988904118607),
        (2, -0.0051965039422263715),
        (3,  0.020620431614155166),
    ]

    // MARK: - Helpers (probe / re-capture)
    //
    // These are intentionally `@Test` but with leading-underscore names so
    // they don't run automatically (they currently don't print anything).
    // To re-capture, comment in the `print` lines and run with
    // `--filter GoldenVectorTests._capture`.

    // @Test func _captureSMA10() async {
    //     let analyzer = TechnicalAnalyzer()
    //     let r = await analyzer.calculateSMA(data: Self.candles(), period: 10)
    //     for (i, x) in r.enumerated() { print("SMA10[\(i)] = \(x.value)") }
    // }
    //
    // @Test func _captureEMA10() async {
    //     let analyzer = TechnicalAnalyzer()
    //     let r = await analyzer.calculateEMA(data: Self.candles(), period: 10)
    //     for (i, x) in r.enumerated() { print("EMA10[\(i)] = \(x.value)") }
    // }
    //
    // @Test func _captureRSI14() async {
    //     let analyzer = TechnicalAnalyzer()
    //     let r = await analyzer.calculateRSI(data: Self.candles(), period: 14)
    //     for (i, x) in r.enumerated() { print("RSI14[\(i)] = \(x.value)") }
    // }
    //
    // @Test func _captureMACD() async {
    //     let analyzer = TechnicalAnalyzer()
    //     let r = await analyzer.calculateMACD(
    //         data: Self.candles(), fastPeriod: 12, slowPeriod: 26, signalPeriod: 9
    //     )
    //     for (i, x) in r.enumerated() { print("MACD[\(i)] = \(x.value)") }
    // }

    // MARK: - Value regression tests

    @Test func sma10MatchesReference() async throws {
        let analyzer = TechnicalAnalyzer()
        let results = await analyzer.calculateSMA(data: Self.candles(), period: 10)
        try #require(results.count == Self.closes.count - 10 + 1)

        for (idx, expected) in Self.expectedSMA10 {
            let actual = results[idx].value
            #expect(
                abs(actual - expected) < Self.tolerance,
                "SMA10[\(idx)] expected \(expected), got \(actual)"
            )
        }
    }

    @Test func ema10MatchesReference() async throws {
        let analyzer = TechnicalAnalyzer()
        let results = await analyzer.calculateEMA(data: Self.candles(), period: 10)
        try #require(results.count == Self.closes.count - 10 + 1)

        for (idx, expected) in Self.expectedEMA10 {
            let actual = results[idx].value
            #expect(
                abs(actual - expected) < Self.tolerance,
                "EMA10[\(idx)] expected \(expected), got \(actual)"
            )
        }
    }

    @Test func rsi14MatchesReference() async throws {
        let analyzer = TechnicalAnalyzer()
        let results = await analyzer.calculateRSI(data: Self.candles(), period: 14)
        try #require(results.count == Self.closes.count - 14)

        for (idx, expected) in Self.expectedRSI14 {
            let actual = results[idx].value
            #expect(
                abs(actual - expected) < Self.tolerance,
                "RSI14[\(idx)] expected \(expected), got \(actual)"
            )
        }
    }

    @Test func macd12_26_9MatchesReference() async throws {
        let analyzer = TechnicalAnalyzer()
        let results = await analyzer.calculateMACD(
            data: Self.candles(),
            fastPeriod: 12, slowPeriod: 26, signalPeriod: 9
        )
        try #require(!results.isEmpty)

        for (idx, expected) in Self.expectedMACD {
            let actual = results[idx].value
            #expect(
                abs(actual - expected) < Self.tolerance,
                "MACD[\(idx)] expected \(expected), got \(actual)"
            )
        }
    }

    // MARK: - Timestamp regression tests
    //
    // These lock in the off-by-one fix: `result[i].timestamp` must equal the
    // closing-bar timestamp of the rolling window, i.e.
    // `input[i + period - 1].timestamp` (NOT `input[i + period]`).

    @Test func smaTimestampMatchesInputCandle() async throws {
        let candles = Self.candles()
        let analyzer = TechnicalAnalyzer()
        let period = 10
        let results = await analyzer.calculateSMA(data: candles, period: period)
        try #require(!results.isEmpty)

        for i in results.indices {
            let expected = candles[i + period - 1].timestamp
            #expect(
                results[i].timestamp == expected,
                "SMA[\(i)].timestamp expected \(expected), got \(results[i].timestamp)"
            )
        }
    }

    @Test func stochasticTimestampMatchesInputCandle() async throws {
        let candles = Self.candles()
        let analyzer = TechnicalAnalyzer()
        let kPeriod = 14
        let dPeriod = 3
        let results = await analyzer.calculateStochastic(
            data: candles, kPeriod: kPeriod, dPeriod: dPeriod
        )
        try #require(!results.isEmpty)

        // %K values are emitted starting at input index `kPeriod - 1`,
        // and %D smoothing drops the first `dPeriod - 1` of those, so
        // result `r` is anchored to the kValues index `r + dPeriod - 1`,
        // which itself is anchored to input index
        // `(r + dPeriod - 1) + (kPeriod - 1) = r + kPeriod + dPeriod - 2`.
        //
        // The bug we just fixed had the implementation indexing one bar
        // past that (e.g. `data[i + kPeriod]` where `i` is the kValues
        // index — the "+ 1" off-by-one). With 37 input bars, that bug
        // would overshoot `data.count` on the final result and crash. So
        // this test pins the corrected anchoring AND verifies no overrun.
        let expectedFirstIdx = kPeriod + dPeriod - 2          // 15
        let expectedLastIdx  = expectedFirstIdx + results.count - 1
        try #require(expectedLastIdx == candles.count - 1,
                     "Stochastic should emit results aligned through the last input bar")

        for r in results.indices {
            let expectedIdx = r + kPeriod + dPeriod - 2
            try #require(expectedIdx < candles.count)
            #expect(
                results[r].timestamp == candles[expectedIdx].timestamp,
                "Stochastic[\(r)].timestamp expected candles[\(expectedIdx)] = \(candles[expectedIdx].timestamp), got \(results[r].timestamp)"
            )
        }
    }

    @Test func macdTimestampMatchesInputCandle() async throws {
        let candles = Self.candles()
        let analyzer = TechnicalAnalyzer()
        let fast = 12
        let slow = 26
        let signal = 9
        let results = await analyzer.calculateMACD(
            data: candles, fastPeriod: fast, slowPeriod: slow, signalPeriod: signal
        )
        try #require(!results.isEmpty)

        // The MACD line is built from the slow EMA window (length
        // candles.count - slow + 1). The signal smoothing then drops the
        // first (signal - 1) entries, so result index `r` corresponds to
        // macdLine index `r + signal - 1`, which is anchored to input
        // index `(r + signal - 1) + slow - 1 = r + signal + slow - 2`.
        // This catches off-by-one regressions in the bar-time alignment.
        for r in results.indices {
            let expectedIdx = r + signal + slow - 2
            try #require(expectedIdx < candles.count)
            #expect(
                results[r].timestamp == candles[expectedIdx].timestamp,
                "MACD[\(r)].timestamp expected candles[\(expectedIdx)] = \(candles[expectedIdx].timestamp), got \(results[r].timestamp)"
            )
        }
    }
}
