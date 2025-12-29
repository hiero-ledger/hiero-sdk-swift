import subprocess
from typing import List, Optional
import os
import shutil
from pathlib import Path
import glob
import shlex
from subprocess import CompletedProcess
from enum import Enum, auto

class ProtoDirectory(Enum):
    MIRROR: str = "Mirror"
    PLATFORM: str = "Platform"
    SDK: str = "Sdk"
    SERVICES: str = "Services"
    STREAMS: str = "Streams"
    
    def __str__(self):
        return self.value

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
    
    try:
        # Create destination directory if it doesn't exist
        os.makedirs(dest_base, exist_ok=True)
        
        # Process each file in the files_to_generate list
        for proto_file in proto_files:
            # Construct source and destination paths
            source_file = os.path.join(source_base, proto_file)
            dest_file = os.path.join(dest_base, proto_file)
            
            # Skip if source file doesn't exist
            if not os.path.exists(source_file):
                print(f"Warning: Source file not found: {source_file}")
                continue
                
            # Create subdirectories if needed
            os.makedirs(os.path.dirname(dest_file), exist_ok=True)
            
            # Copy the file
            try:
                shutil.copy2(source_file, dest_file)
                copied_files.append(proto_file)
                print(f"Copied: {proto_file}")
            except Exception as e:
                print(f"Error copying {proto_file}: {e}")
                    
    except Exception as e:
        print(f"Error during organization: {e}")
    
    return copied_files

def run_protoc_protobuf(proto_files: List[str]) -> Optional[CompletedProcess]:
    # Validate input
    if not all(proto_file.endswith('.proto') for proto_file in proto_files):
        print("Error: Invalid proto file detected")
        return None

    # Create output directory if it doesn't exist
    os.makedirs(f"./Generated", exist_ok=True)
        
    cmd = [
        "protoc",
        "--swift_opt=Visibility=Public",
        "--swift_opt=FileNaming=FullPath",
        f"--swift_out=./Generated",
        "--proto_path=./Protos"
    ] + proto_files  # Remove shlex.quote as it's causing issues with the file paths
    
    print(f"\nGenerating Swift protobuf code for {len(proto_files)} files:")
    for file in proto_files:
        print(f"  - {file}")
    
    try:
        return subprocess.run(cmd, check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f"\nError during protobuf generation: {e}")
        if e.stderr:
            print(f"Stderr: {e.stderr}")
        return None

def run_protoc_grpc(proto_files: List[str]):
    # Create output directory if it doesn't exist
    os.makedirs(f"./Generated", exist_ok=True)

    cmd = [
        "protoc",
        "--grpc-swift_opt=Visibility=Public",
        f"--grpc-swift_out=./Generated",
        "--proto_path=./Protos"
    ] + proto_files  # Remove the quotes here as well
    
    print(f"\nGenerating gRPC code for {len(proto_files)} files:")
    for file in proto_files:
        print(f"  - {file}")
    
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print("\ngRPC services generated successfully.")
        return result
    except subprocess.CalledProcessError as e:
        print(f"\nError during gRPC generation: {e}")
        if e.stderr:
            print(f"Stderr: {e.stderr}")
        return None

