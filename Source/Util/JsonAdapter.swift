import Foundation

protocol JsonAdapter {
    func toData(_ object: Codable?) -> Data?
    func fromData<T: Codable>(_ data: Data) -> T?
}

// sourcery: InjectRegister = "JsonAdapter"
class JsonAdapterImpl: JsonAdapter {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func toData(_ object: Codable?) -> Data? {
        guard let object else {
            return nil
        }

        do {
            return try encoder.encode(object)
        } catch {
            return nil
        }
    }

    func fromData<T: Codable>(_ data: Data) -> T? {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}
