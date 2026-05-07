# Changelog

All notable changes to CryptoAnalysisMCP will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-05-07

### Changed (Default behavior)
- **Default transport is now the official `mcp-swift-sdk` (v0.12.1).** v1.2.1 made it opt-in via `--use-sdk`; v1.3 promotes it to the default.
- **Wire-format note:** the SDK serializes JSON with sorted keys and emits `"description": null` for tools without a description (the legacy path omitted the key). Both behaviors are semantically valid JSON-RPC 2.0; downstream consumers diffing raw JSON-RPC traffic should expect this shape change.

### Added
- **`--use-legacy` flag** opting back into the in-tree `SimpleMCP` transport. One-release safety valve so users with SDK-specific issues have a workaround. SimpleMCP is removed in v1.4.
- **Schema-parity integration test.** `StdioIntegrationTests.schemaParityAcrossTransports` spawns the binary against both transports, parses `tools/list`, and asserts byte-equivalent canonicalized `inputSchema` for every tool. Catches drift from forgetting to wire a new tool through one path.

### Deprecated
- **`--use-sdk` flag is a no-op as of v1.3.** Accepted for backward compatibility with v1.2.x configs; emits a one-time stderr deprecation warning. Removed in v1.4.

### Deferred to v1.4
- **`SimpleMCP` removal.** Retained for one release of real-world v1.3 SDK-default usage as a safety margin.

## [1.2.1] - 2026-05-07

### Added
- **`--use-sdk` flag** opting into the official `mcp-swift-sdk` (v0.12.1) transport. Default behavior remains the in-tree `SimpleMCP` for compatibility — the SDK becomes default in v1.3 after wider testing. Both paths serve the same 16 tools through a shared `ToolRegistrar` protocol.
- `MCPSDKBridge` final class wraps the SDK's `Server` and reuses the existing `MCPTool` registration surface. Translates `[String: Any]` schemas and arguments to/from the SDK's `Value` enum at the boundary, so the SDK handler closures only capture Sendable storage.

### Changed
- Bumped Swift toolchain to 6.1 (required by `mcp-swift-sdk`). All strict-concurrency diagnostics resolved without `@unchecked Sendable` escape hatches.
- `registerTools` / `registerDexPaprikaTools` now accept `any ToolRegistrar` (instead of `MCPServer` directly) so both backends share registration call sites.

### Note
- Existing default (`SimpleMCP`) path is unchanged. Both transports speak valid JSON-RPC 2.0 with the same tool name/schema set; minor wire formatting differs (the SDK uses `[.sortedKeys, .withoutEscapingSlashes]` and emits `description: null` for tools without one — semantically equivalent).

## [1.2.0] - 2026-05-07

### Fixed (Breaking)
- **Stochastic and MACD indicator timestamps off-by-one.** Both indicators were stamping each result with the timestamp of the candle one bar after the bar the value was computed from. Anyone joining indicator output to candle data by timestamp will see a one-bar shift. The new timestamps are correct.
- **Paid-tier CoinPaprika auth path.** Switched to `api-pro.coinpaprika.com` base URL with `Authorization` header instead of `?apikey=` query parameter against the free host. Fixes silent failures on paid plans. Thanks to [@donbagger](https://github.com/donbagger) for the report and patch (#3).
- **Removed imperative DEX fallback inside `CryptoDataProvider`.** Fallback chain is now declarative via `FallbackDataProvider`. `CryptoDataProvider.getCurrentPrice` no longer transparently retries on DexPaprika; that logic lives one level up. Behavior for end users via the MCP handler is unchanged (the handler wraps both providers in a `FallbackDataProvider`), but anyone instantiating `CryptoDataProvider` directly will now see CoinPaprika errors propagate instead of silent DEX retries.

### Fixed
- Divide-by-zero guard added to `findVolumeProfileLevels` and similar variation calculations — flat-market input no longer produces NaN propagating into trading signals.
- Replaced ~43 force-unwraps in `ChartPatternRecognizer` and `SupportResistanceAnalyzer` with safe guarded unwraps; degenerate input now returns empty results instead of crashing.
- Test target now compiles — added missing `await` on actor-isolated `calculateSMA` / `calculateRSI` calls.
- `testSupportResistanceAnalysis` flake fixed — replaced `Double.random` in fixture helpers with a deterministic seeded LCG. 5x consecutive runs now produce identical output.

### Added
- **`DataProvider` protocol** abstracts the cross-provider surface (`getCurrentPrice`, `getHistoricalData`, `providerName`). Both `CryptoDataProvider` and `DexPaprikaDataProvider` conform.
- **`FallbackDataProvider`** wraps an ordered list of providers and falls through on error. The handler now uses this to compose CoinPaprika → DexPaprika instead of the imperative fallback that lived inside `CryptoDataProvider`.
- Golden-vector regression tests for SMA, EMA, RSI, MACD against a canonical 37-bar reference series (Swift Testing).
- Timestamp regression tests verifying SMA, Stochastic, MACD, RSI, OBV, Williams %R, and Bollinger Bands results carry the correct candle timestamp (catches off-by-one regressions).
- URLProtocol-mocked auth-path tests verifying free-tier vs paid-tier CoinPaprika request construction (Swift Testing).
- README disclaimer section + dedicated `DISCLAIMER.md` clarifying that this tool is for informational/educational use only, not financial advice.

### Changed
- Pattern-recognition confidence constants centralized into a private `PatternConfidence` namespace in `ChartPatternRecognizer.swift` with documentation that they are heuristics, not empirically calibrated values. Confidence calculations in head-and-shoulders / double-top / double-bottom helpers now have explicit lower-bound clamps (previously only upper-bound).

### Deferred to v1.3
- **`mcp-swift-sdk` migration.** The official MCP Swift SDK (v0.12.1) requires Swift tools-version 6.1 (project is on 5.9), is pre-1.0 with API still churning, and pulls `swift-nio` + `eventsource` as transitive dependencies. Migration is a v1.3 release in its own right; deferred to keep v1.2.0 coherent.

## [1.1.0] - 2025-06-27

### Added
- 🔥 **DexPaprika Integration**: Real-time DEX analytics across 23+ blockchain networks
- **Token Liquidity Analysis**: Check liquidity pools across all DEXes
- **DEX Price Comparison**: Compare token prices across different exchanges
- **Pool Analytics**: Detailed metrics for specific liquidity pools
- **Network Overview**: Get top pools and DEX information by network
- **Advanced Token Search**: Filter by liquidity, volume, and network
- **OHLCV Data**: Historical candlestick data for liquidity pools

### Fixed
- Access control issues for clean builds
- Made logger internal for extension access
- Fixed all dataProvider references to use proper accessors
- Removed disabled files from source directory

### Changed
- Updated README with comprehensive v1.1 feature documentation
- Enhanced error handling for DEX API responses
- Improved build process for fresh installations

## [1.0.0] - 2025-06-01

### Added
- Initial release with core cryptocurrency analysis features
- Real-time price data for 2,500+ cryptocurrencies
- Technical indicators (RSI, MACD, Moving Averages, Bollinger Bands)
- Chart pattern detection (Head & Shoulders, Triangles, Double Tops/Bottoms)
- Support & Resistance level identification
- Trading signals with risk management
- Multi-timeframe analysis
- CoinPaprika API integration
