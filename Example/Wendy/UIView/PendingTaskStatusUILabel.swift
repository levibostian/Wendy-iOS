import SnapKit
import UIKit
import Wendy

class PendingTaskStatusUILabel: UILabel {
    fileprivate var didSetupConstraints = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.numberOfLines = 0

        setNeedsUpdateConstraints()
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
        text = "Not running"

        WendyConfig.addTaskStatusListenerForTask(task.taskId!, listener: self)
    }
}

extension PendingTaskStatusUILabel: PendingTaskStatusListener {
    func running(taskId: Double) {
        text = "Running"
    }

    func complete(taskId: Double, successful: Bool, cancelled: Bool) {
        text = successful ? "Success!" : "Failure"
    }

    func skipped(taskId: Double, reason: ReasonPendingTaskSkipped) {
        text = "Skipped"
    }
}
