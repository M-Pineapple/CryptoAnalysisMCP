# CryptoAnalysisMCP

A Model Context Protocol (MCP) server for comprehensive cryptocurrency technical analysis. Built with Swift, it provides real-time price data, technical indicators, chart pattern detection, and trading signals for over 2,500 cryptocurrencies.

## Features

> 💡 **Not sure what to ask?** Check our [**Crypto Analysis Prompts Guide**](./PROMPTS.md) for inspiration!

- **Dynamic Symbol Resolution**: Automatically supports all 2,500+ cryptocurrencies on CoinPaprika
- **Real-time Price Data**: Current prices, volume, market cap, and percentage changes
- **Technical Indicators**: RSI, MACD, Moving Averages, Bollinger Bands, and more
- **Chart Pattern Detection**: Head & shoulders, triangles, double tops/bottoms
- **Support & Resistance Levels**: Automatic identification of key price levels  
- **Trading Signals**: Buy/sell/hold recommendations based on technical analysis
- **Multi-timeframe Analysis**: 4-hour, daily, weekly, and monthly timeframes
- **Risk-adjusted Strategies**: Conservative, moderate, and aggressive trading approaches

## 🚀 Coming Soon

We're actively working on exciting new features to make CryptoAnalysisMCP even more powerful:

### 🆕 Next Release (v1.1.0)
- **🌊 Elliott Wave Analysis**: Automated wave counting and prediction
- **🕯️ Advanced Candlestick Patterns**: Three Black Crows, Three White Soldiers, Marubozu, and more
- **📊 Portfolio Correlation Analysis**: Track how your holdings correlate with each other
- **🔔 Custom Alert Conditions**: Set personalized alerts based on technical indicators
- **📝 Trading Journal Integration**: Log and analyze your trades automatically
- **🔄 CoinMarketCap API Support**: Switch between CoinPaprika and CoinMarketCap APIs seamlessly

### 🔮 Future Enhancements
- **🦎 CoinGecko API Integration**: Add support for CoinGecko as a third data source
- **🤖 AI-Powered Predictions**: Machine learning models for price movement predictions
- **🌐 Social Sentiment Analysis**: Integrate Twitter/Reddit sentiment data
- **⛓️ On-chain Analytics**: DeFi metrics, whale movements, exchange flows
- **📡 WebSocket Support**: Real-time price and indicator updates
- **💱 Multi-exchange Support**: Aggregate data from multiple exchanges
- **📊 Custom Indicator Builder**: Create your own technical indicators

