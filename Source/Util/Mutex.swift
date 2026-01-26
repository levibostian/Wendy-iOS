import Foundation

public final class Mutex: Sendable {
    /// Resursive lock allows a thread to call lock() N times
    /// and will not release the lock until unlock() called N times, too.
    /// This makes the lock safe for use cases such as recursion and
    /// calling other methods in a class that acquire the lock.
    private let _lock = NSRecursiveLock()

    func lock() {
        _lock.lock()
    }

    func unlock() {
        _lock.unlock()
    }

    public struct Data: AutoResettable {
        var mutexes: [String: Mutex] = [:]
    }

    final class Store: InMemoryDataStore<Data>, Singleton {
        static let shared: Store = .init(data: Data())

        func getMutex(for subject: Any) -> Mutex {
            getMutex(for: String(describing: subject))
        }

        func getMutex(for key: String) -> Mutex {
            updateDataBlock { data in
                if let existingMutex = data.mutexes[key] {
                    return existingMutex
                }

                let mutex = Mutex()
                data.mutexes[key] = mutex

                return mutex
            }
        }
    }
}
