//
//  OpenCodeModels.swift
//  OpenCodeIsland
//
//  Codable types for OpenCode server API responses
//

import Foundation

// MARK: - Health Check

struct HealthResponse: Codable {
    let healthy: Bool
    let version: String
}

// MARK: - Agents

struct ServerAgent: Codable, Identifiable, Equatable {
    let name: String
    let mode: AgentMode
    let native: Bool?
    let isDefault: Bool?
    
    /// Computed id for Identifiable conformance (uses name)
    var id: String { name }
    
    enum AgentMode: String, Codable {
        case primary
        case subagent
        case all
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case mode
        case native
        case isDefault = "default"
    }
    
    /// Whether this agent can be directly selected by users
    var isPrimary: Bool {
        mode == .primary || mode == .all
    }
}

// MARK: - Sessions

struct Session: Codable, Identifiable {
    let id: String
    let title: String?
    let version: String?
    let projectID: String?
    let directory: String?
    let time: SessionTime?
    let parentID: String?
    let share: ShareInfo?
    
    struct SessionTime: Codable {
        let created: Int64  // Unix timestamp in milliseconds
        let updated: Int64
        
        var createdDate: Date {
            Date(timeIntervalSince1970: Double(created) / 1000.0)
        }
        
        var updatedDate: Date {
            Date(timeIntervalSince1970: Double(updated) / 1000.0)
        }
    }
    
    struct ShareInfo: Codable {
        let url: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case version
        case projectID
        case directory
        case time
        case parentID = "parent_id"
        case share
    }
    
    /// Convenience accessor for created date
    var createdAt: Date {
        time?.createdDate ?? Date()
    }
}

struct CreateSessionRequest: Codable {
    let title: String?
    let parentID: String?
    
    // Server uses camelCase, no CodingKeys needed
    
    init(title: String? = nil, parentID: String? = nil) {
        self.title = title
        self.parentID = parentID
    }
}

// MARK: - Messages

/// Tool state for tool parts
struct ToolState: Codable {
    let status: String  // "pending", "running", "completed", "error"
    let input: [String: AnyCodable]?
    let output: String?
    let title: String?
    let error: String?
    let metadata: [String: AnyCodable]?
    let time: ToolTime?
    let attachments: [FilePart]?
    
    struct ToolTime: Codable {
        let start: Int64?
        let end: Int64?
        let compacted: Int64?
    }
    
    var isRunning: Bool { status == "running" || status == "pending" }
    var isCompleted: Bool { status == "completed" }
    var isError: Bool { status == "error" }
}

/// File part for attachments
struct FilePart: Codable {
    let id: String?
    let sessionID: String?
    let messageID: String?
    let type: String?
    let mime: String?
    let filename: String?
    let url: String?
}

/// A flexible wrapper for JSON values that may be any type
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
    
    /// Get the value as a string representation for display
    var stringValue: String {
        switch value {
        case let string as String:
            return string
        case let int as Int:
            return String(int)
        case let double as Double:
            return String(double)
        case let bool as Bool:
            return bool ? "true" : "false"
        case let dict as [String: Any]:
            // Try to extract common keys for tools
            if let path = dict["path"] as? String {
                return path
            } else if let pattern = dict["pattern"] as? String {
                return pattern
            } else if let command = dict["command"] as? String {
                return command
            } else if let query = dict["query"] as? String {
                return query
            }
            // Fallback to JSON representation
            if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return String(describing: dict)
        default:
            return String(describing: value)
        }
    }
}

/// Message part - matches the SDK's Part union type
/// Handles all part types: text, tool, reasoning, file, step-start, step-finish, etc.
struct MessagePart: Codable, Identifiable {
    let id: String
    let sessionID: String?
    let messageID: String?
    let type: PartType
    
    // Text part fields
    let text: String?
    let synthetic: Bool?
    let ignored: Bool?
    
    // Tool part fields
    let callID: String?
    let tool: String?
    let state: ToolState?
    
    // Reasoning part fields (uses text field)
    
    // File part fields
    let mime: String?
    let filename: String?
    let url: String?
    
    // Step-start/step-finish fields
    let snapshot: String?
    let reason: String?
    let cost: Double?
    let tokens: PartTokens?
    
    // Agent part fields
    let name: String?
    
    // Subtask part fields
    let prompt: String?
    let description: String?
    let agent: String?
    
    // Retry part fields
    let attempt: Int?
    let error: PartError?
    
    // Time fields
    let time: PartTime?
    
    struct PartTime: Codable {
        let start: Int64?
        let end: Int64?
        let created: Int64?
    }
    
    struct PartTokens: Codable {
        let input: Int?
        let output: Int?
        let reasoning: Int?
        let cache: TokenCache?
        
        struct TokenCache: Codable {
            let read: Int?
            let write: Int?
        }
    }
    
