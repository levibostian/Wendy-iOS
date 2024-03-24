//
//  File.swift
//  
//
//  Created by Levi Bostian on 2/16/24.
//

import Foundation

final public class DIGraph: @unchecked Sendable {
    
    public static let shared = DIGraph()

    let mutex = Mutex()

    private init() {}
    
    internal var overrides: [String: Any] = [:]
    internal var singletons: [String: Any] = [:]

    /**
     Reset graph. Meant to be used in `tearDown()` of tests.
     */
    public func reset() {
        overrides.removeAll()
        singletons.removeAll()
    }
}
