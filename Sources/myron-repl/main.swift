import Foundation
import Myron

print(Banner.render(version: MyronLanguage.version))
print("Ready.")

let session = MyronSession()

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
        for error in errors { print(error.message ?? error.reason.description) }

    case .nothing:
        break
    }
}
