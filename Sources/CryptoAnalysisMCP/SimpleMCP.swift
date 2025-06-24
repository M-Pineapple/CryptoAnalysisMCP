import Foundation
import Logging

// MARK: - No-op Logger for production
public struct SwiftLogNoOpLogHandler: LogHandler {
    public var logLevel: Logger.Level = .trace
    public var metadata: Logger.Metadata = [:]
    
    public init() {}
    
    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { return nil }
        set(newValue) { }
    }
    
    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        // Do nothing - no logging in production
    }
}

// MARK: - Simple MCP Protocol Implementation

/// Basic MCP message structure that can be either request or notification
struct MCPMessage: Codable {
    let jsonrpc: String
    let id: Int?
    let method: String?
    let params: [String: Any]?
    let result: [String: Any]?
    let error: MCPError?
    
    private enum CodingKeys: String, CodingKey {
        case jsonrpc, id, method, params, result, error
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.jsonrpc = try container.decodeIfPresent(String.self, forKey: .jsonrpc) ?? "2.0"
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.method = try container.decodeIfPresent(String.self, forKey: .method)
        
        if container.contains(.params) {
            if let paramsDict = try? container.decode([String: Any].self, forKey: .params) {
                self.params = paramsDict
            } else {
                self.params = nil
            }
        } else {
            self.params = nil
        }
        
        if container.contains(.result) {
            if let resultDict = try? container.decode([String: Any].self, forKey: .result) {
                self.result = resultDict
            } else {
                self.result = nil
            }
        } else {
            self.result = nil
        }
        
        self.error = try container.decodeIfPresent(MCPError.self, forKey: .error)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(method, forKey: .method)
        
        if let params = params {
            try container.encode(params, forKey: .params)
        }
        
        if let result = result {
            try container.encode(result, forKey: .result)
        }
        
        try container.encodeIfPresent(error, forKey: .error)
    }
}

/// MCP Response message
struct MCPResponse: Codable {
    let jsonrpc: String = "2.0"
    let id: Int?
    let result: [String: Any]?
    let error: MCPError?
    
    private enum CodingKeys: String, CodingKey {
        case jsonrpc, id, result, error
    }
    
    init(id: Int?, result: [String: Any]) {
        self.id = id
        self.result = result
        self.error = nil
    }
    
    init(id: Int?, error: MCPError) {
        self.id = id
        self.result = nil
        self.error = error
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.error = try container.decodeIfPresent(MCPError.self, forKey: .error)
        
        if container.contains(.result) {
            if let resultDict = try? container.decode([String: Any].self, forKey: .result) {
                self.result = resultDict
            } else {
                self.result = nil
            }
        } else {
            self.result = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encodeIfPresent(id, forKey: .id)
        
        if let result = result {
            try container.encode(result, forKey: .result)
        }
        
        try container.encodeIfPresent(error, forKey: .error)
    }
}

/// MCP Error
struct MCPError: Codable, Error {
    let code: Int
    let message: String
    let data: [String: Any]?
    
    private enum CodingKeys: String, CodingKey {
        case code, message, data
    }
    
    init(code: Int, message: String, data: [String: Any]? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(Int.self, forKey: .code)
        self.message = try container.decode(String.self, forKey: .message)
        
        if container.contains(.data) {
            if let dataDict = try? container.decode([String: Any].self, forKey: .data) {
                self.data = dataDict
            } else {
                self.data = nil
            }
        } else {
            self.data = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(message, forKey: .message)
        
        if let data = data {
            try container.encode(data, forKey: .data)
        }
    }
}

/// Tool definition for MCP
struct MCPTool {
    let name: String
    let description: String
    let inputSchema: [String: Any]
    let handler: ([String: Any]) async -> [String: Any]
    
    init(name: String, description: String, inputSchema: [String: Any], handler: @escaping ([String: Any]) async -> [String: Any]) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
        self.handler = handler
    }
}

/// Simple MCP Server implementation
class MCPServer {
    private let name: String
    private let version: String
    private var tools: [String: MCPTool] = [:]
    private let logger = Logger(label: "MCPServer")
    private let debugMode: Bool
    
