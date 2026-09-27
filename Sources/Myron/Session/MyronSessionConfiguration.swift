import Foundation

// MARK: - MyronSessionConfiguration

public struct MyronSessionConfiguration: Sendable {
    public enum ErrorStyle: Sendable { case terse, verbose }
    public let errorStyle: ErrorStyle
    public let maximumStackDepth: Int?
    public let maximumEvalDepth: Int?

    public init(errorStyle: ErrorStyle, maximumStackDepth: Int?, maximumEvalDepth: Int? = 8) {
        self.errorStyle = errorStyle
        self.maximumStackDepth = maximumStackDepth
        self.maximumEvalDepth = maximumEvalDepth
    }
}

// MARK: - Standard Configuration

extension MyronSessionConfiguration {

    public static let standard = MyronSessionConfiguration(
        errorStyle: .verbose,
        maximumStackDepth: 2000,
        maximumEvalDepth: 8
    )

}
