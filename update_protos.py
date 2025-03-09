import subprocess
from typing import List
import os
import shutil
from pathlib import Path
import glob

def find_proto_file(filename: str, search_dir: str) -> str:
    """
    Search for a proto file in the source directory and its subdirectories.
    Returns the full path if found, empty string if not found.
    """
    for root, _, files in os.walk(search_dir):
        if filename in files:
            return os.path.join(root, filename)
    return ""

def ensure_directory_exists(directory: str):
    Path(directory).mkdir(parents=True, exist_ok=True)

def organize_proto_files(source_base: str, dest_base: str, proto_files: List[str]):
    print("\nOrganizing .proto files")
    
    # Track which files were successfully copied
    copied_files = []
    
    for proto_file in proto_files:
        if proto_file.startswith(("sdk/", "mirror/")):
            continue
            
        # Find the file in source directory
        found_path = find_proto_file(os.path.basename(proto_file), source_base)
        if not found_path:
            print(f"  Warning: {proto_file} not found")
            continue
            
        # Find destination path
        if "/" in proto_file:
            dest_path = os.path.join(dest_base, proto_file)
        else:
            dest_path = os.path.join(dest_base, proto_file)
            
        # Create destination directory if needed
        dest_dir = os.path.dirname(dest_path)
        ensure_directory_exists(dest_dir)
        
        try:
            shutil.copy2(found_path, dest_path)
            copied_files.append(proto_file)
        except Exception as e:
            print(f"  Error copying {proto_file}: {e}")
            
    return copied_files

def run_protoc_protobuf(proto_files: List[str]):
    cmd = [
        "protoc",
        "--swift_opt=Visibility=Public",
        "--swift_opt=FileNaming=FullPath",
        "--swift_out=./Sources/HieroProtobufs/Services",
        "--proto_path=./Sources/HieroProtobufs/Protos"
    ] + proto_files
    
    print(f"\nGenerating Swift protobuf code for {len(proto_files)} files:")
    for file in proto_files:
        print(f"  - {file}")
    
    try:
        subprocess.run(cmd, check=True)
        print("\nProtobufs generated successfully.")
    except subprocess.CalledProcessError as e:
        print(f"\nError during protobuf generation: {e}")

def run_protoc_grpc(proto_files: List[str]):
    cmd = [
        "protoc",
        "--grpc-swift_opt=Visibility=Public",
        "--grpc-swift_out=./Sources/HieroProtobufs/Services",
        "--proto_path=./Sources/HieroProtobufs/Protos"
    ] + proto_files
    
    for file in proto_files:
        print(f"  - {file}")
    
    try:
        subprocess.run(cmd, check=True)
        print("\ngRPC services generated successfully.")
    except subprocess.CalledProcessError as e:
        print(f"\nError during gRPC generation: {e}")

if __name__ == "__main__":
    # Source and destination directories
    SOURCE_DIR = "protobufs/hapi/hedera-protobufs"
    DEST_DIR = "Sources/HieroProtobufs/Protos"
    
    files_to_generate = [
        "address_book_service.proto",
        "basic_types.proto",
        "consensus_create_topic.proto",
        "consensus_delete_topic.proto",
        "consensus_get_topic_info.proto",
        "consensus_service.proto",
        "consensus_submit_message.proto",
        "consensus_topic_info.proto",
        "consensus_update_topic.proto",
        "contract_call.proto",
        "contract_call_local.proto",
        "contract_create.proto",
        "contract_delete.proto",
        "contract_get_bytecode.proto",
        "contract_get_info.proto",
        "contract_get_records.proto",
        "contract_update.proto",
        "contract_types.proto",
        "crypto_add_live_hash.proto",
        "crypto_approve_allowance.proto",
        "crypto_create.proto",
        "crypto_delete.proto",
        "crypto_delete_allowance.proto",
        "crypto_delete_live_hash.proto",
        "crypto_get_account_balance.proto",
        "crypto_get_account_records.proto",
        "crypto_get_info.proto",
        "crypto_get_live_hash.proto",
        "crypto_get_stakers.proto",
        "crypto_service.proto",
        "crypto_transfer.proto",
        "crypto_update.proto",
        "custom_fees.proto",
        "duration.proto",
        "ethereum_transaction.proto",
        "exchange_rate.proto",
        "file_append.proto",
        "file_create.proto",
        "file_delete.proto",
        "file_get_contents.proto",
        "file_get_info.proto",
        "file_service.proto",
        "file_update.proto",
        "freeze.proto",
        "freeze_service.proto",
        "freeze_type.proto",
        "get_account_details.proto",
        "get_by_key.proto",
        "get_by_solidity_id.proto",
        "network_get_execution_time.proto",
        "network_get_version_info.proto",
        "network_service.proto",
        "node_create.proto",
        "node_delete.proto",
        "node_stake_update.proto",
        "node_update.proto",
        "query.proto",
        "query_header.proto",
        "response.proto",
        "response_code.proto",
        "response_header.proto",
        "schedulable_transaction_body.proto",
        "schedule_create.proto",
        "schedule_delete.proto",
        "schedule_get_info.proto",
        "schedule_service.proto",
        "schedule_sign.proto",
        "smart_contract_service.proto",
        "system_delete.proto",
        "system_undelete.proto",
        "throttle_definitions.proto",
        "timestamp.proto",
        "token_airdrop.proto",
        "token_associate.proto",
        "token_burn.proto",
        "token_cancel_airdrop.proto",
        "token_claim_airdrop.proto",
        "token_create.proto",
        "token_delete.proto",
        "token_dissociate.proto",
        "token_fee_schedule_update.proto",
        "token_freeze_account.proto",
        "token_get_account_nft_infos.proto",
        "token_get_info.proto",
        "token_get_nft_info.proto",
        "token_get_nft_infos.proto",
        "token_grant_kyc.proto",
        "token_mint.proto",
        "token_pause.proto",
        "token_reject.proto",
        "token_revoke_kyc.proto",
        "token_service.proto",
        "token_unfreeze_account.proto",
        "token_unpause.proto",
        "token_update.proto",
        "token_update_nfts.proto",
        "token_wipe_account.proto",
        "transaction.proto",
        "transaction_contents.proto",
        "transaction_get_fast_record.proto",
        "transaction_get_receipt.proto",
        "transaction_get_record.proto",
        "transaction_receipt.proto",
        "transaction_record.proto",
        "transaction_response.proto",
        "unchecked_submit.proto",
        "util_prng.proto",
        "util_service.proto",

        "sdk/transaction_list.proto",

        # Auxiliary files
        "auxiliary/history/history_proof_signature.proto",
        "auxiliary/history/history_proof_key_publication.proto",
        "auxiliary/history/history_proof_vote.proto",
        "auxiliary/history/history_assembly_signature.proto",
        "auxiliary/tss/tss_message.proto",
        "auxiliary/tss/tss_vote.proto",

        "event/state_signature_transaction.proto",

        "state/history/history_types.proto",

        "mirror/consensus_service.proto",
        "mirror/mirror_network_service.proto"
    ]
    
    successfully_copied = organize_proto_files(SOURCE_DIR, DEST_DIR, files_to_generate)
    
    if successfully_copied:
        # Generate protobuf code
        run_protoc_protobuf(successfully_copied)
        
        # Generate gRPC code
        run_protoc_grpc(successfully_copied)
    else:
        print("\nNo files were copied successfully. Cannot generate code.")
