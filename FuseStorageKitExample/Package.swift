// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "FuseStorageKitExample",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(
            name: "FuseStorageKitExample",
            targets: ["FuseStorageKitExample"])
    ],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "FuseStorageKitExample",
            dependencies: [
                .product(name: "FuseStorageKit", package: "FuseStorageKit")
            ],
            path: "FuseStorageKitExample")
    ]
) 