import Foundation

public typealias CollectionId = String
public typealias Collections = [CollectionId: [PendingTask.Tag]]

internal extension Collections {
    func getCollection(id: CollectionId) -> [PendingTask.Tag] {
        guard let collection = self[id] else {
            fatalError("Collection id: \(id) not found in collections: \(self)")
        }

        return collection
    }
}
