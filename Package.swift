// swift-tools-version:3.1

import PackageDescription

let package = Package(
  name: "Blindr",
  targets: [],
  dependencies: [
    .Package(url: "https://github.com/jakeheis/SwiftCLI", majorVersion: 3, minor: 0),
    .Package(url: "https://github.com/JustHTTP/Just.git", majorVersion: 0, minor: 5),
  ]
)

