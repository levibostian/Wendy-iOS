import SnapKit
import UIKit
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

    fileprivate let cancelButton: UIButton = {
        let view = UIButton()
        view.setTitle("Cancel", for: UIControl.State.normal)
        view.setTitleColor(UIColor.blue, for: .normal)
        return view
    }()

    fileprivate let runCollectionButton: UIButton = {
        let view = UIButton()
        view.setTitle("Run collection \(WendyCollectionIds.groceryShopping.rawValue)", for: UIControl.State.normal)
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

    fileprivate lazy var secondButtonsRowStackView: UIStackView = { [unowned self] in
        let view = UIStackView(arrangedSubviews: [self.cancelButton, self.runCollectionButton])
        view.alignment = .leading
        view.distribution = .fill
        view.axis = .horizontal
        return view
    }()

    fileprivate lazy var textFieldStackView: UIStackView = { [unowned self] in
        let view = UIStackView(arrangedSubviews: [self.dataTextField, self.groupTextField, self.manuallyRunViewsStackView, self.automaticallyRunWendyViewsStackView, self.buttonsStackView, self.secondButtonsRowStackView])
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
            pendingTaskTableView.reloadData()
        }
    }

    fileprivate func populateWendyPendingTasks() {
        wendyPendingTasks = Wendy.shared.getAllTasks()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        WendyConfig.addTaskRunnerListener(self)

        view.addSubview(textFieldStackView)
        view.addSubview(pendingTaskTableView)
        view.backgroundColor = UIColor.white

        setupview()

        view.setNeedsUpdateConstraints()
    }

    fileprivate func setupview() {
        addTaskButton.addTarget(self, action: #selector(MainViewController.addTaskButtonPressed(_:)), for: .touchUpInside)
        runAllTasksButton.addTarget(self, action: #selector(MainViewController.runAllTasksButtonPressed(_:)), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(MainViewController.cancelButtonPressed(_:)), for: .touchUpInside)

        automaticallyRunWendySwitch.addTarget(self, action: #selector(automaticallyRunWendySwitchPressed(_:)), for: .touchUpInside)
        runCollectionButton.addTarget(self, action: #selector(runCollectionButtonPressed(_:)), for: .touchUpInside)
        automaticallyRunWendySwitch.setOn(WendyConfig.automaticallyRunTasks, animated: false)

        pendingTaskTableView.delegate = self
        pendingTaskTableView.dataSource = self
        pendingTaskTableView.register(PendingTaskTableViewCell.self, forCellReuseIdentifier: String(describing: PendingTaskTableViewCell.self))
        populateWendyPendingTasks()
    }

    @objc func runAllTasksButtonPressed(_ sender: Any) {
        Wendy.shared.runTasks(filter: nil) { result in
            print("Done running all tasks. Result: \(result)")
        }
    }

    @objc func cancelButtonPressed(_ sender: Any) {
        Wendy.shared.clear()
    }

    @objc func runCollectionButtonPressed(_ sender: Any) {
        Wendy.shared.runTasks(filter: RunAllTasksFilter.collection(id: WendyCollectionIds.groceryShopping.rawValue)) { result in
            print("Done running all tasks. Result: \(result)")
        }
    }

    @objc func automaticallyRunWendySwitchPressed(_ sender: Any) {
        WendyConfig.automaticallyRunTasks = automaticallyRunWendySwitch.isOn
    }

    @objc func addTaskButtonPressed(_ sender: Any) {
        guard let dataTextEntered = self.dataTextField.text, !dataTextEntered.isEmpty else {
            let alert = UIAlertController(title: "Enter text for data id", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel) { _ in })
            present(alert, animated: true, completion: nil)
            return
        }
        let groupId: String? = (groupTextField.text!.isEmpty) ? nil : groupTextField.text

        _ = Wendy.shared.addTask(AddGroceryListItemPendingTask(groceryListItemName: dataTextEntered, manuallyRun: manuallyRunSwitch.isOn, groupId: groupId))
    }

    override func updateViewConstraints() {
        if !didSetupConstraints {
            didSetupConstraints = true

            buttonsStackView.snp.makeConstraints { make in
                make.width.equalToSuperview()
            }
            secondButtonsRowStackView.snp.makeConstraints { make in
                make.width.equalToSuperview()
            }
            textFieldStackView.snp.makeConstraints { make in
                make.width.equalToSuperview().offset(-40)
                make.centerX.equalToSuperview()
                if #available(iOS 11.0, *) {
                    make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                } else {
                    make.top.equalToSuperview()
                }
            }
            for textField in [self.dataTextField, self.groupTextField] {
                textField.snp.makeConstraints { make in
                    make.leading.equalToSuperview()
                    make.trailing.equalToSuperview()
                }
            }
            pendingTaskTableView.snp.makeConstraints({ make in
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
        return wendyPendingTasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PendingTaskTableViewCell.self), for: indexPath) as! PendingTaskTableViewCell // swiftlint:disable:this force_cast
        let item = wendyPendingTasks[indexPath.row]
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
        Wendy.shared.runTask(task.taskId!) { result in
            print("Result of manually run task id ID: \(task.taskId!) is: \(result)")
        }
    }
}

extension MainViewController: TaskRunnerListener {
    func errorRecorded(_ task: PendingTask, errorMessage: String?, errorId: String?) {
        populateWendyPendingTasks()
    }

    func errorResolved(_ task: PendingTask) {
        populateWendyPendingTasks()
    }

    func allTasksComplete() {
        populateWendyPendingTasks()
    }

    func taskSkipped(_ task: PendingTask, reason: ReasonPendingTaskSkipped) {
        populateWendyPendingTasks()
    }

    func taskComplete(_ task: PendingTask, successful: Bool, cancelled: Bool) {
        if successful && !cancelled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.populateWendyPendingTasks()
            }
        } else {
            populateWendyPendingTasks()
        }
    }

    func runningTask(_ task: PendingTask) {
        populateWendyPendingTasks()
    }

    func newTaskAdded(_ task: PendingTask) {
        populateWendyPendingTasks()
    }
}
