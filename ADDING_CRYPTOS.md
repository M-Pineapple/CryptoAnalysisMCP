# Adding More Cryptocurrencies

The CryptoAnalysisMCP now supports **ALL 2,500+ cryptocurrencies** available on CoinPaprika's free tier through dynamic symbol resolution!

## How It Works

The MCP automatically searches for any cryptocurrency symbol you provide:

1. **Common coins** (BTC, ETH, etc.) use cached mappings for speed
2. **Any other coin** is dynamically searched via the CoinPaprika API
3. Results are cached for future use

## Usage Examples

```
// These all work automatically:
get_crypto_price symbol: "XPRT"      // Persistence
get_crypto_price symbol: "PEPE"      // Pepe
get_crypto_price symbol: "WIF"       // dogwifhat
get_crypto_price symbol: "BONK"      // Bonk
```

## Manual Mapping (Optional)

For frequently used coins, you can still add them to the static mapping for better performance:

1. Edit `CryptoDataProvider.swift` and add to the `symbolMapping` dictionary:

```swift
private let symbolMapping: [String: String] = [
    "BTC": "btc-bitcoin",
    "ETH": "eth-ethereum",
    // ... existing mappings ...
    
    // Add frequently used coins here:
    "PEPE": "pepe-pepe",
    "WIF": "wif-dogwifhat",
    // etc.
]
```

2. Rebuild and restart Claude Desktop

## Popular Coins to Add

Here are some popular cryptocurrencies not yet in the MCP:

### Meme Coins
- PEPE: "pepe-pepe"
- WIF: "wif-dogwifhat"  
- BONK: "bonk-bonk"
- FLOKI: "floki-floki"

### Layer 2s
- STRK: "strk-starknet-token"
- MANTA: "manta-manta-network"
- BLAST: "blast-blast"

### DeFi
- MKR: "mkr-maker"
- CRV: "crv-curve-dao-token"
- COMP: "comp-compoumd-coin"
- SNX: "snx-synthetix"

### Gaming
- IMX: "imx-immutable-x"
- GALA: "gala-gala"
- AXS: "axs-axie-infinity"
- SAND: "sand-the-sandbox"

### AI Tokens
- FET: "fet-fetch-ai"
- AGIX: "agix-singularitynet"
- OCEAN: "ocean-ocean-protocol"
- RNDR: "rndr-render-token" (already included)

## Finding CoinPaprika IDs

You can also use the CoinPaprika API to search:

```bash
curl "https://api.coinpaprika.com/v1/search?q=bitcoin&limit=5"
```

This will return results with the exact IDs you need.

## Contribution

If you add support for more cryptocurrencies, please consider submitting a pull request to share with the community!
