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
        view.borderStyle = UITextBorderStyle.line
        return view
    }()

    fileprivate let addTaskButton: UIButton = {
        let view = UIButton()
        view.setTitle("Add task", for: UIControlState.normal)
        view.setTitleColor(UIColor.blue, for: .normal)
        return view
    }()

    fileprivate let textFieldStackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .leading
        view.distribution = .fillEqually
        view.axis = .vertical
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.textFieldStackView.addArrangedSubview(dataTextField)
        self.textFieldStackView.addArrangedSubview(addTaskButton)

        self.view.addSubview(textFieldStackView)
        self.view.backgroundColor = UIColor.white

        self.setupview()

        self.view.setNeedsUpdateConstraints()
    }

    fileprivate func setupview() {
        self.addTaskButton.addTarget(self, action: #selector(MainViewController.addTaskButtonPressed(_:)), for: UIControlEvents.touchUpInside)
    }

    @objc func addTaskButtonPressed(_ sender: Any) {
        guard let dataTextEntered = self.dataTextField.text, dataTextEntered.count > 0 else {
            let alert = UIAlertController(title: "Enter text for data id", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel) { action in })
            self.present(alert, animated: true, completion: nil)
            return
        }

        try! _ = PendingTasks.sharedInstance.addTask(AddGroceryListItemPendingTask(groceryListItemName: dataTextEntered))
    }

    override func updateViewConstraints() {
        if !didSetupConstraints {
            didSetupConstraints = true

            self.textFieldStackView.snp.makeConstraints({ (make) in
                make.width.equalToSuperview().offset(-40)
                make.centerX.equalToSuperview()
                if #available(iOS 11.0, *) {
                    make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                } else {
                    make.top.equalToSuperview()
                }
            })
            self.dataTextField.snp.makeConstraints({ (make) in
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview()
                make.top.equalToSuperview()
            })
        }
        super.updateViewConstraints()
    }

}

