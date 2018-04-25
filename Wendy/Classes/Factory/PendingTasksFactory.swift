//
//  PendingTasksFactory.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 11/14/17.
//  Copyright © 2017 Curiosity IO. All rights reserved.
//

import Foundation

public protocol PendingTasksFactory {
    func getTask(tag: String) -> PendingTask?
}
