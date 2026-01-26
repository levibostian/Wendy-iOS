import Foundation

/**
 Dependency Injection Graph.

 Features:
 * Get an instance of a class. As easy as: `DIGraph.shared.foo` to get a strongly typed instance.
 * Register overrides for testing. In tests, run `DIGraph.shared.overrideFoo(instance)` and the next time code requests an instance of `foo`, your override will be used.
 * Easily reset all dependencies in the codebase as convenience for tests. In test tearDown call: `DIGraph.shared.reset()` and all overrides, instances, and singletons in the codebase will be reset to their original state.

 The code for the DIGraph is automatically generated. You inherit one of the provided protocols to your class.
 */
public final class DIGraph: Sendable, Singleton {
    public static let shared = DIGraph()

    private init() {}

    /**
     Reset the graph and all dependencies tied to it.

     Meant to be used in `tearDown()` of tests.
     */
    public func reset() {
        resetSingletons()
    }

    public struct Data: AutoResettable {
        var overrides: [String: Any] = [:]
    }

    public final class DataStore: InMemoryDataStore<Data>, Singleton {
        public static let shared: DataStore = .init(data: Data())
    }
}

/**
 Convenient global variable to access the shared DIGraph.

 Usage:
 ```
 var foo: Foo { inject.foo }
 ```
 */
var inject: DIGraph {
    DIGraph.shared
}

/**
 A protocol indicating that you can reset the instance back to it's original state as if the instance was just constructed.
 */
public protocol Resettable {
    mutating func reset()
}

/**
 You can optionally use this protocol instead of `Resettable` which will automatically generate the `Resettable` conformance.

 The algorithm used is to get all properties of the class and set them to their default values. Great for in-memory data stores.
 */
public protocol AutoResettable {}

// MARK: - Protocols to register classes with the DIGraph.

/**
 A protocol to indicate that a class is a singleton.
 When conforming to this protocol, you must provide a `reset` function that will reset the state of the singleton instance as if the singleton was just constructed.
 This is useful for testing where each test should run in a clean environment.

 The DIGraph will detect your Singleton and register it with the graph.
 */
public protocol Singleton: Resettable {
    static var shared: Self { get }
}

/*
 If you are wanting to create a dependency that can be injected in the DIGraph that's not a singleton,
 at this time, you do not inherit a protocol but instead add a comment above your class.

 // sourcery: InjectRegister = "QueueWriter" <-- the string is the data type you want to register in the DIGraph. A common pattern is to use the name of a protocol. That way you can set overrides in tests by mocking that protocol.
 */

// public protocol InjectableAs<T> {
//    associatedtype T
// }
//
// public protocol Injectable {}
