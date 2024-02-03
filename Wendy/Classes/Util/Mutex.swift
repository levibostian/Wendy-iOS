//
//  Mutex.swift
//  Wendy
//
//  Created by Levi Bostian on 1/27/24.
//

import Foundation

public class Mutex {
    // Resursive lock allows a thread to call lock() N times
    // and will not release the lock until unlock() called N times, too.
    // This makes the lock safe for use cases such as recursion and
    // calling other methods in a class that acquire the lock.
    private let _lock = NSRecursiveLock()

    func lock() {
        _lock.lock()
    }

    func unlock() {
        _lock.unlock()
    }
}
