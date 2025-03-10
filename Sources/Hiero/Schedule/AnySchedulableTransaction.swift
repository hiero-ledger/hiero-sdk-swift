// SPDX-License-Identifier: Apache-2.0

import HieroProtobufs

internal enum AnySchedulableTransaction {
    case accountCreate(AccountCreateTransaction)
    case accountUpdate(AccountUpdateTransaction)
    case accountDelete(AccountDeleteTransaction)
    case accountAllowanceApprove(AccountAllowanceApproveTransaction)
    case accountAllowanceDelete(AccountAllowanceDeleteTransaction)
    case contractCreate(ContractCreateTransaction)
    case contractUpdate(ContractUpdateTransaction)
    case contractDelete(ContractDeleteTransaction)
    case contractExecute(ContractExecuteTransaction)
    case transfer(TransferTransaction)
    case topicCreate(TopicCreateTransaction)
    case topicUpdate(TopicUpdateTransaction)
    case topicDelete(TopicDeleteTransaction)
    case topicMessageSubmit(TopicMessageSubmitTransaction)
    case fileAppend(FileAppendTransaction)
    case fileCreate(FileCreateTransaction)
    case fileUpdate(FileUpdateTransaction)
    case fileDelete(FileDeleteTransaction)
    case tokenAssociate(TokenAssociateTransaction)
    case tokenBurn(TokenBurnTransaction)
    case tokenCreate(TokenCreateTransaction)
    case tokenDelete(TokenDeleteTransaction)
    case tokenDissociate(TokenDissociateTransaction)
    case tokenFeeScheduleUpdate(TokenFeeScheduleUpdateTransaction)
    case tokenFreeze(TokenFreezeTransaction)
    case tokenGrantKyc(TokenGrantKycTransaction)
    case tokenMint(TokenMintTransaction)
    case tokenPause(TokenPauseTransaction)
    case tokenRevokeKyc(TokenRevokeKycTransaction)
    case tokenUnfreeze(TokenUnfreezeTransaction)
    case tokenUnpause(TokenUnpauseTransaction)
    case tokenUpdate(TokenUpdateTransaction)
    case tokenWipe(TokenWipeTransaction)
    case systemDelete(SystemDeleteTransaction)
    case systemUndelete(SystemUndeleteTransaction)
    case freeze(FreezeTransaction)
    case scheduleDelete(ScheduleDeleteTransaction)
    case prng(PrngTransaction)

    internal init(upcasting transaction: Transaction) {
        switch transaction {
        case let transaction as AccountCreateTransaction: self = .accountCreate(transaction)
        case let transaction as AccountUpdateTransaction: self = .accountUpdate(transaction)
        case let transaction as AccountDeleteTransaction: self = .accountDelete(transaction)
        case let transaction as AccountAllowanceApproveTransaction: self = .accountAllowanceApprove(transaction)
        case let transaction as AccountAllowanceDeleteTransaction: self = .accountAllowanceDelete(transaction)
        case let transaction as ContractCreateTransaction: self = .contractCreate(transaction)
        case let transaction as ContractUpdateTransaction: self = .contractUpdate(transaction)
        case let transaction as ContractDeleteTransaction: self = .contractDelete(transaction)
        case let transaction as ContractExecuteTransaction: self = .contractExecute(transaction)
        case let transaction as TransferTransaction: self = .transfer(transaction)
        case let transaction as TopicCreateTransaction: self = .topicCreate(transaction)
        case let transaction as TopicUpdateTransaction: self = .topicUpdate(transaction)
        case let transaction as TopicDeleteTransaction: self = .topicDelete(transaction)
        case let transaction as TopicMessageSubmitTransaction: self = .topicMessageSubmit(transaction)
        case let transaction as FileAppendTransaction: self = .fileAppend(transaction)
        case let transaction as FileCreateTransaction: self = .fileCreate(transaction)
        case let transaction as FileUpdateTransaction: self = .fileUpdate(transaction)
        case let transaction as FileDeleteTransaction: self = .fileDelete(transaction)
        case let transaction as PrngTransaction: self = .prng(transaction)
        case let transaction as TokenAssociateTransaction: self = .tokenAssociate(transaction)
        case let transaction as TokenBurnTransaction: self = .tokenBurn(transaction)
        case let transaction as TokenCreateTransaction: self = .tokenCreate(transaction)
        case let transaction as TokenDeleteTransaction: self = .tokenDelete(transaction)
        case let transaction as TokenDissociateTransaction: self = .tokenDissociate(transaction)
        case let transaction as TokenFeeScheduleUpdateTransaction: self = .tokenFeeScheduleUpdate(transaction)
        case let transaction as TokenFreezeTransaction: self = .tokenFreeze(transaction)
        case let transaction as TokenGrantKycTransaction: self = .tokenGrantKyc(transaction)
        case let transaction as TokenMintTransaction: self = .tokenMint(transaction)
        case let transaction as TokenPauseTransaction: self = .tokenPause(transaction)
        case let transaction as TokenRevokeKycTransaction: self = .tokenRevokeKyc(transaction)
        case let transaction as TokenUnfreezeTransaction: self = .tokenUnfreeze(transaction)
        case let transaction as TokenUnpauseTransaction: self = .tokenUnpause(transaction)
        case let transaction as TokenUpdateTransaction: self = .tokenUpdate(transaction)
        case let transaction as TokenWipeTransaction: self = .tokenWipe(transaction)
        case let transaction as SystemDeleteTransaction: self = .systemDelete(transaction)
        case let transaction as SystemUndeleteTransaction: self = .systemUndelete(transaction)
        case let transaction as FreezeTransaction: self = .freeze(transaction)
        case let transaction as ScheduleDeleteTransaction: self = .scheduleDelete(transaction)
        case is ScheduleCreateTransaction, is ScheduleSignTransaction, is EthereumTransaction:
            fatalError("Cannot schedule `\(type(of: transaction))`")
        default: fatalError("Unrecognized transaction type: \(type(of: transaction))")
        }
    }
}

