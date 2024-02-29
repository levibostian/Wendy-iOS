// swift-tools-version:5.3

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
    ],
    targets: [ 
        .target(name: "Wendy",
                dependencies: [],
                path: "Source/"),
        .testTarget(name: "WendyTests",
                    dependencies: ["Wendy"],
                    path: "Tests/")
    ]
)