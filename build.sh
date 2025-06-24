#!/bin/bash

# CryptoAnalysisMCP Build and Test Script

echo "🚀 Building CryptoAnalysisMCP..."

# Navigate to project directory
cd "$(dirname "$0")"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
swift package clean

# Resolve dependencies
echo "📦 Resolving dependencies..."
swift package resolve

# Build the project
echo "🔨 Building project..."
swift build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Run tests
    echo "🧪 Running tests..."
    swift test
    
    if [ $? -eq 0 ]; then
        echo "✅ All tests passed!"
        echo ""
        echo "🎉 CryptoAnalysisMCP is ready to use!"
        echo ""
        echo "To run the MCP server:"
        echo "  swift run CryptoAnalysisMCP"
        echo ""
        echo "To open in Xcode:"
        echo "  open .swiftpm/xcode/package.xcworkspace"
    else
        echo "❌ Tests failed!"
        exit 1
    fi
else
    echo "❌ Build failed!"
    exit 1
fi
