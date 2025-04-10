// swift-tools-version:5.9

// SPDX-License-Identifier: Apache-2.0

import PackageDescription

let exampleTargets = [
    "AccountAlias",
    "AccountAllowance",
    "AddNftAllowance",
    "ConsensusPubSub",
    "ConsensusPubSubChunked",
    "ConsensusPubSubWithSubmitKey",
    "CreateAccount",
    "CreateAccountThresholdKey",
    "CreateFile",
    "CreateSimpleContract",
    "CreateStatefulContract",
    "CreateTopic",
    "DeleteAccount",
    "DeleteFile",
    "FileAppendChunked",
    "GenerateKey",
    "GenerateKeyWithMnemonic",
    "GetAccountBalance",
    "GetAccountInfo",
    "GetAddressBook",
    "GetExchangeRates",
    "GetFileContents",
    "ModifyTokenKeys",
    "MultiAppTransfer",
    "MultiSigOffline",
    "Prng",
    "Schedule",
    "ScheduledTransactionMultiSigThreshold",
    "ScheduledTransfer",
    "ScheduleIdenticalTransaction",
    "ScheduleMultiSigTransaction",
    "Staking",
    "StakingWithUpdate",
    "TopicWithAdminKey",
    "TransferCrypto",
    "TransferTokens",
    "UpdateAccountPublicKey",
    "ValidateChecksum",
    "TokenUpdateMetadata",
    "NftUpdateMetadata",
    "TokenAirdrop",
    "InitializeClientWithMirrorNetwork",
    "LongTermScheduledTransaction",
    "CreateAccountWithAlias",
    "CreateTopicWithRevenue",
].map { name in
    Target.executableTarget(
        name: "\(name)Example",
        dependencies: [
            "Hiero",
            "HieroExampleUtilities",
            .product(name: "SwiftDotenv", package: "swift-dotenv"),
        ],
        path: "Examples/\(name)",
        swiftSettings: [.unsafeFlags(["-parse-as-library"])]
    )
}

let package = Package(
    name: "Hiero",
    platforms: [
        .macOS(.v14),
        .iOS(.v13),
    ],
    products: [
        .library(name: "Hiero", targets: ["Hiero"])
    ],
    dependencies: [
        .package(url: "https://github.com/objecthub/swift-numberkit.git", from: "2.6.0"),
        .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "2.1.0"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.28.2"),
        .package(url: "https://github.com/vsanthanam/AnyAsyncSequence.git", from: "1.0.2"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-asn1.git", from: "1.3.1"),
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift.git", from: "0.18.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.3"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.18.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.112.0"),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.5.1"),
        .package(url: "https://github.com/krzyzanowskim/OpenSSL-Package.git", from: "3.3.2000"),
    ],
    targets: [
        .target(
            name: "HieroProtobufs",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "GRPCCore", package: "grpc-swift"),
            ],
            exclude: [
                "Protos",
                "update_protos.py",
            ]
        ),
        .target(
            name: "HieroExampleUtilities",
            dependencies: ["Hiero"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "Hiero",
            dependencies: [
                "HieroProtobufs",
                "AnyAsyncSequence",
                .product(name: "SwiftASN1", package: "swift-asn1"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "NumberKit", package: "swift-numberkit"),
                .product(name: "GRPCCore", package: "grpc-swift"),
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "secp256k1", package: "secp256k1.swift"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "OpenSSL", package: "OpenSSL-Package"),
            ]
        ),
        .executableTarget(
            name: "HieroTCK",
            dependencies: [
                "Hiero",
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(
            name: "HieroTests",
            dependencies: [
                "Hiero",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: ["__Snapshots__"]
        ),
        .testTarget(
            name: "HieroE2ETests",
            dependencies: [
                "Hiero",
                .product(name: "SwiftDotenv", package: "swift-dotenv"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                "HieroExampleUtilities",
            ],
            exclude: ["File/__Snapshots__"]
        ),
    ] + exampleTargets
)
