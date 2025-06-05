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
            targets: ["FuseStorage"]
        ),
        .library(
            name: "FuseStorageKitSQLCipher",
            targets: ["FuseStorageSQLCipher"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.5.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
    ],
    targets: [
        .binaryTarget(
            name: "GRDBSQLCipher",
            url: "https://github.com/duckduckgo/GRDB.swift/releases/download/3.0.0/GRDB.xcframework.zip",
            checksum: "41f01022f6a35986393e063e1ef386fd896646ed032f7d0419c4b02fa3afe61d"
        ),
        .target(
            name: "FuseStorageCore",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
            ],
            path: "Sources/FuseStorageCore"
        ),
        .target(
            name: "FuseObjcBridge",
            path: "Sources/FuseObjcBridge",
            publicHeadersPath: "include"
        ),
        .target(
            name: "FuseStorage",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                "FuseStorageCore",
                "FuseObjcBridge"
            ],
            path: "Sources/FuseStorage"
        ),
        .target(
            name: "FuseStorageSQLCipher",
            dependencies: [
                "FuseStorageCore",
                "GRDBSQLCipher",
                "FuseObjcBridge"
            ],
            path: "Sources/FuseStorageSQLCipher"
        ),
        .testTarget(
            name: "FuseStorageKitTests",
            dependencies: ["FuseStorageSQLCipher"],
            path: "Tests/FuseStorageKitTests"
        ),
    ]
)
