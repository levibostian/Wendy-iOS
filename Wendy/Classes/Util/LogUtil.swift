//
//  LogUtil.swift
//  Wendy
//
//  Created by Levi Bostian on 4/2/18.
//

import Foundation

internal class LogUtil {

    internal class func d(_ message: String) {
        if WendyConfig.debug {
            NSLog("\(WendyConfig.logTag) debug: %@", message)
        }
    }
    
    internal class func w(_ message: String) {
        if WendyConfig.debug {
            NSLog("\(WendyConfig.logTag) WARNING: %@", message)
        }
    }

}
