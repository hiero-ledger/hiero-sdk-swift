#!/usr/bin/env python3
"""
Synchronizes Status.swift with response_code.proto.

This script:
1. Parses response_code.proto to extract all ResponseCodeEnum values
2. Parses Status.swift to find existing status codes  
3. Generates Swift code for any missing status codes
4. Updates Status.swift in all required sections

Usage:
    python3 sync_status_codes.py [--dry-run] [--verbose]

Options:
    --dry-run   Preview changes without modifying files
    --verbose   Show detailed output
"""

import re
import os
import sys
import shutil
import argparse
from dataclasses import dataclass
from typing import List, Dict, Tuple, Optional


@dataclass
class StatusCode:
    """Represents a status code from the proto file."""
    name: str           # e.g., "INVALID_TRANSACTION"
    code: int           # e.g., 1
    comment: str        # e.g., "For any error not handled by specific error codes listed below."
    deprecated: bool    # Whether the code is marked as deprecated


def proto_to_swift_case(proto_name: str) -> str:
    """
    Convert PROTO_SNAKE_CASE to swiftCamelCase.
    
    Special handling for common acronyms to match existing style:
    - ID stays as ID (not Id)
    - NFT stays as Nft in middle, NFT at start stays lowercase nft
    
    Examples:
        OK -> ok
        INVALID_TRANSACTION -> invalidTransaction
        INVALID_FILE_ID -> invalidFileID
        NFT_TRANSFERS_ONLY_ALLOWED -> nftTransfersOnlyAllowed
    """
    # Handle special case for just "OK"
    if proto_name == "OK":
        return "ok"
    
    parts = proto_name.split('_')
    result_parts = []
    
    for i, part in enumerate(parts):
        if i == 0:
            # First part is always lowercase
            result_parts.append(part.lower())
        else:
            # Check for acronyms that should stay uppercase
            if part in ('ID', 'IP', 'TX'):
                result_parts.append(part)
            elif part == 'IPV4':
                result_parts.append('Ipv4')
            elif part == 'FQDN':
                result_parts.append('Fqdn')
            elif part == 'NFT':
                result_parts.append('Nft')
            elif part == 'KYC':
                result_parts.append('Kyc')
            elif part == 'GRPC':
                result_parts.append('Grpc')
            elif part == 'LCM':
                result_parts.append('Lcm')
            else:
                # Standard capitalization
                result_parts.append(part.capitalize())
    
    return ''.join(result_parts)


def parse_proto_file(proto_path: str, verbose: bool = False) -> List[StatusCode]:
    """
    Parse response_code.proto to extract all status codes.
    
    Returns a list of StatusCode objects.
    """
    if verbose:
        print(f"Reading proto file: {proto_path}")
    
    with open(proto_path, 'r') as f:
        content = f.read()
    
    codes = []
    
    # Find the enum block
    enum_match = re.search(r'enum\s+ResponseCodeEnum\s*\{(.*?)\}', content, re.DOTALL)
    if not enum_match:
        print("Error: Could not find ResponseCodeEnum in proto file")
        return codes
    
    enum_content = enum_match.group(1)
    
    # Pattern to match enum values with optional comments and deprecated flag
    # Matches: NAME = 123; or NAME = 123 [deprecated = true]; with preceding comments
    lines = enum_content.split('\n')
    
    current_comment = []
    
    for line in lines:
        line = line.strip()
        
        # Skip empty lines
        if not line:
            current_comment = []
            continue
        
        # Collect multi-line comments
        if line.startswith('/**') or line.startswith('/*'):
            current_comment = []
            # Check if it's a single-line block comment
            if '*/' in line:
                comment_text = re.sub(r'/\*\*?\s*|\s*\*/', '', line).strip()
                if comment_text:
                    current_comment.append(comment_text)
            continue
        
        if line.startswith('*'):
            # Inside a block comment
            comment_text = line.lstrip('* ').rstrip()
            if comment_text and comment_text != '/':
                current_comment.append(comment_text)
            if '*/' in line:
                continue
            continue
        
        # Single line comment
        if line.startswith('//'):
            current_comment.append(line.lstrip('/ ').strip())
            continue
        
        # Try to match an enum value
        # Pattern: NAME = 123; or NAME = 123 [deprecated = true]; // optional inline comment
        enum_pattern = r'^(\w+)\s*=\s*(\d+)\s*(?:\[deprecated\s*=\s*true\])?\s*;?\s*(?://\s*(.*))?$'
        match = re.match(enum_pattern, line)
        
        if match:
            name = match.group(1)
            code = int(match.group(2))
            inline_comment = match.group(3)
            deprecated = 'deprecated' in line.lower()
            
            # Combine comments
            comment = ' '.join(current_comment)
            if inline_comment:
                if comment:
                    comment += ' ' + inline_comment
                else:
                    comment = inline_comment
            
            codes.append(StatusCode(
                name=name,
                code=code,
                comment=comment.strip(),
                deprecated=deprecated
            ))
            
            current_comment = []
    
    if verbose:
        print(f"Found {len(codes)} status codes in proto file")
    
    return codes