    init(name: String, version: String, debugMode: Bool = false) {
        self.name = name
        self.version = version
        self.debugMode = debugMode
    }
    
    func addTool(_ tool: MCPTool) {
        tools[tool.name] = tool
        if debugMode {
            logger.info("📝 Registered tool: \(tool.name)")
        }
    }
    
    func runStdio() async {
        if debugMode {
            logger.info("🚀 Starting MCP Server: \(name) v\(version)")
            logger.info("📡 Listening on STDIO...")
        }
        
        // Set stdin to line buffering mode
        setbuf(stdin, nil)
        
        // Main event loop - don't send anything until we receive a request
        while true {
            guard let line = readLine() else {
                if debugMode {
                    logger.info("📛 STDIO closed, shutting down server")
                }
                break
            }
            
            if debugMode {
                logger.info("📥 Received line: \(line)")
            }
            
            await handleMessage(line)
        }
    }
    
    private func handleMessage(_ message: String) async {
        do {
            guard let data = message.data(using: .utf8) else { return }
            
            let decoder = JSONDecoder()
            let msg = try decoder.decode(MCPMessage.self, from: data)
            
            // Check if it's a notification (no id field)
            if msg.id == nil && msg.method != nil {
                // It's a notification - handle it without sending a response
                if debugMode {
                    logger.info("📨 Received notification: \(msg.method!)")
                }
                
                // Handle specific notifications if needed
                switch msg.method! {
                case "notifications/initialized":
                    // Claude Desktop sends this after initialize - just log it
                    if debugMode {
                        logger.info("✅ Client initialized successfully")
                    }
                default:
                    if debugMode {
                        logger.info("🔕 Ignoring notification: \(msg.method!)")
                    }
                }
                return
            }
            
            // It's a request - must have an id
            guard let method = msg.method, let id = msg.id else {
                if debugMode {
                    logger.error("❌ Invalid message format - missing method or id")
                }
                return
            }
            
            if debugMode {
                logger.info("📨 Received request: \(method)")
            }
            
            switch method {
            case "initialize":
                await handleInitialize(id: id, params: msg.params)
            case "tools/list":
                await handleToolsList(id: id)
            case "tools/call":
                await handleToolCall(id: id, params: msg.params)
            default:
                await sendError(id: id, code: -32601, message: "Method not found: \(method)")
            }
            
        } catch {
            if debugMode {
                logger.error("❌ Failed to parse message: \(error)")
            }
            // Don't send parse errors for invalid messages
        }
    }
    
    private func handleInitialize(id: Int, params: [String: Any]?) async {
        let result: [String: Any] = [
            "protocolVersion": "2024-11-05",
            "capabilities": [
                "tools": [:]
            ],
            "serverInfo": [
                "name": name,
                "version": version
            ]
        ]
        
        await sendResponse(id: id, result: result)
    }
    
    private func handleToolsList(id: Int) async {
        let toolsList = tools.values.map { tool in
            [
                "name": tool.name,
                "description": tool.description,
                "inputSchema": tool.inputSchema
            ]
        }
        
        await sendResponse(id: id, result: ["tools": toolsList])
    }
    
    private func handleToolCall(id: Int, params: [String: Any]?) async {
        guard let params = params,
              let toolName = params["name"] as? String,
              let arguments = params["arguments"] as? [String: Any] else {
            await sendError(id: id, code: -32602, message: "Invalid parameters")
            return
        }
        
        guard let tool = tools[toolName] else {
            await sendError(id: id, code: -32601, message: "Tool not found: \(toolName)")
            return
        }
        
        if debugMode {
            logger.info("🔧 Executing tool: \(toolName)")
        }
        
        let result = await tool.handler(arguments)
        
        // Convert result to proper MCP format
        let jsonData = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted)
        let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        
        let mcpContent = [
            [
                "type": "text",
                "text": jsonString
            ]
        ]
        
        await sendResponse(id: id, result: ["content": mcpContent])
    }
    
    private func sendResponse(id: Int?, result: [String: Any]) async {
        let response = MCPResponse(id: id, result: result)
        await sendMessage(response)
    }
    
