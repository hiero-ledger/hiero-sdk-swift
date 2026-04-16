// SPDX-License-Identifier: Apache-2.0

import Foundation
import Hiero

/// Shared test constants used across unit tests
public enum TestConstants {

    /// Standard test node account IDs
    public static let nodeAccountIds: [AccountId] = [5005, 5006]

    /// Standard test valid start timestamp
    public static let validStart = Timestamp(seconds: 1_554_158_542, subSecondNanos: 0)

    /// Standard test transaction ID
    public static var transactionId: TransactionId {
        TransactionId.withValidStart(AccountId(num: 5006), validStart)
    }

    // MARK: - Test Keys

    /// Standard test private key (unused in production, safe for tests)
    public static let privateKey: PrivateKey =
        "302e020100300506032b657004220420db484b828e64b2d8f12ce3c0a0e93a0b8cce7af1bb8f39c97732394482538e10"

    /// Standard test public key (derived from privateKey)
    public static var publicKey: PublicKey {
        privateKey.publicKey
    }

    // MARK: - Entity IDs

    /// Standard test account ID
    public static let accountId = AccountId("0.0.5009")

    /// Standard test file ID
    public static let fileId = FileId("1.2.3")

    /// Standard test token ID
    public static let tokenId = TokenId("0.3.5")

    /// Standard test topic ID
    public static let topicId = TopicId("4.4.4")

    /// Standard test schedule ID
    public static let scheduleId = ScheduleId("0.0.555")

    /// Standard test contract ID
    public static let contractId = ContractId("0.0.789")

    /// Standard test metadata
    public static let metadata = Data([3, 4])

    /// Standard test memo
    public static let memo = "test memo"

    /// Standard initial balance
    public static let initialBalance = Hbar.fromTinybars(1000)

    /// Standard max transaction fee
    public static let maxTransactionFee = Hbar.fromTinybars(100_000)

    /// Standard auto-renew period
    public static let autoRenewPeriod = Duration.hours(10)

    /// Standard transaction valid duration
    public static let transactionValidDuration = Duration.seconds(120)

    /// Standard test token name
    public static let tokenName = "ffff"

    /// Standard test token symbol
    public static let tokenSymbol = "TEST"

    /// Standard gas amount for contract creation (2M gas)
    public static let standardContractGas: UInt64 = 2_000_000

    /// Standard gas amount for contract execution (200K gas)
    public static let contractExecuteGas: UInt64 = 200_000

    /// Standard constructor parameters for contract creation
    public static func standardContractConstructorParameters() -> ContractFunctionParameters {
        ContractFunctionParameters().addString("Hello from Hiero.")
    }

    // MARK: - Integration Test Constants

    /// Standard token transfer amount for integration tests
    public static let testAmount: Int64 = 100

    /// Standard number of NFTs to mint in integration tests
    public static let testMintedNfts: Int64 = 10

    /// Standard initial supply for fungible tokens in integration tests
    public static let testFungibleInitialBalance: UInt64 = 1_000_000

    /// Standard NFT metadata for integration tests
    public static let testMetadata = Array(repeating: Data([9, 1, 6]), count: 10)

    /// Standard token decimals for integration tests
    public static let testTokenDecimals: UInt32 = 3

    /// Standard small initial supply for integration tests
    public static let testSmallInitialSupply: UInt64 = 10

    /// Standard max supply for integration tests
    public static let testMaxSupply: UInt64 = 5000

    /// Standard transfer amount for integration tests (Int64 for tokenTransfer)
    public static let testTransferAmount: Int64 = 10

    /// Standard operation amount for integration tests (UInt64 for burn/wipe/mint)
    public static let testOperationAmount: UInt64 = 10

    /// Unlimited token associations (-1)
    public static let testUnlimitedTokenAssociations: Int32 = -1

    /// No token associations (0)
    public static let testNoTokenAssociations: Int32 = 0

    /// Many token associations (100)
    public static let testManyTokenAssociations: Int32 = 100

    /// Standard small Hbar balance for integration tests
    public static let testSmallHbarBalance = Hbar(1)

    /// Standard medium Hbar balance for integration tests
    public static let testMediumHbarBalance = Hbar(10)

    /// Standard topic memo for integration tests
    public static let standardTopicMemo = "[e2e::TopicCreateTransaction]"

    // MARK: - Contract Bytecode