Want to suggest a feature? [Open an issue](https://github.com/M-Pineapple/CryptoAnalysisMCP/issues) on GitHub!

## ❓ Frequently Asked Questions

### Do I need a paid API key to use this MCP?

**Short answer**: You need a FREE API key for most features. Paid key for advanced timeframes.

**What works WITHOUT any API key:**
- ✅ Real-time price data (get_crypto_price)
- ✅ Market cap, volume, 24h changes
- ✅ Price percentage changes (15m, 30m, 1h, 6h, 12h, 24h, 7d, 30d, 1y)

**What requires a FREE CoinPaprika API key:**
- 🔑 Technical indicators (RSI, MACD, Bollinger Bands)
- 🔑 Chart pattern detection
- 🔑 Support & resistance levels
- 🔑 Trading signals
- 🔑 Multi-timeframe analysis

**How to get your FREE API key:**
1. Go to [CoinPaprika API](https://coinpaprika.com/api/)
2. Click "Start Free" 
3. Register for an account
4. Get your API key
5. Add to Claude Desktop config:
```json
{
  "mcpServers": {
    "crypto-analysis": {
      "command": "/path/to/crypto-analysis-mcp",
      "env": {
        "COINPAPRIKA_API_KEY": "your-free-api-key-here"
      }
    }
  }
}
```

The free tier includes:
- ✅ 25,000 API calls per month
- ✅ 1 year of daily historical data
- ✅ 2,500+ cryptocurrencies

**For advanced features**, upgrade to [CoinPaprika Pro](https://coinpaprika.com/api/):
- ❌ 4-hour and hourly timeframes (Pro required)
- ❌ Extended historical data beyond 1 year
- ❌ Higher rate limits
- ❌ Priority support

### Can I use CoinMarketCap or CoinGecko API instead?

**Currently**: Not directly - this MCP is specifically built for CoinPaprika's API structure.

**Coming in v1.1.0**: CoinMarketCap API support! 🎉

Key differences:
- **CoinMarketCap**: Different endpoint structure (support coming in v1.1.0!)
- **CoinGecko**: Different data format (planned for future release)
- **CoinPaprika**: Best coverage (71,000+ assets vs 10,000-20,000 for competitors)

We chose CoinPaprika first because:
- 3x more market coverage than competitors
- More generous free tier
- Better historical data access
- Superior API reliability (99.9% uptime)

Once v1.1.0 is released, you'll be able to switch between CoinPaprika and CoinMarketCap APIs with a simple configuration change!

### What cryptocurrencies are supported?

All 2,500+ cryptocurrencies available on CoinPaprika! This includes:
- Major coins (BTC, ETH, SOL, etc.)
- Meme coins (DOGE, SHIB, PEPE, etc.)
- DeFi tokens (UNI, AAVE, etc.)
- Layer 2 tokens (ARB, OP, MATIC, etc.)
- Any new listings on CoinPaprika

Just use the ticker symbol - the MCP handles the rest!

### Why am I getting 402 Payment Required errors?

This means you're trying to access paid features with a free API key:
- Using 4h or hourly timeframes (free tier only supports daily)
- Requesting data older than 1 year
- Exceeding rate limits

**Solution**: Either use daily timeframe or [upgrade to CoinPaprika Pro](https://coinpaprika.com/api/).

### How accurate are the trading signals?

⚠️ **Important**: Trading signals are for informational purposes only!

- Based on well-established technical indicators
- No prediction is 100% accurate
- Always do your own research
- Never invest more than you can afford to lose
- Consider multiple factors beyond technical analysis

### Can I use this for automated trading?

While technically possible, we **strongly advise caution**:
- This MCP provides analysis, not execution
- Requires additional safety mechanisms
- Needs proper risk management
- Should be thoroughly backtested
- Consider paper trading first

### How often does the data update?

Depends on your API tier:
- **Free tier**: ~1-5 minute delays
- **Pro tier**: 30-second updates for prices
- **Cached locally**: 1-5 minutes to reduce API calls

### Is my API key secure?

Yes! Your API key:
- Is never hardcoded
- Only read from environment variables
- Never logged or transmitted
- Only used for CoinPaprika API calls
- Follows security best practices

### Can I contribute to this project?

Absolutely! We welcome contributions:
- Bug fixes
- New indicators
- Performance improvements
- Documentation updates
- Feature suggestions

See our [Contributing](#contributing) section for guidelines.

### Where can I get help?

1. Check this FAQ first
2. Read the [documentation](https://github.com/M-Pineapple/CryptoAnalysisMCP)
3. Search [existing issues](https://github.com/M-Pineapple/CryptoAnalysisMCP/issues)
4. Open a new issue with details
5. Join our community discussions

### Why Swift instead of Python/JavaScript?

Swift offers:
- Native macOS performance
- Type safety and modern concurrency
- Excellent memory management
- Seamless Claude Desktop integration
- Growing ecosystem for server-side development

Plus, we love Swift! 🍍

## Prerequisites

- macOS 10.15 or later
- Swift 5.5 or later
- Xcode 13+ (for development)
- Claude Desktop

## Installation

### Prerequisites

1. **Get a FREE CoinPaprika API Key** (required for technical analysis):
   - Visit [CoinPaprika API](https://coinpaprika.com/api/)
   - Click "Start Free" and register
   - Copy your API key for step 3

### Quick Install

1. Clone the repository:
```bash
git clone https://github.com/M-Pineapple/CryptoAnalysisMCP.git
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
      "command": "/path/to/CryptoAnalysisMCP/crypto-analysis-mcp",
      "env": {
        "COINPAPRIKA_API_KEY": "your-free-api-key-here"
      }
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

### 📝 Example Prompts

**New to crypto analysis?** Check out our comprehensive [**Crypto Analysis Prompts Guide**](./PROMPTS.md) with 100+ example prompts for:
- 🏃 Day Trading
- 📊 Swing Trading
- 💼 Long-term Investing
- 📈 Technical Indicators
- 🎯 Risk Management
- And much more!

### Available Commands

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

## 💡 Quick Examples

Here are some natural language prompts you can use:

**1. Quick Analysis**
```
"Give me a quick technical analysis of [SYMBOL]"
"Is [SYMBOL] bullish or bearish right now?"
"What's the trend for [SYMBOL]?"
```

**2. Day Trading Focus**
```
"Analyze [SYMBOL] for day trading opportunities"
"Show me scalping levels for [SYMBOL] today"
"What are the intraday support and resistance for [SYMBOL]?"
```

**3. Swing Trading Analysis**
```
"Provide swing trading setup for [SYMBOL] with 3-7 day outlook"
"Analyze [SYMBOL] patterns on daily timeframe for swing trades"
"Give me entry, stop loss, and targets for swing trading [SYMBOL]"
```

**4. Full Institutional Analysis**
```
"Do a complete Wall Street analyst report on [SYMBOL]"
"Analyze [SYMBOL] like a hedge fund would"
"Give me all technical indicators, patterns, and signals for [SYMBOL]"
```

**5. Risk-Based Strategies**
```
"Show me conservative trading strategy for [SYMBOL]"
"What's the aggressive play on [SYMBOL]?"
"Give me risk-adjusted entries for [SYMBOL]"
```

**6. Specific Indicator Requests**
```
"What's the RSI and MACD saying about [SYMBOL]?"
"Check Bollinger Bands squeeze on [SYMBOL]"
"Are there any chart patterns forming on [SYMBOL]?"
```

💡 **Replace [SYMBOL] with any cryptocurrency ticker** (BTC, ETH, SOL, etc.)

👉 **See 100+ more examples in our [Crypto Analysis Prompts Guide](./PROMPTS.md)**

## Supported Cryptocurrencies

The MCP now supports **ALL cryptocurrencies** available on CoinPaprika through dynamic symbol resolution. Just use the ticker symbol (e.g., BTC, ETH, DOGE, SHIB, PEPE, etc.).

Common symbols are cached for performance, while any other symbol is dynamically resolved via the API.

## Configuration

### API Key (Required for Technical Analysis)

⚠️ **Important**: While real-time prices work without an API key, all technical analysis features require at least a FREE CoinPaprika API key.

#### Get your FREE API key:

1. Visit [CoinPaprika API](https://coinpaprika.com/api/)
2. Click "Start Free"
3. Create an account
4. Copy your API key

#### Add to Claude Desktop:

**Option 1 - Environment Variable (Recommended):**
```json
{
  "mcpServers": {
    "crypto-analysis": {
      "command": "/path/to/crypto-analysis-mcp",
      "env": {
        "COINPAPRIKA_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

**Option 2 - System Environment:**
```bash
export COINPAPRIKA_API_KEY="your-api-key-here"
```

### Free vs Paid Tiers

| Feature | No API Key | Free API Key | Pro API Key ($99/mo) |
|---------|------------|--------------|---------------------|
| Real-time prices | ✅ | ✅ | ✅ |
| Technical indicators | ❌ | ✅ Daily only | ✅ All timeframes |
| Chart patterns | ❌ | ✅ Daily only | ✅ All timeframes |
| Trading signals | ❌ | ✅ Daily only | ✅ All timeframes |
| Historical data | ❌ | ✅ 1 year | ✅ Full history |
| Timeframes | - | Daily only | 5m, 15m, 30m, 1h, 4h, daily, weekly |
| API calls/month | - | 25,000 | 500,000+ |

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
git clone https://github.com/M-Pineapple/CryptoAnalysisMCP.git
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

## 💖 Support This Project

If CryptoAnalysisMCP has helped enhance your crypto analysis workflow or saved you time with technical indicators, consider supporting its development:

<a href="https://www.buymeacoffee.com/mpineapple" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>

Your support helps me:
* Maintain and improve CryptoAnalysisMCP with new features
* Keep the project open-source and free for everyone
* Dedicate more time to addressing user requests and bug fixes
* Explore new indicators and analysis techniques

Thank you for considering supporting my work! 🙏

## Support

For issues, questions, or suggestions, please open an issue on GitHub.

---

Made with ❤️ by 🍍
