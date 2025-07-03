// swift-tools-version:6.0
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
            name: "FuseStorageKit",
            dependencies: [
                "FuseStorageCore",
                "GRDBSQLCipher",
                "FuseObjcBridge"
            ],
            path: "Sources/FuseStorageSQLCipher"
        ),
        .testTarget(
            name: "FuseStorageKitTests",
            dependencies: ["FuseStorageKit"],
            path: "Tests/FuseStorageKitTests"
        ),
    ]
)
