/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
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

import HieroProtobufs

// exists for the same reason as rust and still sucks :/\
internal enum ServicesTransactionDataList {
    case accountCreate([Proto_CryptoCreateTransactionBody])
    case accountUpdate([Proto_CryptoUpdateTransactionBody])
    case accountDelete([Proto_CryptoDeleteTransactionBody])
    case accountAllowanceApprove([Proto_CryptoApproveAllowanceTransactionBody])
    case accountAllowanceDelete([Proto_CryptoDeleteAllowanceTransactionBody])
    case contractCreate([Proto_ContractCreateTransactionBody])
    case contractUpdate([Proto_ContractUpdateTransactionBody])
    case contractDelete([Proto_ContractDeleteTransactionBody])
    case contractExecute([Proto_ContractCallTransactionBody])
    case transfer([Proto_CryptoTransferTransactionBody])
    case topicCreate([Proto_ConsensusCreateTopicTransactionBody])
    case topicUpdate([Proto_ConsensusUpdateTopicTransactionBody])
    case topicDelete([Proto_ConsensusDeleteTopicTransactionBody])
    case topicMessageSubmit([Proto_ConsensusSubmitMessageTransactionBody])
    case fileAppend([Proto_FileAppendTransactionBody])
    case fileCreate([Proto_FileCreateTransactionBody])
    case fileUpdate([Proto_FileUpdateTransactionBody])
    case fileDelete([Proto_FileDeleteTransactionBody])
    case tokenAssociate([Proto_TokenAssociateTransactionBody])
    case tokenBurn([Proto_TokenBurnTransactionBody])
    case tokenCreate([Proto_TokenCreateTransactionBody])
    case tokenDelete([Proto_TokenDeleteTransactionBody])
    case tokenDissociate([Proto_TokenDissociateTransactionBody])
    case tokenFeeScheduleUpdate([Proto_TokenFeeScheduleUpdateTransactionBody])
    case tokenFreeze([Proto_TokenFreezeAccountTransactionBody])
    case tokenGrantKyc([Proto_TokenGrantKycTransactionBody])
    case tokenMint([Proto_TokenMintTransactionBody])
    case tokenPause([Proto_TokenPauseTransactionBody])
    case tokenRevokeKyc([Proto_TokenRevokeKycTransactionBody])
    case tokenReject([Proto_TokenRejectTransactionBody])
    case tokenUnfreeze([Proto_TokenUnfreezeAccountTransactionBody])
    case tokenUnpause([Proto_TokenUnpauseTransactionBody])
    case tokenUpdate([Proto_TokenUpdateTransactionBody])
    case tokenWipe([Proto_TokenWipeAccountTransactionBody])
    case systemDelete([Proto_SystemDeleteTransactionBody])
    case systemUndelete([Proto_SystemUndeleteTransactionBody])
    case freeze([Proto_FreezeTransactionBody])
    case scheduleCreate([Proto_ScheduleCreateTransactionBody])
    case scheduleSign([Proto_ScheduleSignTransactionBody])
    case scheduleDelete([Proto_ScheduleDeleteTransactionBody])
    case ethereum([Proto_EthereumTransactionBody])
    case prng([Proto_UtilPrngTransactionBody])
    case tokenUpdateNfts([Proto_TokenUpdateNftsTransactionBody])
    case nodeCreate([Com_Hedera_Hapi_Node_Addressbook_NodeCreateTransactionBody])
    case nodeUpdate([Com_Hedera_Hapi_Node_Addressbook_NodeUpdateTransactionBody])
    case nodeDelete([Com_Hedera_Hapi_Node_Addressbook_NodeDeleteTransactionBody])
    case tokenAirdrop([Proto_TokenAirdropTransactionBody])
    case tokenClaimAirdrop([Proto_TokenClaimAirdropTransactionBody])
    case tokenCancelAirdrop([Proto_TokenCancelAirdropTransactionBody])

