import Foundation

public extension Data {
    func wendyDecode<Data: Codable>() -> Data? {
        DIGraph.shared.jsonAdapter.fromData(self)
    }
}

extension Data {
    func asDictionary() -> [String: AnyHashable] {
        do {
            return try JSONSerialization.jsonObject(with: self, options: []) as? [String: AnyHashable] ?? [:]
        } catch {
            return [:]
        }
    }
}
