import Foundation

/**
 Boilerplate code to create a Sendable in-memory data store.

    Usage:

    ```
     // 1. Define the data that you want to have stored in-memory.
     public struct Data: Resettable {
         var overrides: [String: Any] = [:]
     }

     // 2. Then, create a class that extends this generic class.
     public final class DataStore: InMemoryDataStore<Data>, Singleton {
         public static let shared: DataStore = DataStore(data: Data())
     }
    ```

 Notes:
 * @unchecked because `data` is mutable but we are mutating it only behind a lock.
 */
public class InMemoryDataStore<DataType: Resettable>: Resettable, @unchecked Sendable {
    private let mutex = Mutex()

    private var data: DataType

    init(data: DataType) {
        self.data = data
    }

    public func reset() {
        updateDataBlock { data in
            data.reset()
        }
    }

    /**
     Read the data at it's current state.
     */
    public func getDataSnapshot() -> DataType {
        mutex.lock()

        let dataSnapshot = data

        mutex.unlock()

        return dataSnapshot
    }

    /**
     Safely update the data stored in-memory.

     The block has a lock on the memory. Be careful how long you hold onto that lock.
     */
    @discardableResult
    public func updateDataBlock<T>(_ update: (inout DataType) -> T) -> T {
        mutex.lock()

        let result = update(&data)

        mutex.unlock()

        return result
    }
}
