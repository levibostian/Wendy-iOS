//
//  File.swift
//  
//
//  Created by Levi Bostian on 3/26/24.
//

import Foundation

public extension Data {
    func wendyDecode<Data: Codable>() -> Data? {        
        return DIGraph.shared.jsonAdapter.fromData(self)
    }
}
