//
//  BundleExtensions.swift
//  Wendy
//
//  Created by Levi Bostian on 3/30/18.
//

import Foundation

extension Bundle {

    class func bundleUrlForWendyFramework() -> Bundle {
        let frameworkBundle = Bundle(for: PendingTasks.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("Wendy-iOS.bundle")
        return Bundle.init(url: bundleURL!)!
    }

    class func frameworkUrlForWendyFramework() -> Bundle {
        let frameworkBundle = Bundle(for: PendingTasks.self)
        let bundleURL = frameworkBundle.resourceURL
        return Bundle.init(url: bundleURL!)!
    }

}
