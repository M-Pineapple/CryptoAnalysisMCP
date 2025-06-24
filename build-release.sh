#!/bin/bash

# CryptoAnalysisMCP Build Script

echo "🚀 Building CryptoAnalysisMCP..."

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
swift package clean

# Build in release mode
echo "🔨 Building in release mode..."
swift build -c release

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Create a convenient symlink
    echo "🔗 Creating symlink..."
    ln -sf .build/release/CryptoAnalysisMCP crypto-analysis-mcp
    
    echo ""
    echo "🎉 CryptoAnalysisMCP is ready to use!"
    echo ""
    echo "To run the MCP server:"
    echo "  ./crypto-analysis-mcp"
    echo ""
    echo "To install globally (optional):"
    echo "  sudo cp ./.build/release/CryptoAnalysisMCP /usr/local/bin/crypto-analysis-mcp"
    echo ""
    echo "For Claude Desktop configuration, see README.md"
else
    echo "❌ Build failed!"
    exit 1
fi