def parse_swift_status_codes(swift_path: str, verbose: bool = False) -> Dict[int, str]:
    """
    Parse Status.swift to find existing status codes.
    
    Returns a dict mapping code number to Swift case name.
    """
    if verbose:
        print(f"Reading Swift file: {swift_path}")
    
    with open(swift_path, 'r') as f:
        content = f.read()
    
    codes = {}
    
    # Find the init(rawValue:) section and extract case mappings
    # Pattern: case 123: self = .statusName
    init_pattern = r'case\s+(\d+):\s*self\s*=\s*\.(\w+)'
    
    for match in re.finditer(init_pattern, content):
        code = int(match.group(1))
        name = match.group(2)
        codes[code] = name
    
    if verbose:
        print(f"Found {len(codes)} status codes in Swift file")
    
    return codes


def find_missing_codes(proto_codes: List[StatusCode], swift_codes: Dict[int, str]) -> List[StatusCode]:
    """Find status codes that are in proto but not in Swift."""
    missing = []
    for proto_code in proto_codes:
        if proto_code.code not in swift_codes:
            missing.append(proto_code)
    return sorted(missing, key=lambda x: x.code)


def generate_case_declaration(status: StatusCode) -> str:
    """Generate Swift enum case declaration with doc comment."""
    swift_name = proto_to_swift_case(status.name)
    
    lines = []
    
    # Add doc comment if there's a comment
    if status.comment:
        # Clean up the comment
        comment = status.comment
        if status.deprecated:
            comment = f"[Deprecated] {comment}"
        lines.append(f"    /// {comment}")
    elif status.deprecated:
        lines.append(f"    /// [Deprecated]")
    
    lines.append(f"    case {swift_name}  // = {status.code}")
    
    return '\n'.join(lines)


def generate_init_case(status: StatusCode) -> str:
    """Generate init(rawValue:) case line."""
    swift_name = proto_to_swift_case(status.name)
    return f"        case {status.code}: self = .{swift_name}"


def generate_raw_value_case(status: StatusCode) -> str:
    """Generate rawValue property case line."""
    swift_name = proto_to_swift_case(status.name)
    return f"        case .{swift_name}: return {status.code}"


def generate_all_cases_entry(status: StatusCode) -> str:
    """Generate allCases array entry."""
    swift_name = proto_to_swift_case(status.name)
    return f"        .{swift_name},"


def generate_name_map_entry(status: StatusCode) -> str:
    """Generate nameMap dictionary entry."""
    return f'            {status.code}: "{status.name}",'


