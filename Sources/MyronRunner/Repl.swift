import Foundation
import Myron

// MARK: - REPL

enum Repl {

    static func run(in session: MyronSession) {
        print(Banner.render(version: MyronLanguage.version))
        print("Ready.")

        while true {
            print("> ", terminator: "")
            fflush(nil)

            guard let line = readLine() else {
                print()
                break
            }

            switch session.eval(line) {

            case .success(let value):
                print(value)

            case .failure(let errors):
                for error in errors { Console.error(error.message ?? error.reason.description) }

            case .nothing:
                break
            }
        }
    }

}
