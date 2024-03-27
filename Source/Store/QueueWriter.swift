//
//  QueueWriter.swift
//  Wendy
//
//  Created by Levi Bostian on 1/24/24.
//

import Foundation

public protocol QueueWriter {
    func add<Data: Codable>(tag: String, data: Data, groupId: String?) -> PendingTask
    func delete(taskId: Double) -> Bool
}

public extension QueueWriter {
    func delete(task: PendingTask) -> Bool {
        return delete(taskId: task.taskId!)
    }
}
