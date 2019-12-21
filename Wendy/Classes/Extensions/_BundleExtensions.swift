import Foundation

internal extension Bundle {
    class func bundleUrlForWendyFramework() -> Bundle {
        let frameworkBundle = Bundle(for: Wendy.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("Wendy.bundle")
        return Bundle(url: bundleURL!)!
    }

    class func frameworkUrlForWendyFramework() -> Bundle {
        let frameworkBundle = Bundle(for: Wendy.self)
        let bundleURL = frameworkBundle.resourceURL
        return Bundle(url: bundleURL!)!
    }
}