    /// Standard contract bytecode for testing (stateful contract with getMessage/setMessage).
    ///
    /// This is a simple Solidity contract that stores and retrieves a string message.
    public static let contractBytecode: Data = {
        let bytecodeString = """
            608060405234801561001057600080fd5b506040516104d73803806104d7833981810160405260208110156100\
            3357600080fd5b810190808051604051939291908464010000000082111561005357600080fd5b908301906020\
            82018581111561006857600080fd5b825164010000000081118282018810171561008257600080fd5b82525081\
            516020918201929091019080838360005b838110156100af578181015183820152602001610097565b50505050\
            905090810190601f1680156100dc5780820380516001836020036101000a031916815260200191505b50604052\
            5050600080546001600160a01b0319163317905550805161010890600190602084019061010f565b50506101aa\
            565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f\
            1061015057805160ff191683800117855561017d565b8280016001018555821561017d579182015b8281111561\
            017d578251825591602001919060010190610162565b5061018992915061018d565b5090565b6101a791905b80\
            8211156101895760008155600101610193565b90565b61031e806101b96000396000f3fe608060405234801561\
            001057600080fd5b50600436106100415760003560e01c8063368b87721461004657806341c0e1b5146100ee57\
            8063ce6d41de146100f6575b600080fd5b6100ec6004803603602081101561005c57600080fd5b810190602081\
            01813564010000000081111561007757600080fd5b82018360208201111561008957600080fd5b803590602001\
            918460018302840111640100000000831117156100ab57600080fd5b91908080601f0160208091040260200160\
            405190810160405280939291908181526020018383808284376000920191909152509295506101739450505050\
            50565b005b6100ec6101a2565b6100fe6101ba565b604080516020808252835181830152835191928392908301\
            9185019080838360005b83811015610138578181015183820152602001610120565b5050505090509081019060\
            1f1680156101655780820380516001836020036101000a031916815260200191505b5092505050604051809103\
            90f35b6000546001600160a01b0316331461018a5761019f565b805161019d906001906020840190610250565b\
            505b50565b6000546001600160a01b03163314156101b85733ff5b565b60018054604080516020601f60026000\
            196101008789161502019095169490940493840181900481028201810190925282815260609390929091830182\
            8280156102455780601f1061021a57610100808354040283529160200191610245565b82019190600052602060\
            0020905b81548152906001019060200180831161022857829003601f168201915b505050505090505b90565b82\
            8054600181600116156101000203166002900490600052602060002090601f016020900481019282601f106102\
            9157805160ff19168380011785556102be565b828001600101855582156102be579182015b828111156102be57\
            82518255916020019190600101906102a3565b506102ca9291506102ce565b5090565b61024d91905b80821115\
            6102ca57600081556001016102d456fea264697066735822122084964d4c3f6bc912a9d20e14e449721012d625\
            aa3c8a12de41ae5519752fc89064736f6c63430006000033
            """
        return bytecodeString.data(using: .utf8)!
    }()

