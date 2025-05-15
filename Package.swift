// swift-tools-version:5.6

/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2022 - 2024 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

import PackageDescription

let exampleTargets = [
    "AccountAlias",
    "AccountAllowance",
    "AddNftAllowance",
    "BatchTransaction",
    "ConsensusPubSub",
    "ConsensusPubSubChunked",
    "ConsensusPubSubWithSubmitKey",
    "CreateAccount",
    "CreateAccountThresholdKey",
    "CreateAccountWithAlias",
    "CreateFile",
    "CreateSimpleContract",
    "CreateStatefulContract",
    "CreateTopic",
    "CreateTopicWithRevenue",
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
    "InitializeClientWithMirrorNetwork",
    "LongTermScheduledTransaction",
    "MirrorNodeContractQuery",
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
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        .library(name: "Hiero", targets: ["Hiero"])
    ],
    dependencies: [
        .package(url: "https://github.com/objecthub/swift-numberkit.git", from: "2.5.1"),
        .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "1.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.23.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.29.0"),
        .package(url: "https://github.com/vsanthanam/AnyAsyncSequence.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.1.0"),
        // swift-asn1 wants swift 5.7+ past 0.4
        .package(url: "https://github.com/apple/swift-asn1.git", .upToNextMinor(from: "1.3.1")),
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift.git", .upToNextMinor(from: "0.12.0")),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.101.3"),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.2.0"),
        // Currently, only used for keccak256
        .package(url: "https://github.com/krzyzanowskim/OpenSSL-Package.git", from: "3.3.2000"),
    ],
    targets: [
        .target(
            name: "HieroProtobufs",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "GRPC", package: "grpc-swift"),
            ],
            exclude: [
                "Protos",
                "update_protos.py",
            ]
        ),
        // weird name, but whatever, internal targets
        .target(
            name: "HieroExampleUtilities",
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
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "secp256k1", package: "secp256k1.swift"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "OpenSSL", package: "OpenSSL-Package"),
            ]
            // todo: find some way to enable these locally.
            // swiftSettings: [
            //     .unsafeFlags(["-Xfrontend", "-warn-concurrency", "-Xfrontend", "-enable-actor-data-race-checks"])
            // ]
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
