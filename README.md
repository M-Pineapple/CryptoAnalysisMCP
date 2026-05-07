<div align="center">
  <img src="https://github.com/user-attachments/assets/5d1aae51-4183-4cd5-a79c-163fc1e8c918">
</div>

# CryptoAnalysisMCP v1.3 🚀

**Supports 7+ MILLION tokens through DexPaprika integration!** 🎉

A Model Context Protocol (MCP) server for comprehensive cryptocurrency technical analysis. Built with Swift, it provides real-time price data, technical indicators, chart pattern detection, and trading signals for over 7 million cryptocurrencies - from Bitcoin to the newest meme coin on any DEX!

⚠️ **IMPORTANT FOR DAY TRADERS**: This tool requires a $99/mo Pro subscription for intraday analysis. The free tier only supports daily candles, making it suitable for swing traders and long-term investors only.

## ⚠️ Disclaimer

CryptoAnalysisMCP is provided **for informational and educational purposes only**. It is **not** financial, investment, trading, or tax advice, and nothing it outputs should be treated as a recommendation to buy, sell, or hold any asset.

- Technical indicators, chart patterns, and trading signals are computed from public market data using well-known formulas. They are imperfect, can be wrong, and offer no predictive guarantee.
- Cryptocurrency markets are highly volatile. You can lose your entire investment — and more than you put in if you use leverage or margin. Never trade with money you cannot afford to lose.
- Past performance — including any examples, backtests, or sample outputs in this repository — does not predict future returns.
- The author and contributors are not licensed financial advisors. This project is not affiliated with, endorsed by, or operated by any exchange, broker, regulator, or data provider.
- Always do your own research (DYOR), consult a qualified financial professional about your specific situation, and verify any data this tool produces against an authoritative source before acting on it.
- The software is provided "as is", without warranty of any kind, per the [MIT License](LICENSE). The author and contributors are not liable for any losses, damages, or consequences arising from your use of this tool.

**By using CryptoAnalysisMCP you acknowledge and accept these terms.** See [DISCLAIMER.md](DISCLAIMER.md) for the full text.

## 🆕 What's New in v1.3

### 🔄 Default SDK Transport
- Moved from in-tree `SimpleMCP` to official `mcp-swift-sdk` v0.12.1 as the default transport
- Legacy `SimpleMCP` available via `--use-legacy` flag (one-release safety valve; removed in v1.4)
- Both transports expose the same 16 tools with identical schemas

### ⚙️ Swift 6.1 Toolchain
- Full strict concurrency compliance with zero warnings
- Modern async/await patterns throughout
- Enhanced type safety and memory management

### 📦 v1.2 Quality Bundle
- `DataProvider` protocol for pluggable data sources (CoinPaprika primary, DexPaprika fallback)
- Fixed mathematical precision in all technical indicators (RSI, MACD, OBV, Williams %R, Bollinger Bands)
- 2,989+ integration and golden-vector tests ensure indicator accuracy

