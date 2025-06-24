#!/bin/bash

echo "CryptoAnalysisMCP Configuration Checker"
echo "======================================"
echo ""

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if binary exists in local build
if [ -f "$DIR/.build/release/CryptoAnalysisMCP" ]; then
    echo "✅ Binary found at: $DIR/.build/release/CryptoAnalysisMCP"
    echo "   Size: $(ls -lh $DIR/.build/release/CryptoAnalysisMCP | awk '{print $5}')"
else
    echo "❌ Binary NOT found in .build/release/"
    echo "   Run ./build-release.sh first"
fi

# Check if binary exists in /usr/local/bin
if [ -f "/usr/local/bin/crypto-analysis-mcp" ]; then
    echo "✅ Global binary found at: /usr/local/bin/crypto-analysis-mcp"
fi

echo ""
echo "Claude Desktop Configuration"
echo "============================"
echo ""
echo "Add one of these to your ~/Library/Application Support/Claude/claude_desktop_config.json:"
echo ""
echo "Option 1 - Local installation:"
echo '{'
echo '  "mcpServers": {'
echo '    "crypto-analysis": {'
echo '      "command": "'$DIR'/crypto-analysis-mcp"'
echo '    }'
echo '  }'
echo '}'
echo ""
echo "Option 2 - Global installation:"
echo '{'
echo '  "mcpServers": {'
echo '    "crypto-analysis": {'
echo '      "command": "/usr/local/bin/crypto-analysis-mcp"'
echo '    }'
echo '  }'
echo '}'
echo ""
echo "After updating config:"
echo "1. Save the file"
echo "2. Restart Claude Desktop completely"
echo "3. The crypto-analysis MCP should appear in available tools"