if __name__ == "__main__":
    # Source and destination directories
    SOURCE_DIR = "../../protobufs/hapi/hedera-protobuf-java-api/src/main/proto"
    DEST_DIR = "Protos"
    
    files_to_generate = [
        "services/address_book_service.proto",
        "services/basic_types.proto",
        "services/consensus_create_topic.proto",
        "services/consensus_delete_topic.proto",
        "services/consensus_get_topic_info.proto",
        "services/consensus_service.proto",
        "services/consensus_submit_message.proto",
        "services/consensus_topic_info.proto",
        "services/consensus_update_topic.proto",
        "services/contract_call_local.proto",
        "services/contract_call.proto",
        "services/contract_create.proto",
        "services/contract_delete.proto",
        "services/contract_get_bytecode.proto",
        "services/contract_get_info.proto",
        "services/contract_get_records.proto",
        "services/contract_types.proto",
        "services/contract_update.proto",
        "services/crypto_add_live_hash.proto",
        "services/crypto_approve_allowance.proto",
        "services/crypto_create.proto",
        "services/crypto_delete_allowance.proto",
        "services/crypto_delete_live_hash.proto",
        "services/crypto_delete.proto",
        "services/crypto_get_account_balance.proto",
        "services/crypto_get_account_records.proto",
        "services/crypto_get_info.proto",
        "services/crypto_get_live_hash.proto",
        "services/crypto_get_stakers.proto",
        "services/crypto_service.proto",
        "services/crypto_transfer.proto",
        "services/crypto_update.proto",
        "services/custom_fees.proto",
        "services/duration.proto",
        "services/ethereum_transaction.proto",
        "services/exchange_rate.proto",
        "services/file_append.proto",
        "services/file_create.proto",
        "services/file_delete.proto",
        "services/file_get_contents.proto",
        "services/file_get_info.proto",
        "services/file_service.proto",
        "services/file_update.proto",
        "services/freeze_service.proto",
        "services/freeze_type.proto",
        "services/freeze.proto",
        "services/get_account_details.proto",
        "services/get_by_key.proto",
        "services/get_by_solidity_id.proto",
        "services/hook_dispatch.proto",
        "services/hook_types.proto",
        "services/lambda_sstore.proto",
        "services/network_get_execution_time.proto",
        "services/network_get_version_info.proto",
        "services/network_service.proto",
        "services/node_create.proto",
        "services/node_delete.proto",
        "services/node_stake_update.proto",
        "services/node_update.proto",
        "services/query_header.proto",
        "services/query.proto",
        "services/response_code.proto",
        "services/response_header.proto",
        "services/response.proto",
        "services/schedulable_transaction_body.proto",
        "services/schedule_create.proto",
        "services/schedule_delete.proto",
        "services/schedule_get_info.proto",
        "services/schedule_service.proto",
        "services/schedule_sign.proto",
        "services/smart_contract_service.proto",
        "services/system_delete.proto",
        "services/system_undelete.proto",
        "services/throttle_definitions.proto",
        "services/timestamp.proto",
        "services/token_airdrop.proto",
        "services/token_associate.proto",
        "services/token_burn.proto",
        "services/token_cancel_airdrop.proto",
        "services/token_claim_airdrop.proto",
        "services/token_create.proto",
        "services/token_delete.proto",
        "services/token_dissociate.proto",
        "services/token_fee_schedule_update.proto",
        "services/token_freeze_account.proto",
        "services/token_get_account_nft_infos.proto",
        "services/token_get_info.proto",
        "services/token_get_nft_info.proto",
        "services/token_get_nft_infos.proto",
        "services/token_grant_kyc.proto",
        "services/token_mint.proto",
        "services/token_pause.proto",
        "services/token_reject.proto",
        "services/token_revoke_kyc.proto",
        "services/token_service.proto",
        "services/token_unfreeze_account.proto",
        "services/token_unpause.proto",
        "services/token_update_nfts.proto",
        "services/token_update.proto",
        "services/token_wipe_account.proto",
        "services/transaction_contents.proto",
        "services/transaction_get_fast_record.proto",
        "services/transaction_get_receipt.proto",
        "services/transaction_get_record.proto",
        "services/transaction_receipt.proto",
        "services/transaction_record.proto",
        "services/transaction_response.proto",
        "services/transaction.proto",
        "services/unchecked_submit.proto",
        "services/util_prng.proto",
        "services/util_service.proto",

        "sdk/transaction_list.proto",

        # Auxiliary files
        "services/auxiliary/history/history_proof_signature.proto",
        "services/auxiliary/history/history_proof_key_publication.proto",
        "services/auxiliary/history/history_proof_vote.proto",
        "services/auxiliary/tss/tss_message.proto",
        "services/auxiliary/tss/tss_vote.proto",
        "services/auxiliary/hints/hints_preprocessing_vote.proto",
        "services/auxiliary/hints/hints_partial_signature.proto",
        "services/auxiliary/hints/crs_publication.proto",
        "services/auxiliary/hints/hints_key_publication.proto",
        "services/state/hints/hints_types.proto",
        "services/state/history/history_types.proto",
        
        "platform/event/state_signature_transaction.proto",
        "block/stream/chain_of_trust_proof.proto",

        "mirror/mirror_network_service.proto",

        "block/stream/chain_of_trust_proof.proto"
    ]
    
    successfully_copied = organize_proto_files(SOURCE_DIR, DEST_DIR, files_to_generate)
    
    if successfully_copied:
        # Generate protobuf code
        services_result = run_protoc_protobuf(successfully_copied)
        
        if services_result:
            print("\nProtobufs generated successfully.")
        else:
            print("\nNo files were copied successfully. Cannot generate code.")
        
        # Generate gRPC code
        run_protoc_grpc(successfully_copied)
    else:
        print("\nNo files were copied successfully. Cannot generate code.")

