//
//  PendingTaskTableViewCell.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 3/30/18.
//Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Wendy
import SnapKit

protocol PendingTaskTableViewCellDelegate: AnyObject {
    func resolveErrorButtonPressed(_ task: PendingTask)
    func runTaskButtonPressed(_ task: PendingTask)
}

class PendingTaskTableViewCell: UITableViewCell {

    fileprivate var didSetupConstraints = false

    private var item: PendingTask!
    private var position: Int!
    
    weak var delegate: PendingTaskTableViewCellDelegate?

    fileprivate let idLabel: UILabel = {
        let view = UILabel()
        return view
    }()

    fileprivate let tagLabel: UILabel = {
        let view = UILabel()
        return view
    }()

    fileprivate let dataIdLabel: UILabel = {
        let view = UILabel()
        return view
    }()

    fileprivate let groupIdLabel: UILabel = {
        let view = UILabel()
        return view
    }()

    fileprivate let manuallyRunTaskLabel: UILabel = {
        let view = UILabel()
        return view
    }()

    fileprivate let createdAtLabel: UILabel = {
        let view = UILabel()
        return view
    }()

    fileprivate lazy var labelsStackView: UIStackView = { [unowned self] in
        let view = UIStackView(arrangedSubviews: [idLabel, tagLabel, dataIdLabel, groupIdLabel, manuallyRunTaskLabel, createdAtLabel])
        view.alignment = .leading
        view.distribution = .fill
        view.spacing = 2.0
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        return view
    }()
    
    fileprivate let pendingTaskStatusLabel: PendingTaskStatusUILabel = {
        let view = PendingTaskStatusUILabel()
        return view
    }()
    
    fileprivate let runTaskButton: UIButton = {
        let view = UIButton()
        view.setTitle("Run task", for: .normal)
        view.setTitleColor(UIColor.blue, for: .normal)
        return view
    }()
    
    fileprivate let resolveErrorButton: PendingTaskResolveErrorButton = {
        let view = PendingTaskResolveErrorButton()       
        return view
    }()
    
    fileprivate lazy var buttonsStackView: UIStackView = { [unowned self] in
        let view = UIStackView(arrangedSubviews: [pendingTaskStatusLabel, runTaskButton, resolveErrorButton])
        view.alignment = .leading
        view.distribution = .fill
        view.spacing = 2.0
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        return view
    }()

    func populateCell(_ item: PendingTask, position: Int) {
        self.item = item
        self.position = position

        self.idLabel.text = "id: \(item.taskId!)"
        self.tagLabel.text = "tag: \(item.tag)"
        self.dataIdLabel.text = "dataId: \(item.dataId!)"
        self.groupIdLabel.text = "groupId: \(item.groupId ?? "(none)")"
        self.manuallyRunTaskLabel.text = "manuallyRun: \(item.manuallyRun)"
        self.createdAtLabel.text = "createdAt: \(item.createdAt!)"
        self.pendingTaskStatusLabel.setPendingTask(item)

        self.contentView.addSubview(self.labelsStackView)
        self.contentView.addSubview(self.buttonsStackView)
        
        self.runTaskButton.addTarget(self, action: #selector(runTaskButtonPressed(_:)), for: .touchUpInside)
        self.runTaskButton.isHidden = !item.isAbleToManuallyRun()
        self.resolveErrorButton.delegate = self
        self.resolveErrorButton.setPendingTask(item)

        self.setNeedsUpdateConstraints()
    }
    
    @objc func runTaskButtonPressed(_ sender: AnyObject) {
        delegate?.runTaskButtonPressed(self.item)
    }

    override func updateConstraints() {
        if !didSetupConstraints {
            labelsStackView.snp.makeConstraints({ (make) in
                make.width.equalToSuperview().multipliedBy(0.6)
                make.leading.equalToSuperview()
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            })
            buttonsStackView.snp.makeConstraints({ (make) in
                make.leading.equalTo(labelsStackView.snp.trailing)
                make.trailing.equalToSuperview()
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            })

            didSetupConstraints = true
        }
        super.updateConstraints()
    }

}

extension PendingTaskTableViewCell: PendingTaskResolveErrorButtonDelegate {
    
    func resolveErrorButtonPressed(_ task: PendingTask) {
        delegate?.resolveErrorButtonPressed(task)
    }
    
}
