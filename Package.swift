// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "brh-splitview",
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [
    .library(name: "BRHSplitview", targets: ["BRHSplitview"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
  ],
  targets: [
    .target(
      name: "BRHSplitview",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .testTarget(
      name: "BRHSplitviewTests",
      dependencies: ["BRHSplitview"]
    ),
  ]
)
