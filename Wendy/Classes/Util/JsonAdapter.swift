//
//  JsonAdapter.swift
//  Wendy
//
//  Created by Levi Bostian on 1/27/24.
//

import Foundation

internal protocol JsonAdapter {
    func toData(_ object: Codable) -> Data?
    func fromData<T: Codable>(_ data: Data) -> T?
}

internal class JsonAdapterImpl: JsonAdapter {
    
    internal static let shared: JsonAdapter = JsonAdapterImpl()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    func toData(_ object: Codable) -> Data? {
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
