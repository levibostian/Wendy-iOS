//
//  PendingTaskStatusUILabel.swift
//  Wendy_Example
//
//  Created by Levi Bostian on 4/20/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit
import Wendy

class PendingTaskStatusUILabel: UILabel {
    
    fileprivate var didSetupConstraints = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.text = "Not running"
        self.numberOfLines = 0
        
        self.setNeedsUpdateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func updateConstraints() {
        if !didSetupConstraints {
            // snapkit add constraints.
            
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
    
    func setPendingTask(_ task: PendingTask) {
        WendyConfig.addTaskStatusListenerForTask(task.taskId!, listener: self)
    }
    
}

extension PendingTaskStatusUILabel: PendingTaskStatusListener {
    
    func running(taskId: Double) {
        self.text = "Running"
    }
    
    func complete(taskId: Double, successful: Bool) {
        self.text = successful ? "Success!" : "Failure"
    }
    
    func skipped(taskId: Double, reason: ReasonPendingTaskSkipped) {
        self.text = "Skipped"
    }
    
    func errorRecorded(taskId: Double, errorMessage: String?, errorId: String?) {
        self.text = "Error recorded: \(errorMessage!)"
    }
    
    func errorResolved(taskId: Double) {
        self.text = "Error resolved"
    }
    
}
