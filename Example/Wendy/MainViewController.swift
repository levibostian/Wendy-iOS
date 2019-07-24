//
//  ViewController.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 03/26/2018.
//  Copyright (c) 2018 Levi Bostian. All rights reserved.
//

import UIKit
import SnapKit
import Wendy

class MainViewController: UIViewController {

    fileprivate var didSetupConstraints = false

    fileprivate let dataTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "data id"
        view.borderStyle = UITextField.BorderStyle.line
        return view
    }()

    fileprivate let groupTextField: UITextField = {
        let view = UITextField()
        view.placeholder = "group id"
        view.borderStyle = UITextField.BorderStyle.line
        return view
    }()

    fileprivate let manuallyRunSwitch: UISwitch = {
        let view = UISwitch()
        view.setOn(false, animated: false)
        return view
    }()

    fileprivate let manuallyRunSwitchLabel: UILabel = {
        let view = UILabel()
        view.text = "Manually run task"
        return view
    }()

    fileprivate lazy var manuallyRunViewsStackView: UIStackView = { [unowned self] in
        let view = UIStackView(arrangedSubviews: [self.manuallyRunSwitch, self.manuallyRunSwitchLabel])
        view.alignment = .leading
        view.distribution = .fill
        view.spacing = 8.0
        view.axis = .horizontal
        return view
    }()

    fileprivate let automaticallyRunWendySwitch: UISwitch = {
        let view = UISwitch()
        view.setOn(false, animated: false)
        return view
    }()

    fileprivate let automaticallyRunWendySwitchLabel: UILabel = {
        let view = UILabel()
        view.text = "Wendy automatically run tasks"
        return view
    }()

    fileprivate lazy var automaticallyRunWendyViewsStackView: UIStackView = { [unowned self] in
        let view = UIStackView(arrangedSubviews: [self.automaticallyRunWendySwitch, self.automaticallyRunWendySwitchLabel])
        view.alignment = .leading
        view.distribution = .fill
        view.spacing = 8.0
        view.axis = .horizontal
        return view
    }()

    fileprivate let addTaskButton: UIButton = {
        let view = UIButton()
        view.setTitle("Add task", for: UIControl.State.normal)
        view.setTitleColor(UIColor.blue, for: .normal)
        return view
    }()

    fileprivate let runAllTasksButton: UIButton = {
        let view = UIButton()
        view.setTitle("Run all tasks", for: UIControl.State.normal)
        view.setTitleColor(UIColor.blue, for: .normal)
        return view
    }()

    fileprivate lazy var buttonsStackView: UIStackView = { [unowned self] in
        let view = UIStackView(arrangedSubviews: [self.addTaskButton, self.runAllTasksButton])
        view.alignment = .leading
        view.distribution = .fill
        view.axis = .horizontal
        return view
    }()

    fileprivate lazy var textFieldStackView: UIStackView = { [unowned self] in
        let view = UIStackView(arrangedSubviews: [self.dataTextField, self.groupTextField, self.manuallyRunViewsStackView, self.automaticallyRunWendyViewsStackView, self.buttonsStackView])
        view.alignment = .leading
        view.distribution = .fillEqually
        view.spacing = 8.0
        view.axis = .vertical
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    fileprivate let pendingTaskTableView: UITableView = {
        let view = UITableView()
        view.estimatedRowHeight = 360.0
        view.rowHeight = UITableView.automaticDimension
        return view
    }()

    fileprivate var wendyPendingTasks: [PendingTask] = [] {
        didSet {
            self.pendingTaskTableView.reloadData()
        }
    }

    fileprivate func populateWendyPendingTasks() {
        self.wendyPendingTasks = Wendy.shared.getAllTasks()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        WendyConfig.addTaskRunnerListener(self)

        self.view.addSubview(textFieldStackView)
        self.view.addSubview(pendingTaskTableView)
        self.view.backgroundColor = UIColor.white

        self.setupview()

        self.view.setNeedsUpdateConstraints()
    }

    fileprivate func setupview() {
        self.addTaskButton.addTarget(self, action: #selector(MainViewController.addTaskButtonPressed(_:)), for: .touchUpInside)
        self.runAllTasksButton.addTarget(self, action: #selector(MainViewController.runAllTasksButtonPressed(_:)), for: .touchUpInside)

        self.automaticallyRunWendySwitch.addTarget(self, action: #selector(automaticallyRunWendySwitchPressed(_:)), for: .touchUpInside)
        self.automaticallyRunWendySwitch.setOn(WendyConfig.automaticallyRunTasks, animated: false)

        self.pendingTaskTableView.delegate = self
        self.pendingTaskTableView.dataSource = self
        self.pendingTaskTableView.register(PendingTaskTableViewCell.self, forCellReuseIdentifier: String(describing: PendingTaskTableViewCell.self))
        self.populateWendyPendingTasks()
    }

    @objc func runAllTasksButtonPressed(_ sender: Any) {
        Wendy.shared.runTasks(filter: nil)
    }

    @objc func automaticallyRunWendySwitchPressed(_ sender: Any) {
        WendyConfig.automaticallyRunTasks = self.automaticallyRunWendySwitch.isOn
    }

    @objc func addTaskButtonPressed(_ sender: Any) {
        guard let dataTextEntered = self.dataTextField.text, dataTextEntered.count > 0 else {
            let alert = UIAlertController(title: "Enter text for data id", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel) { _ in })
            self.present(alert, animated: true, completion: nil)
            return
        }
        let groupId: String? = (self.groupTextField.text!.isEmpty) ? nil : self.groupTextField.text

        _ = Wendy.shared.addTask(AddGroceryListItemPendingTask(groceryListItemName: dataTextEntered, manuallyRun: self.manuallyRunSwitch.isOn, groupId: groupId))
    }

    override func updateViewConstraints() {
        if !didSetupConstraints {
            didSetupConstraints = true

            self.buttonsStackView.snp.makeConstraints({ (make) in
                make.width.equalToSuperview()
            })
            self.textFieldStackView.snp.makeConstraints({ (make) in
                make.width.equalToSuperview().offset(-40)
                make.centerX.equalToSuperview()
                if #available(iOS 11.0, *) {
                    make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                } else {
                    make.top.equalToSuperview()
                }
            })
            for textField in [self.dataTextField, self.groupTextField] {
                textField.snp.makeConstraints({ (make) in
                    make.leading.equalToSuperview()
                    make.trailing.equalToSuperview()
                })
            }
            self.pendingTaskTableView.snp.makeConstraints({ (make) in
                make.top.equalTo(self.textFieldStackView.snp.bottom)
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview()
                if #available(iOS 11.0, *) {
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
                } else {
                    make.bottom.equalToSuperview()
                }
            })
        }
        super.updateViewConstraints()
    }

}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.wendyPendingTasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PendingTaskTableViewCell.self), for: indexPath) as! PendingTaskTableViewCell // swiftlint:disable:this force_cast
        let item = self.wendyPendingTasks[indexPath.row]
        cell.populateCell(item, position: indexPath.row)
        cell.delegate = self
        return cell
    }

}

extension MainViewController: PendingTaskTableViewCellDelegate {
    
    func resolveErrorButtonPressed(_ task: PendingTask) {
        _ = Wendy.shared.resolveError(taskId: task.taskId!)
    }
    
    func runTaskButtonPressed(_ task: PendingTask) {
        Wendy.shared.runTask(task.taskId!)
    }
    
}

extension MainViewController: TaskRunnerListener {

    func errorRecorded(_ task: PendingTask, errorMessage: String?, errorId: String?) {
        self.populateWendyPendingTasks()
    }

    func errorResolved(_ task: PendingTask) {
        self.populateWendyPendingTasks()
    }

    func allTasksComplete() {
        self.populateWendyPendingTasks()
    }

    func taskSkipped(_ task: PendingTask, reason: ReasonPendingTaskSkipped) {
        self.populateWendyPendingTasks()
    }

    func taskComplete(_ task: PendingTask, successful: Bool) {
        if successful {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.populateWendyPendingTasks()
            }
        } else {
            self.populateWendyPendingTasks()
        }
    }

    func runningTask(_ task: PendingTask) {
        self.populateWendyPendingTasks()
    }

    func newTaskAdded(_ task: PendingTask) {
        self.populateWendyPendingTasks()
    }

}
