# CryptoAnalysisMCP

A Model Context Protocol (MCP) server for comprehensive cryptocurrency technical analysis. Built with Swift, it provides real-time price data, technical indicators, chart pattern detection, and trading signals for over 2,500 cryptocurrencies.

## Features

- **Dynamic Symbol Resolution**: Automatically supports all 2,500+ cryptocurrencies on CoinPaprika
- **Real-time Price Data**: Current prices, volume, market cap, and percentage changes
- **Technical Indicators**: RSI, MACD, Moving Averages, Bollinger Bands, and more
- **Chart Pattern Detection**: Head & shoulders, triangles, double tops/bottoms
- **Support & Resistance Levels**: Automatic identification of key price levels  
- **Trading Signals**: Buy/sell/hold recommendations based on technical analysis
- **Multi-timeframe Analysis**: 4-hour, daily, weekly, and monthly timeframes
- **Risk-adjusted Strategies**: Conservative, moderate, and aggressive trading approaches

## Prerequisites

- macOS 10.15 or later
- Swift 5.5 or later
- Xcode 13+ (for development)
- Claude Desktop

## Installation

### Quick Install

1. Clone the repository:
```bash
git clone https://github.com/[your-username]/CryptoAnalysisMCP.git
cd CryptoAnalysisMCP
```

2. Build the project:
```bash
./build-release.sh
```

3. Configure Claude Desktop by adding to `~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "crypto-analysis": {
      "command": "/path/to/CryptoAnalysisMCP/crypto-analysis-mcp"
    }
  }
}
```

4. Restart Claude Desktop

### Global Installation (Optional)

```bash
sudo cp ./.build/release/CryptoAnalysisMCP /usr/local/bin/crypto-analysis-mcp
```

Then use this in Claude Desktop config:
```json
{
  "mcpServers": {
    "crypto-analysis": {
      "command": "/usr/local/bin/crypto-analysis-mcp"
    }
  }
}
```

## Usage

Once configured, you can use these commands in Claude:

### Get Current Price
```
crypto-analysis:get_crypto_price
  symbol: "BTC"
```

### Technical Indicators
```
crypto-analysis:get_technical_indicators
  symbol: "ETH"
  timeframe: "daily"
```

### Chart Pattern Detection
```
crypto-analysis:detect_chart_patterns
  symbol: "SOL"
  timeframe: "4h"
```

### Trading Signals
```
crypto-analysis:get_trading_signals
  symbol: "ADA"
  risk_level: "moderate"
  timeframe: "daily"
```

### Full Analysis
```
crypto-analysis:get_full_analysis
  symbol: "DOT"
  timeframe: "weekly"
  risk_level: "aggressive"
```

### Support & Resistance
```
crypto-analysis:get_support_resistance
  symbol: "MATIC"
  timeframe: "daily"
```

### Multi-timeframe Analysis
```
crypto-analysis:multi_timeframe_analysis
  symbol: "AVAX"
```

## Supported Cryptocurrencies

The MCP now supports **ALL cryptocurrencies** available on CoinPaprika through dynamic symbol resolution. Just use the ticker symbol (e.g., BTC, ETH, DOGE, SHIB, PEPE, etc.).

Common symbols are cached for performance, while any other symbol is dynamically resolved via the API.

## Configuration

### API Key (Optional)

For higher rate limits and access to premium features, you can add a CoinPaprika API key:

1. Set environment variable:
```bash
export COINPAPRIKA_API_KEY="your-api-key"
```

2. Or add to Claude Desktop config:
```json
{
  "mcpServers": {
    "crypto-analysis": {
      "command": "/path/to/crypto-analysis-mcp",
      "env": {
        "COINPAPRIKA_API_KEY": "your-api-key"
      }
    }
  }
}
```

## Timeframes

- `4h` - 4-hour candles
- `daily` - Daily candles (default)
- `weekly` - Weekly candles
- `monthly` - Monthly candles

## Risk Levels

- `conservative` - Lower risk, focus on strong signals
- `moderate` - Balanced approach (default)
- `aggressive` - Higher risk, more sensitive signals

## Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/[your-username]/CryptoAnalysisMCP.git
cd CryptoAnalysisMCP

# Build debug version
swift build

# Build release version
swift build -c release

# Run tests
swift test
```

### Project Structure

```
CryptoAnalysisMCP/
├── Sources/
│   └── CryptoAnalysisMCP/
│       ├── Main.swift              # Entry point
│       ├── MCPServer.swift         # MCP protocol implementation
│       ├── CryptoDataProvider.swift # API integration & caching
│       ├── TechnicalAnalysis.swift # Indicators & calculations
│       ├── ChartPatterns.swift     # Pattern detection
│       ├── TradingSignals.swift    # Signal generation
│       └── Models/                 # Data models
├── Tests/                          # Unit tests
├── Package.swift                   # Swift package manifest
└── README.md                       # This file
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with Swift and the Model Context Protocol
- Powered by CoinPaprika API for cryptocurrency data
- Technical analysis algorithms based on industry standards

## Troubleshooting

### MCP not appearing in Claude

1. Ensure the path in `claude_desktop_config.json` is absolute
2. Check that the binary has execute permissions: `chmod +x crypto-analysis-mcp`
3. Restart Claude Desktop after configuration changes

### API Rate Limits

The free tier of CoinPaprika has rate limits. If you encounter 402 errors, consider:
- Using daily timeframe (most compatible with free tier)
- Adding an API key for higher limits
- Implementing request throttling

### Build Issues

If you encounter build errors:
1. Ensure Swift 5.5+ is installed: `swift --version`
2. Clean the build: `swift package clean`
3. Update dependencies: `swift package update`

## Support

For issues, questions, or suggestions, please open an issue on GitHub.

---

Made with ❤️ by 🍍