def update_swift_file(swift_path: str, missing_codes: List[StatusCode], 
                      dry_run: bool = False, verbose: bool = False) -> bool:
    """
    Update Status.swift with missing status codes.
    
    Returns True if successful, False otherwise.
    """
    if not missing_codes:
        print("No missing codes to add.")
        return True
    
    with open(swift_path, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # 1. Add enum case declarations (before "case unrecognized(Int32)")
    if verbose:
        print("Adding enum case declarations...")
    
    case_declarations = '\n\n'.join(generate_case_declaration(code) for code in missing_codes)
    
    # Find the marker for insertion
    marker = "    /// swift-format-ignore: AlwaysUseLowerCamelCase\n    case unrecognized(Int32)"
    if marker in content:
        content = content.replace(marker, case_declarations + '\n\n' + marker)
    else:
        print("Warning: Could not find insertion point for case declarations")
    
    # 2. Add init(rawValue:) cases (before "default: self = .unrecognized(rawValue)")
    if verbose:
        print("Adding init(rawValue:) cases...")
    
    init_cases = '\n'.join(generate_init_case(code) for code in missing_codes)
    
    init_marker = "        default: self = .unrecognized(rawValue)"
    if init_marker in content:
        content = content.replace(init_marker, init_cases + '\n' + init_marker)
    else:
        print("Warning: Could not find insertion point for init cases")
    
    # 3. Add rawValue cases (before "case .unrecognized(let i): return i")
    if verbose:
        print("Adding rawValue cases...")
    
    raw_value_cases = '\n'.join(generate_raw_value_case(code) for code in missing_codes)
    
    raw_value_marker = "        case .unrecognized(let i): return i"
    if raw_value_marker in content:
        content = content.replace(raw_value_marker, raw_value_cases + '\n' + raw_value_marker)
    else:
        print("Warning: Could not find insertion point for rawValue cases")
    
    # 4. Add allCases entries (before the closing "]" of allCases)
    if verbose:
        print("Adding allCases entries...")
    
    all_cases_entries = '\n'.join(generate_all_cases_entry(code) for code in missing_codes)
    
    # Find the allCases array ending - look for the pattern at the end of allCases
    all_cases_pattern = r'(    \]\n\})\n\n// minimal edit from proto-generated file:'
    all_cases_match = re.search(all_cases_pattern, content)
    if all_cases_match:
        old_ending = all_cases_match.group(0)
        new_ending = all_cases_entries + '\n    ]\n}\n\n// minimal edit from proto-generated file:'
        content = content.replace(old_ending, new_ending)
    else:
        print("Warning: Could not find insertion point for allCases entries")
    
    # 5. Add nameMap entries (before the closing "]" of nameMap)
    if verbose:
        print("Adding nameMap entries...")
    
    name_map_entries = '\n'.join(generate_name_map_entry(code) for code in missing_codes)
    
    # Find the nameMap dictionary ending
    name_map_pattern = r'(        \]\n\})\n\nextension Status: Sendable'
    name_map_match = re.search(name_map_pattern, content)
    if name_map_match:
        old_ending = name_map_match.group(0)
        new_ending = name_map_entries + '\n        ]\n}\n\nextension Status: Sendable'
        content = content.replace(old_ending, new_ending)
    else:
        print("Warning: Could not find insertion point for nameMap entries")
    
    if dry_run:
        print("\n[DRY RUN] Would update Status.swift with the following changes:")
        print(f"  - Add {len(missing_codes)} enum case declarations")
        print(f"  - Add {len(missing_codes)} init(rawValue:) cases")
        print(f"  - Add {len(missing_codes)} rawValue cases")
        print(f"  - Add {len(missing_codes)} allCases entries")
        print(f"  - Add {len(missing_codes)} nameMap entries")
        return True
    
    # Create backup
    backup_path = swift_path + '.bak'
    if verbose:
        print(f"Creating backup at {backup_path}")
    shutil.copy2(swift_path, backup_path)
    
    # Write updated content
    try:
        with open(swift_path, 'w') as f:
            f.write(content)
        
        if verbose:
            print("Successfully wrote updated Status.swift")
        
        # Remove backup on success
        os.remove(backup_path)
        if verbose:
            print("Removed backup file")
        
        return True
        
    except Exception as e:
        print(f"Error writing file: {e}")
        print(f"Restoring from backup...")
        shutil.copy2(backup_path, swift_path)
        os.remove(backup_path)
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Synchronize Status.swift with response_code.proto'
    )
    parser.add_argument('--dry-run', action='store_true',
                        help='Preview changes without modifying files')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Show detailed output')
    
    args = parser.parse_args()
    
    # Determine paths relative to this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    proto_path = os.path.join(script_dir, 'Protos', 'services', 'response_code.proto')
    swift_path = os.path.join(script_dir, '..', 'Hiero', 'Status.swift')
    
    # Normalize paths
    proto_path = os.path.normpath(proto_path)
    swift_path = os.path.normpath(swift_path)
    
    print("Synchronizing Status.swift with response_code.proto...")
    if args.dry_run:
        print("[DRY RUN MODE]")
    print()
    
    # Check files exist
    if not os.path.exists(proto_path):
        print(f"Error: Proto file not found: {proto_path}")
        sys.exit(1)
    
    if not os.path.exists(swift_path):
        print(f"Error: Swift file not found: {swift_path}")
        sys.exit(1)
    
    # Parse files
    proto_codes = parse_proto_file(proto_path, args.verbose)
    swift_codes = parse_swift_status_codes(swift_path, args.verbose)
    
    print(f"Proto file: {len(proto_codes)} status codes")
    print(f"Swift file: {len(swift_codes)} status codes")
    print()
    
    # Find missing codes
    missing = find_missing_codes(proto_codes, swift_codes)
    
    if not missing:
        print("✓ Status.swift is in sync with response_code.proto")
        print("No updates needed.")
        sys.exit(0)
    
    print(f"Found {len(missing)} missing status code(s):")
    for code in missing:
        swift_name = proto_to_swift_case(code.name)
        print(f"  - {swift_name} ({code.code})")
    print()
    
    # Update Swift file
    success = update_swift_file(swift_path, missing, args.dry_run, args.verbose)
    
    if success:
        if args.dry_run:
            print("\n[DRY RUN] No files were modified.")
        else:
            print(f"\n✓ Status.swift updated successfully with {len(missing)} new status code(s)!")
        sys.exit(0)
    else:
        print("\n✗ Failed to update Status.swift")
        sys.exit(1)


if __name__ == "__main__":
    main()
