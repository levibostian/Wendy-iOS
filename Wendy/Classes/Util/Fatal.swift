//
//  Fatal.swift
//  Wendy
//
//  Created by Levi Bostian on 4/19/18.
//

import Foundation

internal class Fatal {
    
    // https://twitter.com/johnsundell/status/850432972478189569
    internal class func preconditionFailure(_ message: String) {
        NSException(name: .invalidArgumentException, reason: message, userInfo: nil).raise()
        preconditionFailure(message)
    }
    
}
