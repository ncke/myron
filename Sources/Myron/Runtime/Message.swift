import Foundation

// MARK: - Message

struct Message {
    let source: MyronProcess
    let destination: MyronProcess
    let sequence: Int
    let content: MyronValue
}

extension Message: Hashable {}
