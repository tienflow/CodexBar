import Foundation

enum AgentState: String, Codable, CaseIterable {
    case idle
    case thinking
    case developing
    case confirming
    case completed

    var label: String {
        switch self {
        case .idle:       return "空闲"
        case .thinking:   return "思考中"
        case .developing: return "开发中"
        case .confirming: return "需要确认"
        case .completed:  return "已完成"
        }
    }
}

struct AgentStatus: Codable {
    let state: AgentState
    let timestamp: String?
    let session_id: String?
    let turn_id: String?
    let cwd: String?
    let model: String?
    let last_tool: String?
    let last_tool_detail: String?

    static let empty = AgentStatus(
        state: .idle, timestamp: nil, session_id: nil,
        turn_id: nil, cwd: nil, model: nil,
        last_tool: nil, last_tool_detail: nil
    )
}
