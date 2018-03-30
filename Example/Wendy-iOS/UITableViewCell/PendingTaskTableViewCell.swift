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

protocol PendingTaskTableViewCellDelegate {
}

class PendingTaskTableViewCell: UITableViewCell {

    fileprivate var didSetupConstraints = false
    
    private var item: PendingTask!
    private var position: Int!

    fileprivate let dataIdLabel: UILabel = {
        let view = UILabel()
        return view
    }()
    
    var delegate: PendingTaskTableViewCellDelegate?
    
    func populateCell(_ item: PendingTask, position: Int) {
        self.item = item
        self.position = position

        self.dataIdLabel.text = item.dataId

        self.addSubview(self.dataIdLabel)

        self.setNeedsUpdateConstraints()
    }

    override func updateConstraints() {
        if !didSetupConstraints {
            dataIdLabel.snp.makeConstraints({ (make) in
                make.edges.equalToSuperview()
            })

            didSetupConstraints = true
        }
        super.updateConstraints()
    }
    
}