    internal mutating func append(_ transaction: Proto_TransactionBody.OneOf_Data) throws {
        switch (self, transaction) {
        case (.accountCreate(var array), .cryptoCreateAccount(let data)):
            array.append(data)
            self = .accountCreate(array)

        case (.accountUpdate(var array), .cryptoUpdateAccount(let data)):
            array.append(data)
            self = .accountUpdate(array)

        case (.accountDelete(var array), .cryptoDelete(let data)):
            array.append(data)
            self = .accountDelete(array)

        case (.accountAllowanceApprove(var array), .cryptoApproveAllowance(let data)):
            array.append(data)
            self = .accountAllowanceApprove(array)

        case (.accountAllowanceDelete(var array), .cryptoDeleteAllowance(let data)):
            array.append(data)
            self = .accountAllowanceDelete(array)

        case (.contractCreate(var array), .contractCreateInstance(let data)):
            array.append(data)
            self = .contractCreate(array)

        case (.contractUpdate(var array), .contractUpdateInstance(let data)):
            array.append(data)
            self = .contractUpdate(array)

        case (.contractDelete(var array), .contractDeleteInstance(let data)):
            array.append(data)
            self = .contractDelete(array)

        case (.contractExecute(var array), .contractCall(let data)):
            array.append(data)
            self = .contractExecute(array)

        case (.transfer(var array), .cryptoTransfer(let data)):
            array.append(data)
            self = .transfer(array)

        case (.topicCreate(var array), .consensusCreateTopic(let data)):
            array.append(data)
            self = .topicCreate(array)

        case (.topicUpdate(var array), .consensusUpdateTopic(let data)):
            array.append(data)
            self = .topicUpdate(array)

        case (.topicDelete(var array), .consensusDeleteTopic(let data)):
            array.append(data)
            self = .topicDelete(array)

        case (.topicMessageSubmit(var array), .consensusSubmitMessage(let data)):
            array.append(data)
            self = .topicMessageSubmit(array)

        case (.fileAppend(var array), .fileAppend(let data)):
            array.append(data)
            self = .fileAppend(array)

        case (.fileCreate(var array), .fileCreate(let data)):
            array.append(data)
            self = .fileCreate(array)

        case (.fileUpdate(var array), .fileUpdate(let data)):
            array.append(data)
            self = .fileUpdate(array)

        case (.fileDelete(var array), .fileDelete(let data)):
            array.append(data)
            self = .fileDelete(array)

        case (.tokenAssociate(var array), .tokenAssociate(let data)):
            array.append(data)
            self = .tokenAssociate(array)

        case (.tokenBurn(var array), .tokenBurn(let data)):
            array.append(data)
            self = .tokenBurn(array)

        case (.tokenCreate(var array), .tokenCreation(let data)):
            array.append(data)
            self = .tokenCreate(array)

        case (.tokenDelete(var array), .tokenDeletion(let data)):
            array.append(data)
            self = .tokenDelete(array)

        case (.tokenDissociate(var array), .tokenDissociate(let data)):
            array.append(data)
            self = .tokenDissociate(array)

        case (.tokenFeeScheduleUpdate(var array), .tokenFeeScheduleUpdate(let data)):
            array.append(data)
            self = .tokenFeeScheduleUpdate(array)

        case (.tokenFreeze(var array), .tokenFreeze(let data)):
            array.append(data)
            self = .tokenFreeze(array)

        case (.tokenGrantKyc(var array), .tokenGrantKyc(let data)):
            array.append(data)
            self = .tokenGrantKyc(array)

        case (.tokenMint(var array), .tokenMint(let data)):
            array.append(data)
            self = .tokenMint(array)

        case (.tokenPause(var array), .tokenPause(let data)):
            array.append(data)
            self = .tokenPause(array)

        case (.tokenRevokeKyc(var array), .tokenRevokeKyc(let data)):
            array.append(data)
            self = .tokenRevokeKyc(array)

        case (.tokenUnfreeze(var array), .tokenUnfreeze(let data)):
            array.append(data)
            self = .tokenUnfreeze(array)

        case (.tokenUnpause(var array), .tokenUnpause(let data)):
            array.append(data)
            self = .tokenUnpause(array)

        case (.tokenUpdate(var array), .tokenUpdate(let data)):
            array.append(data)
            self = .tokenUpdate(array)

        case (.tokenWipe(var array), .tokenWipe(let data)):
            array.append(data)
            self = .tokenWipe(array)

        case (.systemDelete(var array), .systemDelete(let data)):
            array.append(data)
            self = .systemDelete(array)

        case (.systemUndelete(var array), .systemUndelete(let data)):
            array.append(data)
            self = .systemUndelete(array)

        case (.freeze(var array), .freeze(let data)):
            array.append(data)
            self = .freeze(array)

        case (.scheduleCreate(var array), .scheduleCreate(let data)):
            array.append(data)
            self = .scheduleCreate(array)

        case (.scheduleSign(var array), .scheduleSign(let data)):
            array.append(data)
            self = .scheduleSign(array)

        case (.scheduleDelete(var array), .scheduleDelete(let data)):
            array.append(data)
            self = .scheduleDelete(array)

        case (.ethereum(var array), .ethereumTransaction(let data)):
            array.append(data)
            self = .ethereum(array)

        case (.prng(var array), .utilPrng(let data)):
            array.append(data)
            self = .prng(array)

        case (.tokenUpdateNfts(var array), .tokenUpdateNfts(let data)):
            array.append(data)
            self = .tokenUpdateNfts(array)

        case (.tokenReject(var array), .tokenReject(let data)):
            array.append(data)
            self = .tokenReject(array)

        case (.nodeCreate(var array), .nodeCreate(let data)):
            array.append(data)
            self = .nodeCreate(array)

        case (.nodeUpdate(var array), .nodeUpdate(let data)):
            array.append(data)
            self = .nodeUpdate(array)

        case (.nodeDelete(var array), .nodeDelete(let data)):
            array.append(data)
            self = .nodeDelete(array)

        case (.tokenAirdrop(var array), .tokenAirdrop(let data)):
            array.append(data)
            self = .tokenAirdrop(array)

        case (.tokenClaimAirdrop(var array), .tokenClaimAirdrop(let data)):
            array.append(data)
            self = .tokenClaimAirdrop(array)

        case (.tokenCancelAirdrop(var array), .tokenCancelAirdrop(let data)):
            array.append(data)
            self = .tokenCancelAirdrop(array)

        default:
            throw HError.fromProtobuf("mismatched transaction types")
        }
    }
}

