//
//  File.swift
//  
//
//  Created by Levi Bostian on 2/16/24.
//

import Foundation

public class DIGraph {
    
    public static let shared = DIGraph()

    private init() {}

    public var overrides: [String: Any] = [:]
    public var singletons: [String: Any] = [:]

    /**
     Reset graph. Meant to be used in `tearDown()` of tests.
     */
    public func reset() {
        overrides = [:]
        singletons = [:]
    }
}
