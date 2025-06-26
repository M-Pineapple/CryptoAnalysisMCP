# GitHub Release Checklist

## Pre-Release Steps

- [ ] Build final release binary: `./build-release.sh`
- [ ] Test the release binary with Claude Desktop
- [ ] Update version number in code if needed
- [ ] Ensure all documentation is up to date
- [ ] Create release binary with proper naming: `crypto-analysis-mcp-v1.0.0-macos`

## GitHub Repository Settings

1. **About Section**:
   - Description: `Professional cryptocurrency technical analysis MCP for Claude Desktop. Real-time indicators, patterns & signals for 2,500+ coins. Built with Swift.`
   - Website: (leave blank or add your website)
   - Topics: `mcp`, `model-context-protocol`, `claude-desktop`, `cryptocurrency`, `technical-analysis`, `trading-signals`, `swift`, `macos`, `crypto-trading`, `coinpaprika`

2. **Create Release**:
   - Go to: https://github.com/M-Pineapple/CryptoAnalysisMCP/releases/new
   - Tag version: `v1.0.0`
   - Release title: `v1.0.0 - Initial Release 🚀`
   - Description: Copy content from `release-notes-v1.0.0.md`
   - Attach files:
     - The compiled binary (rename to `crypto-analysis-mcp-v1.0.0-macos`)
     - Optionally: A zip file with the binary and a quick-start guide
   - Check "Set as the latest release"
   - Publish release

## Post-Release Steps

- [ ] Update README with link to latest release
- [ ] Post on Reddit using the prepared draft
- [ ] Share in MCP community channels
- [ ] Monitor issues for user feedback

## Binary Preparation Commands

```bash
# Build release
./build-release.sh

# Copy and rename for release
cp .build/release/CryptoAnalysisMCP crypto-analysis-mcp-v1.0.0-macos

# Make it executable
chmod +x crypto-analysis-mcp-v1.0.0-macos

# Create zip for easy distribution (optional)
zip crypto-analysis-mcp-v1.0.0-macos.zip crypto-analysis-mcp-v1.0.0-macos
```

## Reddit Post

Use the draft at: `/Users/rogers/GitHub/CryptoAnalysisMCP/reddit-post-draft.md`

Primary subreddit: r/ClaudeAI
Secondary: r/cryptocurrency, r/swift, r/opensource