extension ServicesTransactionDataList: TryFromProtobuf {
    internal typealias Protobuf = [Proto_TransactionBody.OneOf_Data]

    // swiftlint:disable:next function_body_length
    internal init(protobuf proto: Protobuf) throws {
        var iter = proto.makeIterator()

        let first = iter.next()!

        var value: Self

        switch first {
        case .contractCall(let data): value = .contractExecute([data])
        case .contractCreateInstance(let data): value = .contractCreate([data])
        case .contractUpdateInstance(let data): value = .contractUpdate([data])
        case .contractDeleteInstance(let data): value = .contractDelete([data])
        case .ethereumTransaction(let data): value = .ethereum([data])
        case .cryptoApproveAllowance(let data): value = .accountAllowanceApprove([data])
        case .cryptoDeleteAllowance(let data): value = .accountAllowanceDelete([data])
        case .cryptoCreateAccount(let data): value = .accountCreate([data])
        case .cryptoDelete(let data): value = .accountDelete([data])
        case .cryptoTransfer(let data): value = .transfer([data])
        case .cryptoUpdateAccount(let data): value = .accountUpdate([data])
        case .fileAppend(let data): value = .fileAppend([data])
        case .fileCreate(let data): value = .fileCreate([data])
        case .fileDelete(let data): value = .fileDelete([data])
        case .fileUpdate(let data): value = .fileUpdate([data])
        case .systemDelete(let data): value = .systemDelete([data])
        case .systemUndelete(let data): value = .systemUndelete([data])
        case .freeze(let data): value = .freeze([data])
        case .consensusCreateTopic(let data): value = .topicCreate([data])
        case .consensusUpdateTopic(let data): value = .topicUpdate([data])
        case .consensusDeleteTopic(let data): value = .topicDelete([data])
        case .consensusSubmitMessage(let data): value = .topicMessageSubmit([data])
        case .tokenCreation(let data): value = .tokenCreate([data])
        case .tokenFreeze(let data): value = .tokenFreeze([data])
        case .tokenUnfreeze(let data): value = .tokenUnfreeze([data])
        case .tokenGrantKyc(let data): value = .tokenGrantKyc([data])
        case .tokenRevokeKyc(let data): value = .tokenRevokeKyc([data])
        case .tokenDeletion(let data): value = .tokenDelete([data])
        case .tokenUpdate(let data): value = .tokenUpdate([data])
        case .tokenMint(let data): value = .tokenMint([data])
        case .tokenBurn(let data): value = .tokenBurn([data])
        case .tokenWipe(let data): value = .tokenWipe([data])
        case .tokenAssociate(let data): value = .tokenAssociate([data])
        case .tokenDissociate(let data): value = .tokenDissociate([data])
        case .tokenFeeScheduleUpdate(let data): value = .tokenFeeScheduleUpdate([data])
        case .tokenPause(let data): value = .tokenPause([data])
        case .tokenUnpause(let data): value = .tokenUnpause([data])
        case .scheduleCreate(let data): value = .scheduleCreate([data])
        case .scheduleDelete(let data): value = .scheduleDelete([data])
        case .scheduleSign(let data): value = .scheduleSign([data])
        case .utilPrng(let data): value = .prng([data])
        case .tokenUpdateNfts(let data): value = .tokenUpdateNfts([data])
        case .cryptoAddLiveHash: throw HError.fromProtobuf("Unsupported transaction `AddLiveHashTransaction`")
        case .cryptoDeleteLiveHash: throw HError.fromProtobuf("Unsupported transaction `DeleteLiveHashTransaction`")
        case .uncheckedSubmit: throw HError.fromProtobuf("Unsupported transaction `UncheckedSubmitTransaction`")
        case .nodeStakeUpdate: throw HError.fromProtobuf("Unsupported transaction `NodeStakeUpdateTransaction`")
        case .nodeCreate(let data): value = .nodeCreate([data])
        case .nodeUpdate(let data): value = .nodeUpdate([data])
        case .nodeDelete(let data): value = .nodeDelete([data])
        case .tokenReject(let data): value = .tokenReject([data])
        case .tokenAirdrop(let data): value = .tokenAirdrop([data])
        case .tokenCancelAirdrop(let data): value = .tokenCancelAirdrop([data])
        case .tokenClaimAirdrop(let data): value = .tokenClaimAirdrop([data])
        case .tssMessage(_):
            throw HError.fromProtobuf("Unsupported transaction `TssMessageTransaction`")
        case .tssVote(_):
            throw HError.fromProtobuf("Unsupported transaction `TssVoteTransaction`")
        case .tssShareSignature(_):
            throw HError.fromProtobuf("Unsupported transaction `TssShareSignatureTransaction`")
        }

        for transaction in iter {
            try value.append(transaction)
        }

        self = value
    }
}
