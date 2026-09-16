import Foundation

class Counter {
 
    nonisolated(unsafe) private static var count: Int = 0
    
    static func next() -> Int {
        count += 1
        return count
    }
    
}