extension AnySchedulableTransaction {
    internal var transaction: Transaction {
        switch self {
        case .accountCreate(let transaction):
            return transaction
        case .accountUpdate(let transaction):
            return transaction
        case .accountDelete(let transaction):
            return transaction
        case .accountAllowanceApprove(let transaction):
            return transaction
        case .accountAllowanceDelete(let transaction):
            return transaction
        case .contractCreate(let transaction):
            return transaction
        case .contractUpdate(let transaction):
            return transaction
        case .contractDelete(let transaction):
            return transaction
        case .contractExecute(let transaction):
            return transaction
        case .transfer(let transaction):
            return transaction
        case .topicCreate(let transaction):
            return transaction
        case .topicUpdate(let transaction):
            return transaction
        case .topicDelete(let transaction):
            return transaction
        case .topicMessageSubmit(let transaction):
            return transaction
        case .fileAppend(let transaction):
            return transaction
        case .fileCreate(let transaction):
            return transaction
        case .fileUpdate(let transaction):
            return transaction
        case .fileDelete(let transaction):
            return transaction
        case .tokenAssociate(let transaction):
            return transaction
        case .tokenBurn(let transaction):
            return transaction
        case .tokenCreate(let transaction):
            return transaction
        case .tokenDelete(let transaction):
            return transaction
        case .tokenDissociate(let transaction):
            return transaction
        case .tokenFeeScheduleUpdate(let transaction):
            return transaction
        case .tokenFreeze(let transaction):
            return transaction
        case .tokenGrantKyc(let transaction):
            return transaction
        case .tokenMint(let transaction):
            return transaction
        case .tokenPause(let transaction):
            return transaction
        case .tokenRevokeKyc(let transaction):
            return transaction
        case .tokenUnfreeze(let transaction):
            return transaction
        case .tokenUnpause(let transaction):
            return transaction
        case .tokenUpdate(let transaction):
            return transaction
        case .tokenWipe(let transaction):
            return transaction
        case .systemDelete(let transaction):
            return transaction
        case .systemUndelete(let transaction):
            return transaction
        case .freeze(let transaction):
            return transaction
        case .scheduleDelete(let transaction):
            return transaction
        case .prng(let transaction):
            return transaction
        }
    }
}

extension AnySchedulableTransaction {
    internal func toSchedulableTransactionData() -> Proto_SchedulableTransactionBody.OneOf_Data {
        switch self {
        case .accountCreate(let transaction): return transaction.toSchedulableTransactionData()
        case .accountUpdate(let transaction): return transaction.toSchedulableTransactionData()
        case .accountDelete(let transaction): return transaction.toSchedulableTransactionData()
        case .accountAllowanceApprove(let transaction): return transaction.toSchedulableTransactionData()
        case .accountAllowanceDelete(let transaction): return transaction.toSchedulableTransactionData()
        case .contractCreate(let transaction): return transaction.toSchedulableTransactionData()
        case .contractUpdate(let transaction): return transaction.toSchedulableTransactionData()
        case .contractDelete(let transaction): return transaction.toSchedulableTransactionData()
        case .contractExecute(let transaction): return transaction.toSchedulableTransactionData()
        case .transfer(let transaction): return transaction.toSchedulableTransactionData()
        case .topicCreate(let transaction): return transaction.toSchedulableTransactionData()
        case .topicUpdate(let transaction): return transaction.toSchedulableTransactionData()
        case .topicDelete(let transaction): return transaction.toSchedulableTransactionData()
        case .topicMessageSubmit(let transaction): return transaction.toSchedulableTransactionData()
        case .fileAppend(let transaction): return transaction.toSchedulableTransactionData()
        case .fileCreate(let transaction): return transaction.toSchedulableTransactionData()
        case .fileUpdate(let transaction): return transaction.toSchedulableTransactionData()
        case .fileDelete(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenAssociate(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenBurn(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenCreate(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenDelete(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenDissociate(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenFeeScheduleUpdate(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenFreeze(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenGrantKyc(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenMint(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenPause(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenRevokeKyc(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenUnfreeze(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenUnpause(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenUpdate(let transaction): return transaction.toSchedulableTransactionData()
        case .tokenWipe(let transaction): return transaction.toSchedulableTransactionData()
        case .systemDelete(let transaction): return transaction.toSchedulableTransactionData()
        case .systemUndelete(let transaction): return transaction.toSchedulableTransactionData()
        case .freeze(let transaction): return transaction.toSchedulableTransactionData()
        case .scheduleDelete(let transaction): return transaction.toSchedulableTransactionData()
        case .prng(let transaction): return transaction.toSchedulableTransactionData()
        }
    }

}
