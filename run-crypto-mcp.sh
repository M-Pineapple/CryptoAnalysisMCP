#!/bin/bash
# Wrapper script for CryptoAnalysisMCP

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Execute the binary with proper environment
exec "$DIR/.build/release/CryptoAnalysisMCP" "$@"
