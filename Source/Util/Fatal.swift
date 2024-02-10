import Foundation

internal class Fatal {
    // https://twitter.com/johnsundell/status/850432972478189569
    internal class func preconditionFailure(_ message: String) {
        NSException(name: .invalidArgumentException, reason: message, userInfo: nil).raise()
        preconditionFailure(message)
    }

    internal class func error(_ message: String, error: NSError) {
        fatalError("\(message)\nPlease create a GitHub issue for Wendy with this issue (https://github.com/levibostian/Wendy-iOS/issues/new)\n\n Error: \(error), \(error.userInfo)")
    }
}
