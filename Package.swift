// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "battery-logger",
  platforms: [.macOS(.v10_10)],
  products: [
    .executable(name: "battery-logger", targets: ["battery-logger"]),
  ],
  targets: [
    .target(name: "battery-logger", path: "src"),
  ]
)
