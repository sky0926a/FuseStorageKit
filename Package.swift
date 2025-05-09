// swift-tools-version:5.6
import PackageDescription

let package = Package(
  name: "FuseStorageKit",
  platforms: [
    .iOS(.v15),
    .macOS(.v11)
  ],
  products: [
    .library(
      name: "FuseStorageKit",
      targets: ["FuseStorageKit"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
  ],
  targets: [
    .target(
      name: "FuseStorageKit",
      dependencies: [
        .product(name: "GRDB", package: "GRDB.swift"),
        .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
      ],
      path: "Sources/FuseStorageKit",
      swiftSettings: [
        .define("USE_GRDB")
      ]
    ),
    .testTarget(
      name: "FuseStorageKitTests",
      dependencies: ["FuseStorageKit"],
      path: "Tests/FuseStorageKitTests"
    ),
  ]
) 
