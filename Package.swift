// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "brh-splitview",
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [
    .library(name: "BRHSplitView", targets: ["BRHSplitView"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.19.0"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
  ],
  targets: [
    .target(
      name: "BRHSplitView",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .testTarget(
      name: "BRHSplitViewTests",
      dependencies: [
        "BRHSplitView", .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
      ]
    ),
  ]
)
