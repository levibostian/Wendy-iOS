//
//  WendyTaskRunner.swift
//  Wendy
//
//  Created by Levi Bostian on 1/14/24.
//

import Foundation

public protocol WendyTaskRunner {
    func runTask(tag: String, dataId: String?, complete: @escaping (Error?) -> Void)
}
