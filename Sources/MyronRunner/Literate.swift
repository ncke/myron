import Foundation

// MARK: - Literate

enum Literate {
    static let languages: Set<String> = ["lisp", "myron"]

    static let ignoreAttribute = "ignore" // For illustrations that are deliberately wrong.

    static let resetAttribute = "reset-environment" // Starts a clean environment.

    static func segments(fromMarkdown markdown: String) -> [String] {
        let lines = markdown.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        var owners = [Int?]()
        var segment = 0
        var open: Fence?

        for line in lines {
            if let fence = open {
                if fence.isClosed(by: line) {
                    open = nil
                    owners.append(nil)
                } else {
                    owners.append(fence.runs ? segment : nil)
                }
                continue
            }

            open = Fence(opening: line)
            if let fence = open, fence.resets { segment += 1 }
            owners.append(nil)
        }

        return (0...segment).map { index in
            zip(lines, owners)
                .map { line, owner in owner == index ? line : "" }
                .joined(separator: "\n")
        }
    }

}

// MARK: - Fence

// A fenced code block: ```lisp
private struct Fence {
    let marker: Character
    let length: Int
    let runs: Bool
    let resets: Bool

    init?(opening line: Substring) {
        guard let (marker, length, rest) = Self.run(in: line) else { return nil }
        if marker == "`" && rest.contains("`") { return nil }

        let words = rest.split(whereSeparator: \.isWhitespace).map { word in word.lowercased() }
        guard let language = words.first else {
            self.init(marker: marker, length: length, runs: false, resets: false)
            return
        }

        let attributes = words.dropFirst()
        let runs = Literate.languages.contains(language)
            && !attributes.contains(Literate.ignoreAttribute)
        let resets = runs && attributes.contains(Literate.resetAttribute)
        self.init(marker: marker, length: length, runs: runs, resets: resets)
    }

    private init(marker: Character, length: Int, runs: Bool, resets: Bool) {
        self.marker = marker
        self.length = length
        self.runs = runs
        self.resets = resets
    }

    func isClosed(by line: Substring) -> Bool {
        guard let (marker, length, rest) = Self.run(in: line) else { return false }
        return marker == self.marker
            && length >= self.length
            && rest.allSatisfy(\.isWhitespace)
    }
    
    private static func run(in line: Substring) -> (Character, Int, Substring)? {
        let indent = line.prefix { character in character == " " }
        guard indent.count <= 3 else { return nil }

        let text = line.dropFirst(indent.count)
        guard let marker = text.first, marker == "`" || marker == "~" else { return nil }

        let length = text.prefix { character in character == marker }.count
        guard length >= 3 else { return nil }

        return (marker, length, text.dropFirst(length))
    }

}