🐦 **Follow [@m_pineapple__](https://x.com/m_pineapple__) for updates!**

## Features

> 💡 **Not sure what to ask?** Check our [**Crypto Analysis Prompts Guide**](./PROMPTS.md) for inspiration!

- **Universal Token Support**: 7+ MILLION tokens through DexPaprika integration
- **Liquidity Pool Analytics**: Monitor liquidity, volume, and pool data across DEXes
- **Dynamic Symbol Resolution**: Automatically supports all cryptocurrencies
- **Real-time Price Data**: Current prices, volume, market cap, and percentage changes
- **Technical Indicators**: RSI, MACD, Moving Averages, Bollinger Bands, and more
- **Chart Pattern Detection**: Head & shoulders, triangles, double tops/bottoms
- **Support & Resistance Levels**: Automatic identification of key price levels  
- **Trading Signals**: Buy/sell/hold recommendations based on technical analysis
- **Multi-timeframe Analysis**: 4-hour, daily, weekly, and monthly timeframes
- **Risk-adjusted Signal Filtering**: Conservative, moderate, and aggressive thresholds for signal confidence

## 🗺️ Roadmap

### v1.4 (Planned)
- Remove legacy `SimpleMCP` transport (SDK becomes mandatory)

Want to suggest a feature? [Open an issue](https://github.com/M-Pineapple/CryptoAnalysisMCP/issues) on GitHub!

## ❓ Frequently Asked Questions

### Do I need a paid API key to use this MCP?

**Short answer**: Depends on your trading style.

⚠️ **IMPORTANT**: Day traders and scalpers NEED a Pro subscription ($99/mo). The free tier only provides daily candles, which is useless for intraday trading.

**What works WITHOUT any API key:**
- ✅ Real-time price data (with slight delays)
- ✅ Swing trading analysis (3-7 day trades)
- ✅ Position trading (weeks to months)
- ✅ Long-term investment analysis
- ✅ All technical indicators on DAILY timeframe
- ✅ 1 year of daily historical data
- Basic price data for 7+ MILLION tokens via DexPaprika
- Liquidity pool data across all major DEXes
- DEX price comparison and aggregation

**What REQUIRES a Pro API key ($99/mo):**
- ❌ Day trading (you need hourly/4h data)
- ❌ Scalping (you need minute data)
- ❌ Intraday patterns and signals
- ❌ Real-time/low-latency updates
- ❌ Historical data beyond 1 year
- ❌ Any timeframe shorter than daily

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

**Currently**: Not implemented. CryptoAnalysisMCP uses CoinPaprika as the primary data provider.

**How to add support**: As of v1.2.0, the `DataProvider` protocol makes it straightforward to add alternative data sources. If you're interested in CoinMarketCap or CoinGecko integration, contributions are welcome! Open an issue to discuss or submit a PR.

Why CoinPaprika first:
- 3x more market coverage than competitors (71,000+ assets)
- More generous free tier (25,000 API calls/month)
- Better historical data access
- Superior API reliability (99.9% uptime)

### What cryptocurrencies are supported?

The MCP supports **7+ MILLION tokens** via DexPaprika integration:
- ✅ **All 2,500+ CoinPaprika tokens** (major coins with full analysis)
- ✅ **7+ MILLION DEX tokens** via DexPaprika (automatic fallback)
- ✅ **Every token on every DEX** across 23+ blockchains
- ✅ **Brand new tokens** - analyze tokens minutes after launch
- ✅ **Obscure meme coins** - if it trades on a DEX, we have it
- ✅ **NO API KEY NEEDED** for basic price data

Examples:
- Major coins: BTC, ETH, SOL (full technical analysis via CoinPaprika)
- Popular memes: DOGE, SHIB, PEPE, WOJAK (price data from any source)
- New launches: That token that launched 5 minutes ago on Uniswap
- Any ERC-20, BEP-20, SPL token, or token on any supported chain

Just use the ticker symbol - the MCP automatically finds it!

### Why am I getting 402 Payment Required errors?

You're trying to use features that require a Pro subscription:

**Common causes:**
- Using any timeframe other than 'daily' (4h, 1h, 15m, etc.)
- Requesting data older than 1 year
- Exceeding rate limits (rare)

**Solutions:**
1. **For swing trading/investing**: Just use 'daily' timeframe - it's free!
2. **For day trading**: You MUST [upgrade to CoinPaprika Pro](https://coinpaprika.com/api/) ($99/mo)

**There is NO free option for day trading**. If you need intraday data, you need to pay.

### How accurate are the trading signals?

Trading signals are for informational purposes only — see the [Disclaimer](#%EF%B8%8F-disclaimer) at the top of this README and the full [DISCLAIMER.md](DISCLAIMER.md). They are based on well-established technical indicators but no prediction is 100% accurate. Always do your own research and never invest more than you can afford to lose.

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

1. **Get a FREE CoinPaprika API Key** (optional but recommended for technical analysis):
   - Visit [CoinPaprika API](https://coinpaprika.com/api/)
   - Click "Start Free" and register
   - Copy your API key for step 3
   - Note: Basic price data works without API key via DexPaprika!

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

> As of v1.3.0 the server runs on the official [`mcp-swift-sdk`](https://github.com/modelcontextprotocol/swift-sdk) transport by default. To opt back into the legacy `SimpleMCP` transport (one-release safety valve, removed in v1.4), pass `"args": ["--use-legacy"]` in the config above.

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

### Liquidity & DEX Commands

### Get Token Liquidity
```
crypto-analysis:get_token_liquidity
  symbol: "PEPE"
  network: "ethereum" (optional)
```

### Search Tokens by Network
```
crypto-analysis:search_tokens_by_network
  network: "solana"
  query: "meme" (optional)
  limit: 20
```

### Compare DEX Prices
```
crypto-analysis:compare_dex_prices
  symbol: "SHIB"
  network: "ethereum"
```

### Get Network Pools
```
crypto-analysis:get_network_pools
  network: "ethereum"
  sort_by: "volume_usd"
  limit: 10
```

### Get Available Networks
```
crypto-analysis:get_available_networks
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

**7. Meme Coin & DEX Token Analysis**
```
"What's the price of WOJAK?"
"Analyze that new PEPE fork on Ethereum"
"Show me price data for [obscure token]"
"Track this Uniswap token: [contract address]"
```

**8. Liquidity & DEX Analytics**
```
"What's the liquidity for SHIB across all DEXes?"
"Show me the top pools on Solana"
"Compare PEPE prices on different DEXes"
"Find high liquidity meme coins on BSC"
"Which DEX has the best price for ETH?"
"Show me all tokens on Arbitrum with >$1M liquidity"
```

💡 **Replace [SYMBOL] with any cryptocurrency ticker** (BTC, ETH, SOL, etc.)

👉 **See 100+ more examples in our [Crypto Analysis Prompts Guide](./PROMPTS.md)**

## Supported Cryptocurrencies

The MCP supports **7+ MILLION tokens** through our dual-provider system:

1. **CoinPaprika** (Primary): 2,500+ major cryptocurrencies with full technical analysis
2. **DexPaprika** (Fallback): 7+ million DEX tokens across 23+ blockchains - NO API KEY REQUIRED!

The MCP automatically:
- Checks CoinPaprika first for established tokens (better data, more features)
- Falls back to DexPaprika for any token not found
- Caches results for optimal performance
- Works with just the ticker symbol

**Supported Networks via DexPaprika**:
- Ethereum, BSC, Polygon, Arbitrum, Optimism, Base
- Solana, Avalanche, Fantom, Aptos, Sui
- And 12+ more chains!

Just use any ticker symbol - if it exists on any DEX, we'll find it!

## Configuration

### API Key (Optional but Recommended)

⚠️ **Important**: 
- Basic price data works WITHOUT API key via DexPaprika
- Technical analysis features still require a FREE CoinPaprika API key

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

### Transport

CryptoAnalysisMCP v1.3+ runs on the official `mcp-swift-sdk` (v0.12.1) by default.
A legacy in-tree `SimpleMCP` transport is retained for one release as an opt-out:

- **Default (recommended):** no flag needed.
- **Opt out:** add `"args": ["--use-legacy"]` to your Claude Desktop config.
- **`--use-sdk`:** accepted as a no-op for v1.2.x backward compatibility; emits a one-time deprecation warning to stderr. Will be removed in v1.4.

Both transports expose the same 16 tools with the same input schemas (verified by an integration test on every build). Wire-format differences:

- The SDK serializes JSON with sorted keys.
- The SDK emits `"description": null` for tools without a description; the legacy path omits the key.

Neither difference is semantically meaningful, but anyone diffing their JSON-RPC traffic across versions should be aware.

## Trading Style Compatibility

![image](https://github.com/user-attachments/assets/10a83419-dec3-43b8-95cc-31be3f01ee41)


**Bottom Line**: If you're a day trader, you MUST get the Pro subscription. There's no workaround.

### Free vs Paid Tiers

![image](https://github.com/user-attachments/assets/841f123f-5ec6-4c93-a336-8b6b183852b2)


## Timeframes

**Free Tier (No API Key):**
- `daily` - Daily candles only ✅

**Pro Tier ($99/mo) - All timeframes:**
- `5m` - 5-minute candles
- `15m` - 15-minute candles
- `30m` - 30-minute candles
- `1h` - 1-hour candles
- `4h` - 4-hour candles
- `daily` - Daily candles
- `weekly` - Weekly candles

💡 **Note**: Attempting to use any timeframe other than 'daily' without a Pro key will result in an error.

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
│       ├── Main.swift                    # Entry point
│       ├── SimpleMCP.swift               # MCP protocol implementation
│       ├── CryptoDataProvider.swift      # CoinPaprika API integration
│       ├── DexPaprikaDataProvider.swift  # 🆕 DexPaprika integration
│       ├── TechnicalAnalyzer.swift       # Indicators & calculations
│       ├── ChartPatternRecognizer.swift  # Pattern detection
│       ├── SupportResistanceAnalyzer.swift # Support/resistance levels
│       ├── AnalysisFormatters.swift      # Output formatting
│       └── Models.swift                  # Data models
├── Tests/                                # Unit tests
├── Package.swift                         # Swift package manifest
└── README.md                             # This file
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
- 🆕 Enhanced with DexPaprika for 7+ million DEX tokens
- Technical analysis algorithms based on industry standards
- Special thanks to the CoinPaprika team for their support!

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

## Connect

Follow me for updates and crypto analysis insights:
- 🐦 Twitter/X: [@m_pineapple__](https://x.com/m_pineapple__)
- 🐙 GitHub: [@M-Pineapple](https://github.com/M-Pineapple)

---

Made with ❤️ by 🍍
