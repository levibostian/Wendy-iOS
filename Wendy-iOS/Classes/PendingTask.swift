//
//  PendingTask.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 3/26/18.
//

import Foundation

public protocol PendingTask {

    var dataId: String? { get set }
    var manuallyRun: Bool { get set }
    var groupId: String? { get set }
    var tag: String { get }

    func runTask(complete: @escaping (Bool) -> Void)
    func canRunTask() -> Bool

}