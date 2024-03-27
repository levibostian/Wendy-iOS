import Foundation

internal extension PendingTask {
    // Using instead of Equatable protocol because Swift does not allow a protocol inherit another protocol *and* I don't want the subclass to inherit Equatable, I just want to internally.
    func equals(_ other: PendingTask) -> Bool {
        return tag == other.tag &&
            data == other.data
    }
}