    struct PartError: Codable {
        let name: String?
        let data: ErrorData?
        
        struct ErrorData: Codable {
            let message: String?
            let statusCode: Int?
        }
    }
    
    enum PartType: String, Codable {
        case text
        case tool
        case reasoning
        case file
        case stepStart = "step-start"
        case stepFinish = "step-finish"
        case snapshot
        case patch
        case agent
        case subtask
        case retry
        case compaction
        case unknown
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = PartType(rawValue: rawValue) ?? .unknown
        }
    }
    
    /// Display name for tool
    var toolDisplayName: String {
        guard let toolName = tool else { return "Tool" }
        return toolName
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    /// Icon for tool type
    var toolIcon: String {
        guard let toolName = tool else { return "wrench" }
        switch toolName.lowercased() {
        case "read", "read_file": return "doc.text"
        case "write", "write_file": return "doc.text.fill"
        case "edit", "edit_file": return "pencil"
        case "bash", "shell": return "terminal"
        case "glob", "find", "find_files": return "magnifyingglass"
        case "grep", "search", "find_text": return "text.magnifyingglass"
        case "list_dir", "ls": return "folder"
        case "task", "agent": return "person.2"
        case "web_search", "websearch", "fetch", "webfetch": return "globe"
        case "todowrite", "todoread": return "checklist"
        default: return "wrench"
        }
    }
    
    /// Tool input summary for display
    var toolInputSummary: String? {
        guard let input = state?.input else { return nil }
        
        // Try to extract the most relevant field for each tool type
        if let path = input["filePath"]?.stringValue ?? input["path"]?.stringValue {
            return path
        }
        if let pattern = input["pattern"]?.stringValue {
            return pattern
        }
        if let command = input["command"]?.stringValue {
            return command
        }
        if let query = input["query"]?.stringValue {
            return query
        }
        if let description = input["description"]?.stringValue {
            return description
        }
        
        // For other tools, try to get any string value
        for (_, value) in input {
            let str = value.stringValue
            if !str.isEmpty && str != "null" {
                return str
            }
        }
        
        return nil
    }
}

struct MessageTime: Codable {
    let created: Int64
    let completed: Int64?
    
    var createdDate: Date {
        Date(timeIntervalSince1970: Double(created) / 1000.0)
    }
    
    var completedDate: Date? {
        guard let completed = completed else { return nil }
        return Date(timeIntervalSince1970: Double(completed) / 1000.0)
    }
}

struct MessagePath: Codable {
    let cwd: String?
    let root: String?
}

struct MessageTokens: Codable {
    let input: Int?
    let output: Int?
    let reasoning: Int?
    let cache: TokenCache?
    
    struct TokenCache: Codable {
        let read: Int?
        let write: Int?
    }
}

struct Message: Codable, Identifiable {
    let id: String
    let sessionID: String
    let role: MessageRole
    let time: MessageTime?
    let parentID: String?
    let modelID: String?
    let providerID: String?
    let mode: String?
    let agent: String?
    let path: MessagePath?
    let cost: Double?
    let tokens: MessageTokens?
    let finish: String?
    
    enum MessageRole: String, Codable {
        case user
        case assistant
    }
    
    /// Convenience accessor for created date
    var createdAt: Date {
        time?.createdDate ?? Date()
    }
    
    // No CodingKeys needed - server uses camelCase which Swift handles
}

struct MessageWithParts: Codable {
    let info: Message
    let parts: [MessagePart]
}

// MARK: - Prompt Request/Response

struct PromptRequest: Codable {
    let parts: [PromptPart]
    let agent: String?
    let model: ModelRef?
    let noReply: Bool?
    
    struct ModelRef: Codable {
        let providerID: String
        let modelID: String
    }
    
    init(text: String, agent: String? = nil) {
        self.parts = [PromptPart.text(text)]
        self.agent = agent
        self.model = nil
        self.noReply = nil
    }
    
    init(parts: [PromptPart], agent: String? = nil) {
        self.parts = parts
        self.agent = agent
        self.model = nil
        self.noReply = nil
    }
}

/// A part of a prompt - can be text or a file (image)
/// OpenCode uses type "file" for images with a data URL
enum PromptPart: Codable {
    case text(String)
    case file(url: String, mime: String, filename: String?)  // data URL with mime type
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case url
        case mime
        case filename
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .file(let url, let mime, let filename):
            try container.encode("file", forKey: .type)
            try container.encode(url, forKey: .url)
            try container.encode(mime, forKey: .mime)
            try container.encodeIfPresent(filename, forKey: .filename)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case "file":
            let url = try container.decode(String.self, forKey: .url)
            let mime = try container.decode(String.self, forKey: .mime)
            let filename = try container.decodeIfPresent(String.self, forKey: .filename)
            self = .file(url: url, mime: mime, filename: filename)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown part type: \(type)")
            )
        }
    }
    
    /// Create an image part from base64 data
    /// - Parameters:
    ///   - base64Data: The base64 encoded image data (without the data URL prefix)
    ///   - mediaType: The MIME type (e.g., "image/png", "image/jpeg")
    ///   - filename: Optional filename
    /// - Returns: A file part with proper data URL format
    static func image(base64Data: String, mediaType: String, filename: String? = nil) -> PromptPart {
        let dataURL = "data:\(mediaType);base64,\(base64Data)"
        return .file(url: dataURL, mime: mediaType, filename: filename)
    }
}

