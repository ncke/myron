import Foundation

// MARK: - MyronSessionConfiguration

public struct MyronSessionConfiguration: Sendable {
    public enum ErrorStyle: Sendable { case terse, verbose }
    public let errorStyle: ErrorStyle
    public let maximumStackDepth: Int?
}

// MARK: - Standard Configuration

extension MyronSessionConfiguration {

    public static let standard = MyronSessionConfiguration(
        errorStyle: .verbose,
        maximumStackDepth: 2000
    )

}
