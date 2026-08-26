import Foundation
import Myron

let signature = #"""
   *       .        *
      |\/| \ / |_) / \ |\ |  .
  .   |  |  |  | \ \_/ | \|
        *        .       *
"""#

print(signature)
print()
print("      version \(Myron.version)")
print()
print("Ready.")

let session = MyronSession()

while true {
    print("> ", terminator: "")
    fflush(stdout)

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
