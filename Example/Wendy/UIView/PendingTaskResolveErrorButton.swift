import SnapKit
import UIKit
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

        setTitleColor(UIColor.blue, for: .normal)
        self.isHidden = true
        setTitle("Resolve Error", for: .normal)

        addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)

        setNeedsUpdateConstraints()
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
        pendingTask = task
        WendyConfig.addTaskStatusListenerForTask(task.taskId!, listener: self)
    }
}

extension PendingTaskResolveErrorButton: PendingTaskStatusListener {
    func running(taskId: Double) {
        isHidden = true
    }

    func complete(taskId: Double, successful: Bool, cancelled: Bool) {
        isHidden = true
    }

    func skipped(taskId: Double, reason: ReasonPendingTaskSkipped) {
        isHidden = true
    }

    func errorRecorded(taskId: Double, errorMessage: String?, errorId: String?) {
        isHidden = false
    }

    func errorResolved(taskId: Double) {
        isHidden = true
    }
}
