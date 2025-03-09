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

import HieroProtobufs

extension Transaction {
    internal static func fromProtobuf(
        _ firstBody: Proto_TransactionBody,
        _ data: [Proto_TransactionBody.OneOf_Data]
    ) throws -> Transaction {
        func intoOnlyValue<Element>(_ array: [Element]) throws -> Element {
            guard array.count == 1 else {
                throw HError.fromProtobuf("chunks in non chunkable transaction")
            }

            return array[0]
        }

        let data = try ServicesTransactionDataList.fromProtobuf(data)

        switch data {
        case .accountCreate(let value):
            let value = try intoOnlyValue(value)
            return try AccountCreateTransaction(protobuf: firstBody, value)

        case .accountUpdate(let value):
            let value = try intoOnlyValue(value)
            return try AccountUpdateTransaction(protobuf: firstBody, value)

        case .accountDelete(let value):
            let value = try intoOnlyValue(value)
            return try AccountDeleteTransaction(protobuf: firstBody, value)

        case .accountAllowanceApprove(let value):
            let value = try intoOnlyValue(value)
            return try AccountAllowanceApproveTransaction(protobuf: firstBody, value)

        case .accountAllowanceDelete(let value):
            let value = try intoOnlyValue(value)
            return try AccountAllowanceDeleteTransaction(protobuf: firstBody, value)

        case .contractCreate(let value):
            let value = try intoOnlyValue(value)
            return try ContractCreateTransaction(protobuf: firstBody, value)

        case .contractUpdate(let value):
            let value = try intoOnlyValue(value)
            return try ContractUpdateTransaction(protobuf: firstBody, value)

        case .contractDelete(let value):
            let value = try intoOnlyValue(value)
            return try ContractDeleteTransaction(protobuf: firstBody, value)

        case .contractExecute(let value):
            let value = try intoOnlyValue(value)
            return try ContractExecuteTransaction(protobuf: firstBody, value)

        case .transfer(let value):
            let value = try intoOnlyValue(value)
            return try TransferTransaction(protobuf: firstBody, value)

        case .topicCreate(let value):
            let value = try intoOnlyValue(value)
            return try TopicCreateTransaction(protobuf: firstBody, value)

        case .topicUpdate(let value):
            let value = try intoOnlyValue(value)
            return try TopicUpdateTransaction(protobuf: firstBody, value)

        case .topicDelete(let value):
            let value = try intoOnlyValue(value)
            return try TopicDeleteTransaction(protobuf: firstBody, value)

        case .topicMessageSubmit(let value):
            return try TopicMessageSubmitTransaction(protobuf: firstBody, value)

        case .fileAppend(let value):
            return try FileAppendTransaction(protobuf: firstBody, value)

        case .fileCreate(let value):
            let value = try intoOnlyValue(value)
            return try FileCreateTransaction(protobuf: firstBody, value)

        case .fileUpdate(let value):
            let value = try intoOnlyValue(value)
            return try FileUpdateTransaction(protobuf: firstBody, value)

        case .fileDelete(let value):
            let value = try intoOnlyValue(value)
            return try FileDeleteTransaction(protobuf: firstBody, value)

        case .tokenAssociate(let value):
            let value = try intoOnlyValue(value)
            return try TokenAssociateTransaction(protobuf: firstBody, value)

        case .tokenBurn(let value):
            let value = try intoOnlyValue(value)
            return try TokenBurnTransaction(protobuf: firstBody, value)

        case .tokenCreate(let value):
            let value = try intoOnlyValue(value)
            return try TokenCreateTransaction(protobuf: firstBody, value)

        case .tokenDelete(let value):
            let value = try intoOnlyValue(value)
            return try TokenDeleteTransaction(protobuf: firstBody, value)

        case .tokenDissociate(let value):
            let value = try intoOnlyValue(value)
            return try TokenDissociateTransaction(protobuf: firstBody, value)

        case .tokenFeeScheduleUpdate(let value):
            let value = try intoOnlyValue(value)
            return try TokenFeeScheduleUpdateTransaction(protobuf: firstBody, value)

        case .tokenFreeze(let value):
            let value = try intoOnlyValue(value)
            return try TokenFreezeTransaction(protobuf: firstBody, value)

        case .tokenGrantKyc(let value):
            let value = try intoOnlyValue(value)
            return try TokenGrantKycTransaction(protobuf: firstBody, value)

        case .tokenMint(let value):
            let value = try intoOnlyValue(value)
            return try TokenMintTransaction(protobuf: firstBody, value)

        case .tokenPause(let value):
            let value = try intoOnlyValue(value)
            return try TokenPauseTransaction(protobuf: firstBody, value)

        case .tokenRevokeKyc(let value):
            let value = try intoOnlyValue(value)
            return try TokenRevokeKycTransaction(protobuf: firstBody, value)

        case .tokenUnfreeze(let value):
            let value = try intoOnlyValue(value)
            return try TokenUnfreezeTransaction(protobuf: firstBody, value)

        case .tokenUnpause(let value):
            let value = try intoOnlyValue(value)
            return try TokenUnpauseTransaction(protobuf: firstBody, value)

        case .tokenUpdate(let value):
            let value = try intoOnlyValue(value)
            return try TokenUpdateTransaction(protobuf: firstBody, value)

        case .tokenWipe(let value):
            let value = try intoOnlyValue(value)
            return try TokenWipeTransaction(protobuf: firstBody, value)

        case .systemDelete(let value):
            let value = try intoOnlyValue(value)
            return try SystemDeleteTransaction(protobuf: firstBody, value)

        case .systemUndelete(let value):
            let value = try intoOnlyValue(value)
            return try SystemUndeleteTransaction(protobuf: firstBody, value)

        case .freeze(let value):
            let value = try intoOnlyValue(value)
            return try FreezeTransaction(protobuf: firstBody, value)

        case .scheduleCreate(let value):
            let value = try intoOnlyValue(value)
            return try ScheduleCreateTransaction(protobuf: firstBody, value)

        case .scheduleSign(let value):
            let value = try intoOnlyValue(value)
            return try ScheduleSignTransaction(protobuf: firstBody, value)

        case .scheduleDelete(let value):
            let value = try intoOnlyValue(value)
            return try ScheduleDeleteTransaction(protobuf: firstBody, value)

        case .ethereum(let value):
            let value = try intoOnlyValue(value)
            return try EthereumTransaction(protobuf: firstBody, value)

        case .prng(let value):
            let value = try intoOnlyValue(value)
            return try PrngTransaction(protobuf: firstBody, value)

        case .tokenUpdateNfts(let value):
            let value = try intoOnlyValue(value)
            return try TokenUpdateNftsTransaction(protobuf: firstBody, value)

        case .tokenReject(let value):
            let value = try intoOnlyValue(value)
            return try TokenRejectTransaction(protobuf: firstBody, value)

        case .nodeCreate(let value):
            let value = try intoOnlyValue(value)
            return try NodeCreateTransaction(protobuf: firstBody, value)

        case .nodeUpdate(let value):
            let value = try intoOnlyValue(value)
            return try NodeUpdateTransaction(protobuf: firstBody, value)

        case .nodeDelete(let value):
            let value = try intoOnlyValue(value)
            return try NodeDeleteTransaction(protobuf: firstBody, value)

        case .tokenAirdrop(let value):
            let value = try intoOnlyValue(value)
            return try TokenAirdropTransaction(protobuf: firstBody, value)

        case .tokenClaimAirdrop(let value):
            let value = try intoOnlyValue(value)
            return try TokenClaimAirdropTransaction(protobuf: firstBody, value)

        case .tokenCancelAirdrop(let value):
            let value = try intoOnlyValue(value)
            return try TokenCancelAirdropTransaction(protobuf: firstBody, value)

        case .stateSignatureTransaction(let code):
            throw HError.fromProtobuf("unrecognized: stateSignatureTransaction `\(code)`")

        case .historyProofSignature(let code):
            throw HError.fromProtobuf("unrecognized: historyProofSignature `\(code)`")

        case .historyProofKeyPublication(let code):
            throw HError.fromProtobuf("unrecognized: historyProofKeyPublication `\(code)`")

        case .historyProofVote(let code):
            throw HError.fromProtobuf("unrecognized: historyProofVote `\(code)`")
        }
    }
}
