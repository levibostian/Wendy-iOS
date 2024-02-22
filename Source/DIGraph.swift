//
//  File.swift
//  
//
//  Created by Levi Bostian on 2/16/24.
//

import Foundation

public class DIGraph {
    
    public static let shared = DIGraph()
    
    let mutex = Mutex()

    private init() {}

    public var overrides: [String: Any] = [:]
    internal var singletons: [String: Any] = [:]

    /**
     Reset graph. Meant to be used in `tearDown()` of tests.
     */
    public func reset() {
        overrides = [:]
        singletons = [:]
    }
}