// MARK: - Path

/// Response from GET /path - server's current working directory
struct PathInfo: Codable {
    let cwd: String
    let root: String?
}

// MARK: - Config

struct ServerConfig: Codable {
    let model: String?
    let defaultAgent: String?
    // Server likely uses camelCase, no CodingKeys needed
}

// MARK: - Providers & Models

/// Response from GET /provider
struct ProviderListResponse: Codable {
    let all: [Provider]
    let `default`: [String: String]  // providerID -> modelID
    let connected: [String]
}

struct Provider: Codable, Identifiable {
    let id: String
    let name: String
    let models: [String: ProviderModel]  // Dictionary keyed by model ID
    
    /// Get models as an array for easier iteration
    var modelsArray: [ProviderModel] {
        Array(models.values)
    }
}

struct ProviderModel: Codable, Identifiable {
    let id: String
    let name: String
    let providerID: String?
    let family: String?
    let status: String?
    let limit: ModelLimit?
    
    struct ModelLimit: Codable {
        let context: Int?
        let output: Int?
    }
}

/// A model reference with provider info for UI display
struct ModelRef: Identifiable, Equatable, Hashable {
    let providerID: String
    let modelID: String
    let displayName: String
    
    var id: String { "\(providerID)/\(modelID)" }
    
    init(providerID: String, modelID: String, displayName: String) {
        self.providerID = providerID
        self.modelID = modelID
        self.displayName = displayName
    }
    
    init(provider: Provider, model: ProviderModel) {
        self.providerID = provider.id
        self.modelID = model.id
        self.displayName = "\(provider.name) - \(model.name)"
    }
}

// MARK: - SSE Events

/// Represents a Server-Sent Event from the OpenCode server
struct SSEEvent {
    let type: String
    let data: Data
    
    /// Decode the event data as a specific type
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
}

/// Event types sent by the server
enum OpenCodeEventType: String {
    case serverConnected = "server.connected"
    case sessionCreated = "session.created"
    case sessionUpdated = "session.updated"
    case messageCreated = "message.created"
    case messageUpdated = "message.updated"
    case messagePartUpdated = "message.part.updated"
    case messagePartRemoved = "message.part.removed"
    case sessionStatus = "session.status"
    case sessionIdle = "session.idle"
    case sessionError = "session.error"
    case unknown
    
    init(rawValue: String) {
        switch rawValue {
        case "server.connected": self = .serverConnected
        case "session.created": self = .sessionCreated
        case "session.updated": self = .sessionUpdated
        case "message.created": self = .messageCreated
        case "message.updated": self = .messageUpdated
        case "message.part.updated": self = .messagePartUpdated
        case "message.part.removed": self = .messagePartRemoved
        case "session.status": self = .sessionStatus
        case "session.idle": self = .sessionIdle
        case "session.error": self = .sessionError
        default: self = .unknown
        }
    }
}

/// Event payload for message part updates (streaming text and tool updates)
struct MessagePartUpdatedEvent: Codable {
    let properties: PartProperties
    
    struct PartProperties: Codable {
        let part: MessagePart
        let delta: String?  // For streaming text updates, this contains the new text chunk
    }
}

/// Event payload for message updates
struct MessageUpdatedEvent: Codable {
    let properties: MessageProperties
    
    struct MessageProperties: Codable {
        let info: Message
    }
}

/// Session status type - matches SDK
struct SessionStatusType: Codable {
    let type: String  // "idle", "busy", "retry"
    let attempt: Int?
    let message: String?
    let next: Int?
}

/// Event payload for session status updates
struct SessionStatusEvent: Codable {
    let properties: StatusProperties
    
    struct StatusProperties: Codable {
        let sessionID: String
        let status: SessionStatusType
    }
}

/// Event payload for session idle
struct SessionIdleEvent: Codable {
    let properties: IdleProperties
    
    struct IdleProperties: Codable {
        let sessionID: String
    }
}

/// Event payload for session error
struct SessionErrorEvent: Codable {
    let properties: ErrorProperties
    
    struct ErrorProperties: Codable {
        let sessionID: String?
        let error: SessionError?
        
        struct SessionError: Codable {
            let name: String?
            let data: ErrorData?
            
            struct ErrorData: Codable {
                let message: String?
            }
        }
    }
}
