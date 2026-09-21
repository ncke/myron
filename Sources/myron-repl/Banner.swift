import Foundation

enum Banner {

    // MARK: - Artwork

    private static let wordmark = [
        "████  ████  ▀██▄ ▄██▀  █████████  █████████  ███▄   ██",
        "██ ████ ██    ▀███▀    ██     ██  ██     ██  ██▀█▄  ██",
        "██  ██  ██     ██      █████████  ██     ██  ██  ▀█▄██",
        "██      ██     ██      ██   ████  █████████  ██   ▀███",
    ]

    private static let indent = "   "
    private static let wordmarkTop = 2 // Which banner row the lettering starts on.

    // MARK: - Starfield

    private static let dust: Character = "."
    private static let faint: Character = "\u{00B7}"
    private static let mid: Character = "+"
    private static let bright: Character = "*"

    private static let skyAbove: [[(Int, Character)]] = [
        [(0, dust), (9, faint), (18, dust), (26, faint), (33, dust), (41, faint),
         (48, dust), (55, faint), (62, dust), (69, faint), (77, dust)],
        [(4, faint), (12, bright), (21, dust), (29, faint), (36, mid), (44, dust),
         (51, faint), (57, dust), (64, faint), (71, dust)],
    ]

    private static let skyBelow: [[(Int, Character)]] = [
        [(0, dust), (5, faint), (11, dust), (20, bright), (27, dust), (34, faint),
         (64, dust)],
        [(9, faint), (17, dust), (25, faint), (32, dust), (38, bright), (45, dust),
         (52, faint), (63, faint), (70, dust), (77, faint)],
    ]

    private static let skyAcross: [[(Int, Character)]] = [
        [(8, faint)],
        [(0, bright), (30, faint), (54, faint), (72, dust)],
        [(41, faint), (66, dust)],
        [(1, faint), (29, faint)],
    ]

    // MARK: - The parens

    private static let parenArc: [[(offset: Int, glyph: Character)]] = [
        [(1, bright)],
        [(2, bright), (3, bright)],
        [(3, bright), (4, bright)],
        [(2, bright), (3, bright)],
        [(1, bright)],
    ]

    private static let parenRamp = ramp + [202]
    private static let parenTop = 2
    private static let parenColumns = [59, 66, 73]

    // MARK: - Palette

    private static let ramp = [228, 220, 214, 208]
    private static let hues: [Character: [Int]] = [
        dust: [59, 60],
        faint: [66, 67],
        mid: [109, 152],
        bright: [195, 255],
    ]
    private static let versionInk = 244

    // MARK: - Width

    private static let minimumWidth = 58
    private static let fieldWidth = 78

    // MARK: - Rendering

    static func render(version: String) -> String {
        let stamp = "version \(version)"
        let available = terminalWidth
        guard available >= minimumWidth else { return cramped(stamp, width: available) }
        let sky = min(fieldWidth, available)

        var lines: [String] = [""]
        lines += skyAbove.enumerated().map { spangle($1, row: $0, width: sky) }
        lines.append("")
        lines += wordmark.indices.map { letters(line: $0, width: sky) }
        lines.append(stamped(skyBelow[0], row: 6, width: sky, text: stamp))
        lines.append(spangle(skyBelow[1], row: 7, width: sky))
        lines.append("")

        return lines.joined(separator: "\n")
    }

    private static var edge: Int {
        indent.count + wordmark.reduce(0) { max($0, $1.count) }
    }

    private static func letters(line: Int, width: Int) -> String {
        let row = line + wordmarkTop
        let gold = ramp[line]
        var cells = blank(width: max(width, indent.count + wordmark[line].count))

        for (column, glyph) in wordmark[line].enumerated() {
            cells[column + indent.count] = (glyph, gold)
        }
        close(row: row, into: &cells)
        strew(skyAcross[line], row: row, into: &cells)
        return paint(cells)
    }

    private static func spangle(
        _ stars: [(Int, Character)], row: Int, width: Int
    ) -> String {
        var cells = blank(width: width)
        close(row: row, into: &cells)
        strew(stars, row: row, into: &cells)
        return paint(cells)
    }

    private static func stamped(
        _ stars: [(Int, Character)], row: Int, width: Int, text: String
    ) -> String {
        let start = max(0, edge - text.count)
        let clearance = max(0, start - 2) ..< (start + text.count + 2)

        var cells = blank(width: width)
        close(row: row, into: &cells)
        strew(stars, row: row, into: &cells, skipping: clearance)
        for (offset, character) in text.enumerated() where start + offset < cells.count {
            cells[start + offset] = (character, versionInk)
        }
        return paint(cells)
    }

    private static func blank(width: Int) -> [(Character, Int)] {
        [(Character, Int)](repeating: (" ", versionInk), count: max(0, width))
    }

    private static func strew(
        _ stars: [(Int, Character)],
        row: Int,
        into cells: inout [(Character, Int)],
        skipping: Range<Int>? = nil
    ) {
        for (column, glyph) in stars
        where column < cells.count
            && cells[column].0 == " "
            && !(skipping?.contains(column) ?? false) {
            cells[column] = (glyph, hue(glyph, row: row, column: column))
        }
    }

    private static func close(row: Int, into cells: inout [(Character, Int)]) {
        let index = row - parenTop
        guard index >= 0, index < parenArc.count else { return }
        let ink = parenRamp[index]
        for base in parenColumns {
            for (offset, glyph) in parenArc[index] {
                let column = base + offset
                guard column < cells.count, cells[column].0 == " " else { continue }
                cells[column] = (glyph, ink)
            }
        }
    }

    private static func hue(_ glyph: Character, row: Int, column: Int) -> Int {
        guard let palette = hues[glyph], !palette.isEmpty else { return versionInk }
        return palette[(row * 31 + column * 17) % palette.count]
    }
    
    private static func paint(_ cells: [(Character, Int)]) -> String {
        guard isColourful else {
            return String(cells.map(\.0)).trimmingTrailing()
        }
        var out = ""
        var current = -1
        for (glyph, ink) in cells {
            guard glyph != " " else { out += " "; continue }
            if ink != current {
                out += escape(ink)
                current = ink
            }
            out += String(glyph)
        }
        return out.trimmingTrailing() + reset
    }

    private static func cramped(_ stamp: String, width: Int) -> String {
        [
            "",
            spangle([(2, bright), (9, dust), (17, faint)], row: 0, width: width),
            indent + colourise("M Y R O N", ramp[0]),
            spangle([(5, dust), (14, bright)], row: 1, width: width),
            indent + colourise(stamp, versionInk),
            "",
        ].joined(separator: "\n")
    }

    private static func colourise(_ line: String, _ colour: Int) -> String {
        isColourful ? escape(colour) + line + reset : line
    }

    private static func escape(_ colour: Int) -> String { "\u{001B}[38;5;\(colour)m" }

    private static let reset = "\u{001B}[0m"

    // MARK: - Terminal

    private static var isColourful: Bool {
        let environment = ProcessInfo.processInfo.environment
        guard environment["NO_COLOR"] == nil else { return false }
        guard let term = environment["TERM"], term != "dumb" else { return false }
        return isatty(STDOUT_FILENO) == 1
    }

    private static var terminalWidth: Int {
        var window = winsize()
        if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &window) == 0, window.ws_col > 0 {
            return Int(window.ws_col)
        }
        if let columns = ProcessInfo.processInfo.environment["COLUMNS"],
           let width = Int(columns) {
            return width
        }
        return 80
    }
}

private extension String {
    func trimmingTrailing() -> String {
        var copy = self
        while copy.last == " " { copy.removeLast() }
        return copy
    }
}
