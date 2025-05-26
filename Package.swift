// swift-tools-version:5.6
import PackageDescription

let package = Package(
  name: "FuseStorageKit",
  platforms: [
    .iOS(.v15),
    .macOS(.v11)
  ],
  products: [
    // Core library with shared functionality
    .library(
      name: "FuseStorageCoreKit",
      targets: ["FuseStorageCoreKit"]
    ),
    // FuseStorageKit with SQLCipher support (default)
    .library(
      name: "FuseStorageKit",
      targets: ["FuseStorageKit"]
    ),
    // FuseStorageKit with standard GRDB (no encryption)
    .library(
      name: "FuseStorageKitStandard", 
      targets: ["FuseStorageKitStandard"]
    ),
  ],
  dependencies: [
    // DuckDuckGo GRDB with SQLCipher support
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
    // Original GRDB without SQLCipher
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.5.0"),
  ],
  targets: [
    // Binary target for SQLCipher-enabled GRDB
    .binaryTarget(
      name: "GRDBSQLCipher",
      url: "https://github.com/duckduckgo/GRDB.swift/releases/download/3.0.0/GRDB.xcframework.zip",
      checksum: "41f01022f6a35986393e063e1ef386fd896646ed032f7d0419c4b02fa3afe61d"
    ),
    
    // Core target with shared functionality (no GRDB dependency)
    .target(
      name: "FuseStorageCoreKit",
      dependencies: [
        .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
      ],
      path: "Sources/FuseStorageCoreKit"
    ),
    
    // FuseStorageKit with SQLCipher support
    .target(
      name: "FuseStorageKit",
      dependencies: [
        "GRDBSQLCipher",
        "FuseStorageCoreKit",
      ],
      path: "Sources/FuseStorageKit",
      swiftSettings: [
        .define("USE_GRDB"),
        .define("SQLITE_HAS_CODEC"),
        .define("SQLCIPHER_ENABLED"),
      ]
    ),
    
    // FuseStorageKit with standard GRDB
    .target(
      name: "FuseStorageKitStandard",
      dependencies: [
        .product(name: "GRDB", package: "GRDB.swift"),
        "FuseStorageCoreKit",
      ],
      path: "Sources/FuseStorageKitStandard",
      swiftSettings: [
        .define("USE_GRDB"),
        // Note: SQLCIPHER_ENABLED is NOT defined here
      ]
    ),
    
    .testTarget(
      name: "FuseStorageKitTests",
      dependencies: ["FuseStorageKit"],
      path: "Tests/FuseStorageKitTests"
    ),
  ]
) 
