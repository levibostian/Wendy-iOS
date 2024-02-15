//
//  File.swift
//  
//
//  Created by Levi Bostian on 2/13/24.
//

import Foundation

/**
 Guarantee the wrapped value is only ever accessed from one thread at a time.

 Class is public because public fields may be Atomic.
 This class is only used for internal SDK development, only. It's not part of the official SDK.

 Inspired from: https://github.com/RougeWare/Swift-Atomic/blob/master/Sources/Atomic/Atomic.swift
 */
@propertyWrapper
public struct Atomic<DataType: Any> {
    fileprivate let exclusiveAccessQueue = DispatchQueue(label: "Atomic \(UUID())", qos: .userInteractive)

    fileprivate var unsafeValue: DataType

    /// Safely accesses the unsafe value from within the context of its exclusive-access queue
    public var wrappedValue: DataType {
        get { exclusiveAccessQueue.sync { unsafeValue } }
        set { exclusiveAccessQueue.sync { unsafeValue = newValue } }
    }

    /**
     Initializer that satisfies @propertyWrapper's requirements.
     With this initializer created, you can assign default values to our wrapped properties,
     like this: `@Atomic var foo = Foo()`
     */
    public init(wrappedValue: DataType) {
        self.unsafeValue = wrappedValue
    }
}
