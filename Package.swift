// swift-tools-version:5.8

import PackageDescription
import Foundation

let package = Package(
    name: "Wendy",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "Wendy", targets: ["Wendy"])
    ],
    dependencies: [
        // Help for the format of declaring SPM dependencies:
        // https://web.archive.org/web/20220525200227/https://www.timc.dev/posts/understanding-swift-packages/
        //
        // Update to exact version until wrapper SDKs become part of testing pipeline.        
        .package(url: "https://github.com/groue/Semaphore.git", from: "0.0.8")
    ],
    targets: [ 
        .target(name: "Wendy",
                dependencies: ["Semaphore"],
                path: "Source/"),
        .testTarget(name: "WendyTests",
                    dependencies: ["Wendy"],
                    path: "Tests/")
    ]
)

// Enable swift concurrency to all targets in package
for target in package.targets {
  var settings = target.swiftSettings ?? []
  settings.append(.enableExperimentalFeature("StrictConcurrency"))
  target.swiftSettings = settings
}
