// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "brh-splitview",
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [
    .library(name: "brh-splitview", targets: ["brh-splitview"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
  ],
  targets: [
    .target(
      name: "brh-splitview",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    ),
    .testTarget(
      name: "brh-splitviewTests",
      dependencies: ["brh-splitview"]
    ),
  ]
)