    /// Standard EVM hook bytecode for testing.
    ///
    /// This is a Solidity contract implementing the three hook interface functions
    /// (selectors 0x124d8b30, 0x94112e2f, 0xbd0dd0b6), each returning true.
    public static let evmHookBytecode: Data = {
        let bytecodeString =
            "6080604052348015600e575f5ffd5b506107d18061001c5f395ff3fe608060405260043610610033575f3560e0"
            + "1c8063124d8b301461003757806394112e2f14610067578063bd0dd0b614610097575b5f5ffd5b610051600480"
            + "360381019061004c91906106f2565b6100c7565b60405161005e9190610782565b60405180910390f35b610081"
            + "600480360381019061007c91906106f2565b6100d2565b60405161008e9190610782565b60405180910390f35b"
            + "6100b160048036038101906100ac91906106f2565b6100dd565b6040516100be9190610782565b604051809103"
            + "90f35b5f6001905092915050565b5f6001905092915050565b5f6001905092915050565b5f604051905090565b"
            + "5f5ffd5b5f5ffd5b5f5ffd5b5f60a08284031215610112576101116100f9565b5b81905092915050565b5f5ffd"
            + "5b5f601f19601f8301169050919050565b7f4e487b710000000000000000000000000000000000000000000000"
            + "00000000005f52604160045260245ffd5b6101658261011f565b810181811067ffffffffffffffff8211171561"
            + "01845761018361012f565b5b80604052505050565b5f6101966100e8565b90506101a2828261015c565b919050"
            + "565b5f5ffd5b5f5ffd5b5f67ffffffffffffffff8211156101c9576101c861012f565b5b602082029050602081"
            + "019050919050565b5f5ffd5b5f73ffffffffffffffffffffffffffffffffffffffff82169050919050565b5f61"
            + "0207826101de565b9050919050565b610217816101fd565b8114610221575f5ffd5b50565b5f81359050610232"
            + "8161020e565b92915050565b5f8160070b9050919050565b61024d81610238565b8114610257575f5ffd5b5056"
            + "5b5f8135905061026881610244565b92915050565b5f604082840312156102835761028261011b565b5b61028d"
            + "604061018d565b90505f61029c84828501610224565b5f8301525060206102af8482850161025a565b60208301"
            + "525092915050565b5f6102cd6102c8846101af565b61018d565b90508083825260208201905060408402830185"
            + "8111156102f0576102ef6101da565b5b835b818110156103195780610305888261026e565b8452602084019350"
            + "506040810190506102f2565b5050509392505050565b5f82601f830112610337576103366101ab565b5b813561"
            + "03478482602086016102bb565b91505092915050565b5f67ffffffffffffffff82111561036a5761036961012f"
            + "565b5b602082029050602081019050919050565b5f67ffffffffffffffff8211156103955761039461012f565b"
            + "5b602082029050602081019050919050565b5f606082840312156103bb576103ba61011b565b5b6103c5606061"
            + "018d565b90505f6103d484828501610224565b5f8301525060206103e784828501610224565b60208301525060"
            + "406103fb8482850161025a565b60408301525092915050565b5f6104196104148461037b565b61018d565b9050"
            + "808382526020820190506060840283018581111561043c5761043b6101da565b5b835b81811015610465578061"
            + "045188826103a6565b84526020840193505060608101905061043e565b5050509392505050565b5f82601f8301"
            + "12610483576104826101ab565b5b8135610493848260208601610407565b91505092915050565b5f6060828403"
            + "12156104b1576104b061011b565b5b6104bb606061018d565b90505f6104ca84828501610224565b5f83015250"
            + "602082013567ffffffffffffffff8111156104ed576104ec6101a7565b5b6104f984828501610323565b602083"
            + "015250604082013567ffffffffffffffff81111561051d5761051c6101a7565b5b6105298482850161046f565b"
            + "60408301525092915050565b5f61054761054284610350565b61018d565b905080838252602082019050602084"
            + "0283018581111561056a576105696101da565b5b835b818110156105b157803567ffffffffffffffff81111561"
            + "058f5761058e6101ab565b5b80860161059c898261049c565b8552602085019450505060208101905061056c56"
            + "5b5050509392505050565b5f82601f8301126105cf576105ce6101ab565b5b81356105df848260208601610535"
            + "565b91505092915050565b5f604082840312156105fd576105fc61011b565b5b610607604061018d565b90505f"
            + "82013567ffffffffffffffff811115610626576106256101a7565b5b61063284828501610323565b5f83015250"
            + "602082013567ffffffffffffffff811115610655576106546101a7565b5b610661848285016105bb565b602083"
            + "01525092915050565b5f604082840312156106825761068161011b565b5b61068c604061018d565b90505f8201"
            + "3567ffffffffffffffff8111156106ab576106aa6101a7565b5b6106b7848285016105e8565b5f830152506020"
            + "82013567ffffffffffffffff8111156106da576106d96101a7565b5b6106e6848285016105e8565b6020830152"
            + "5092915050565b5f5f60408385031215610708576107076100f1565b5b5f83013567ffffffffffffffff811115"
            + "610725576107246100f5565b5b610731858286016100fd565b925050602083013567ffffffffffffffff811115"
            + "610752576107516100f5565b5b61075e8582860161066d565b9150509250929050565b5f811515905091905056"
            + "5b61077c81610768565b82525050565b5f6020820190506107955f830184610773565b9291505056fea2646970"
            + "6673582212207dfe7723f6d6869419b1cb0619758b439da0cf4ffd9520997c40a3946299d4dc64736f6c634300"
            + "081e0033"
        return hexStringToBytes(bytecodeString)
    }()

    private static func hexStringToBytes(_ hex: String) -> Data {
        let chars = Array(hex.utf8)
        var bytes = [UInt8]()
        bytes.reserveCapacity(chars.count / 2)
        for i in stride(from: 0, to: chars.count, by: 2) {
            let high = hexNibble(chars[i])
            let low = hexNibble(chars[i + 1])
            bytes.append(high << 4 | low)
        }
        return Data(bytes)
    }

    private static func hexNibble(_ c: UInt8) -> UInt8 {
        switch c {
        case UInt8(ascii: "0")...UInt8(ascii: "9"): return c - UInt8(ascii: "0")
        case UInt8(ascii: "a")...UInt8(ascii: "f"): return c - UInt8(ascii: "a") + 10
        case UInt8(ascii: "A")...UInt8(ascii: "F"): return c - UInt8(ascii: "A") + 10
        default: fatalError("Invalid hex character: \(c)")
        }
    }
}