    private func sendError(id: Int?, code: Int, message: String) async {
        let error = MCPError(code: code, message: message)
        let response = MCPResponse(id: id, error: error)
        await sendMessage(response)
    }
    
    private func sendMessage<T: Codable>(_ message: T) async {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = []
            let data = try encoder.encode(message)
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
                fflush(stdout)
            }
        } catch {
            if debugMode {
                logger.error("❌ Failed to encode message: \(error)")
            }
        }
    }
}

/// Convenience functions for creating tool schemas
func createToolSchema(
    type: String = "object",
    properties: [String: [String: Any]] = [:],
    required: [String] = []
) -> [String: Any] {
    var schema: [String: Any] = [
        "type": type,
        "properties": properties
    ]
    
    if !required.isEmpty {
        schema["required"] = required
    }
    
    return schema
}

func createProperty(type: String, description: String, items: [String: Any]? = nil) -> [String: Any] {
    var property: [String: Any] = [
        "type": type,
        "description": description
    ]
    
    if let items = items {
        property["items"] = items
    }
    
    return property
}

// MARK: - JSON Encoding/Decoding Extensions
extension KeyedDecodingContainer {
    func decode(_ type: [String: Any].Type, forKey key: K) throws -> [String: Any] {
        let container = try self.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
        return try container.decode(type)
    }
}

extension KeyedEncodingContainer {
    mutating func encode(_ value: [String: Any], forKey key: K) throws {
        var container = self.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
        try container.encode(value)
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        let container = try self.nestedContainer(keyedBy: JSONCodingKey.self)
        return try container.decode(type)
    }
}

extension UnkeyedEncodingContainer {
    mutating func encode(_ value: [String: Any]) throws {
        var container = self.nestedContainer(keyedBy: JSONCodingKey.self)
        try container.encode(value)
    }
}

extension KeyedDecodingContainer where K == JSONCodingKey {
    func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        var dictionary = [String: Any]()
        
        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let nestedDictionary = try? decode([String: Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode([Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

extension KeyedEncodingContainer where K == JSONCodingKey {
    mutating func encode(_ value: [String: Any]) throws {
        for (key, value) in value {
            let key = JSONCodingKey(stringValue: key)!
            switch value {
            case let value as Bool:
                try encode(value, forKey: key)
            case let value as String:
                try encode(value, forKey: key)
            case let value as Int:
                try encode(value, forKey: key)
            case let value as Double:
                try encode(value, forKey: key)
            case let value as [String: Any]:
                try encode(value, forKey: key)
            case let value as [Any]:
                try encode(value, forKey: key)
            default:
                continue
            }
        }
    }
}

extension KeyedDecodingContainer {
    func decode(_ type: [Any].Type, forKey key: K) throws -> [Any] {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
}

extension KeyedEncodingContainer {
    mutating func encode(_ value: [Any], forKey key: K) throws {
        var container = self.nestedUnkeyedContainer(forKey: key)
        try container.encode(value)
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode(_ type: [Any].Type) throws -> [Any] {
        var array = [Any]()
        
        while !isAtEnd {
            if let boolValue = try? decode(Bool.self) {
                array.append(boolValue)
            } else if let stringValue = try? decode(String.self) {
                array.append(stringValue)
            } else if let intValue = try? decode(Int.self) {
                array.append(intValue)
            } else if let doubleValue = try? decode(Double.self) {
                array.append(doubleValue)
            } else if let nestedDictionary = try? decode([String: Any].self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode([Any].self) {
                array.append(nestedArray)
            }
        }
        return array
    }
}

extension UnkeyedEncodingContainer {
    mutating func encode(_ value: [Any]) throws {
        for value in value {
            switch value {
            case let value as Bool:
                try encode(value)
            case let value as String:
                try encode(value)
            case let value as Int:
                try encode(value)
            case let value as Double:
                try encode(value)
            case let value as [String: Any]:
                try encode(value)
            case let value as [Any]:
                try encode(value)
            default:
                continue
            }
        }
    }
}

struct JSONCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
