import Foundation

public final class DIGraph: @unchecked Sendable {
    public static let shared = DIGraph()

    let mutex = Mutex()

    private init() {}

    var overrides: [String: Any] = [:]
    var singletons: [String: Any] = [:]

    /**
     Reset graph. Meant to be used in `tearDown()` of tests.
     */
    public func reset() {
        overrides.removeAll()
        singletons.removeAll()
    }
}
