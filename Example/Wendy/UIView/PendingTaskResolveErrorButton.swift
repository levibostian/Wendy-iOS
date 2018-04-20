//
//  PendingTaskResolveErrorButton.swift
//  Wendy_Example
//
//  Created by Levi Bostian on 4/20/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit
import Wendy

protocol PendingTaskResolveErrorButtonDelegate: AnyObject {
    func resolveErrorButtonPressed(_ task: PendingTask)
}

class PendingTaskResolveErrorButton: UIButton {
    
    fileprivate var didSetupConstraints = false
    
    fileprivate var pendingTask: PendingTask!
    weak var delegate: PendingTaskResolveErrorButtonDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setTitleColor(UIColor.blue, for: .normal)
        self.isHidden = true
        self.setTitle("Resolve Error", for: .normal)
        
        self.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        
        self.setNeedsUpdateConstraints()
    }
    
    @objc func buttonPressed(_ sender: AnyObject) {
        delegate?.resolveErrorButtonPressed(pendingTask)
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
        self.pendingTask = task
        WendyConfig.addTaskStatusListenerForTask(task.taskId!, listener: self)
    }
    
}

extension PendingTaskResolveErrorButton: PendingTaskStatusListener {
    
    func running(taskId: Double) {
        self.isHidden = true
    }
    
    func complete(taskId: Double, successful: Bool) {
        self.isHidden = true
    }
    
    func skipped(taskId: Double, reason: ReasonPendingTaskSkipped) {
        self.isHidden = true
    }
    
    func errorRecorded(taskId: Double, errorMessage: String?, errorId: String?) {
        self.isHidden = false
    }
    
    func errorResolved(taskId: Double) {
        self.isHidden = true
    }
    
}
