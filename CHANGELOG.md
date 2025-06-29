# Changelog

All notable changes to CryptoAnalysisMCP will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
