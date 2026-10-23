# Linux image for hosts that build and run this stdio MCP server in a container (for example Glama).
# The process starts with no arguments and needs no network or credentials.
FROM swift:6.1-jammy

WORKDIR /app
COPY . .
# Keep the Swift log in the image. A large log can fill the legacy
# builder pipe and stall the build under emulation.
RUN swift build -c release > /tmp/swift-build.log 2>&1 \
    || (cat /tmp/swift-build.log && exit 1)

CMD ["/app/.build/release/CryptoAnalysisMCP"]
