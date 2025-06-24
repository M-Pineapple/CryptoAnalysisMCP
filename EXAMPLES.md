# CryptoAnalysisMCP Examples 📊

This file contains practical examples of how to use the CryptoAnalysisMCP server.

## Quick Start

### 1. Start the MCP Server
```bash
swift run CryptoAnalysisMCP
```

### 2. Connect from Claude Desktop

Add this to your Claude Desktop MCP configuration:

```json
{
  "mcpServers": {
    "crypto-analysis": {
      "command": "/path/to/CryptoAnalysisMCP/.build/release/CryptoAnalysisMCP",
      "args": [],
      "env": {}
    }
  }
}
```

## Example Queries for Claude

### Basic Price Check
> "What's the current price of Bitcoin?"

This will call `get_crypto_price` with symbol "BTC" and return current market data.

### Technical Analysis
> "Analyze Bitcoin's technical indicators on the daily timeframe"

This will call `get_technical_indicators` and return RSI, MACD, moving averages, etc.

### Pattern Recognition
> "Are there any chart patterns forming on Ethereum's daily chart?"

This will call `detect_chart_patterns` and identify formations like triangles, head & shoulders, etc.

### Trading Signals
> "Give me a trading signal for Bitcoin with moderate risk tolerance"

This will call `get_trading_signals` and provide entry/exit recommendations.

### Multi-Timeframe Analysis
> "Analyze Ethereum across all timeframes and give me the overall picture"

This will call `multi_timeframe_analysis` for comprehensive cross-timeframe view.

### Support & Resistance
> "Where are the key support and resistance levels for Solana?"

This will call `get_support_resistance` and identify critical price levels.

### Full Analysis
> "Give me a complete technical analysis of Cardano including everything"

This will call `get_full_analysis` for comprehensive report.

## Advanced Examples

### Specific Indicator Request
> "What's Bitcoin's RSI and MACD on the 4-hour timeframe?"

### Pattern-Specific Search
> "Look for any head and shoulders patterns on Ethereum's weekly chart"

### Risk-Adjusted Signals
> "Give me conservative trading signals for Bitcoin - I want high confidence entries only"

### Multi-Crypto Comparison
> "Compare the technical analysis of Bitcoin, Ethereum, and Cardano"

### Entry/Exit Strategy
> "Where should I enter Bitcoin if I want to buy, and what should my stop loss be?"

## Real-World Scenarios

### Scenario 1: Day Trading Setup
```
User: "I'm looking for a day trading setup on Bitcoin. Show me 4-hour patterns and current momentum."

Expected Response:
- 4-hour chart patterns
- RSI and MACD signals
- Support/resistance levels
- Entry recommendations with stops
```

### Scenario 2: Swing Trading Analysis
```
User: "I'm thinking of holding Ethereum for a few weeks. What does the daily analysis look like?"

Expected Response:
- Daily timeframe indicators
- Chart patterns with targets
- Multi-week support levels
- Risk-adjusted signals
```

### Scenario 3: Long-term Investment
```
User: "Should I add to my Solana position? Show me the weekly technical picture."

Expected Response:
- Weekly trend analysis
- Long-term support/resistance
- Pattern formations
- Investment-grade signals
```

### Scenario 4: Risk Management
```
User: "Bitcoin is approaching a key level. Where should I place my stop loss?"

Expected Response:
- Current support levels
- Stop loss recommendations
- Risk/reward ratios
- Level strength analysis
```

### Scenario 5: Market Overview
```
User: "Give me a quick technical overview of the top 5 cryptocurrencies."

Expected Response:
- Multi-crypto analysis
- Overall market sentiment
- Key levels to watch
- Relative strength comparison
```

## Sample Output Formats

### Price Data Response
```json
{
  "symbol": "BTC",
  "price": 109293.67,
  "change_24h": 3304.62,
  "change_percent_24h": 3.12,
  "volume_24h": 34888334155.28,
  "market_cap": 2172580030356,
  "rank": 1,
  "percent_changes": {
    "1h": 0.1,
    "6h": -0.38,
    "7d": 3.82,
    "30d": 4.58
  }
}
```

### Technical Indicators Response
```json
{
  "symbol": "BTC",
  "timeframe": "daily",
  "indicators": {
    "RSI_14": {
      "value": 67.5,
      "signal": "HOLD",
      "parameters": {"period": 14}
    },
    "MACD_12_26_9": {
      "value": 1250.45,
      "signal": "BUY",
      "parameters": {"histogram": 245.67}
    },
    "SMA_20": {
      "value": 107890.23,
      "signal": "BUY"
    }
  }
}
```

### Pattern Detection Response
```json
{
  "symbol": "ETH",
  "patterns": [
    {
      "type": "ASCENDING_TRIANGLE",
      "confidence": 0.85,
      "description": "Strong ascending triangle with 3 touches on resistance",
      "target_price": 2850.00,
      "stop_loss": 2450.00,
      "is_bullish": true
    }
  ]
}
```

### Trading Signals Response
```json
{
  "symbol": "BTC",
  "primary_signal": "BUY",
  "confidence": 0.75,
  "entry_price": 109293.67,
  "stop_loss": 107500.00,
  "take_profit": 112000.00,
  "reasoning": "RSI shows oversold conditions. Chart patterns detected: ASCENDING_TRIANGLE. Price near key support level at 107500.00"
}
```

## Tips for Best Results

### 1. Be Specific
- Specify the cryptocurrency symbol
- Mention the timeframe you're interested in
- State your risk tolerance if asking for signals

### 2. Use Context
- Mention if you're day trading, swing trading, or investing
- Provide your current position if relevant
- Ask about specific price levels you're watching

### 3. Ask Follow-up Questions
- "What if price breaks below that support level?"
- "How does this compare to last week's analysis?"
- "What are the key levels to watch for a breakout?"

### 4. Combine Analyses
- Ask for multiple timeframes
- Request both patterns and indicators
- Get both technical and risk analysis

## Troubleshooting

### Common Issues
1. **"No data available"** - The cryptocurrency symbol might not be supported
2. **"Insufficient data"** - Not enough historical data for the requested timeframe
3. **"Rate limit exceeded"** - Too many requests; wait a moment and try again

### Supported Symbols
Make sure to use standard symbols like:
- BTC (Bitcoin)
- ETH (Ethereum)  
- ADA (Cardano)
- SOL (Solana)
- DOT (Polkadot)
- LINK (Chainlink)
- MATIC (Polygon)
- AVAX (Avalanche)

### Best Practices
- Wait a few seconds between requests
- Use clear, specific cryptocurrency names
- Specify your timeframe preference
- Ask for clarification if results are unclear

---

**Happy Trading! 📈**

*Remember: This is for educational purposes only. Always do your own research and manage risk appropriately.*
