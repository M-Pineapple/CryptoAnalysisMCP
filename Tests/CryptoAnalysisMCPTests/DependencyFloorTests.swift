// DependencyFloorTests.swift
//
// Guards the committed Package.resolved against regressing below the
// minimum safe versions of security-relevant dependencies.
import Foundation
import Testing

struct DependencyFloorTests {
    /// Minimum versions that the committed lockfile must satisfy.
    static let floors: [String: [Int]] = [
        "swift-nio": [2, 100, 0],
    ]

    static func resolvedURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // CryptoAnalysisMCPTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // package root
            .appendingPathComponent("Package.resolved")
    }

    static func parse(_ v: String) -> [Int] {
        v.split(separator: ".").map { Int($0) ?? 0 }
    }

    @Test func pinnedDependenciesMeetSecurityFloor() throws {
        let data = try Data(contentsOf: Self.resolvedURL())
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let pins = try #require(json["pins"] as? [[String: Any]])
        for (identity, floor) in Self.floors {
            let pin = try #require(pins.first { ($0["identity"] as? String) == identity },
                                   "\(identity) missing from Package.resolved")
            let state = try #require(pin["state"] as? [String: Any])
            let version = try #require(state["version"] as? String)
            #expect(Self.parse(version).lexicographicallyPrecedes(floor) == false,
                    "\(identity) \(version) is below the required minimum \(floor.map(String.init).joined(separator: "."))")
        }
    }
}
