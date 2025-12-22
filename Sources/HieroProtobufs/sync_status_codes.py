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
from typing import List, Dict, Optional


@dataclass
class StatusCode:
    """Represents a status code from the proto file."""
    name: str           # e.g., "INVALID_TRANSACTION"
    code: int           # e.g., 1
    comment: str        # e.g., "For any error not handled by specific error codes listed below."
    deprecated: bool    # Whether the code is marked as deprecated


# Acronyms that need special casing in Swift
# ID stays uppercase (e.g., invalidFileID), TX uses Title Case (e.g., insufficientTxFee)
ACRONYM_MAPPINGS = {
    'ID': 'ID',
    'IPV4': 'Ipv4',
    'FQDN': 'Fqdn',
    'NFT': 'Nft',
    'KYC': 'Kyc',
    'GRPC': 'Grpc',
    'LCM': 'Lcm',
}


def proto_to_swift_case(proto_name: str) -> str:
    """
    Convert PROTO_SNAKE_CASE to swiftCamelCase.
    
    Examples:
        OK -> ok
        INVALID_TRANSACTION -> invalidTransaction
        INVALID_FILE_ID -> invalidFileID (ID stays uppercase)
        INSUFFICIENT_TX_FEE -> insufficientTxFee (TX uses Title Case)
    """
    if proto_name == "OK":
        return "ok"
    
    parts = proto_name.split('_')
    result_parts = [parts[0].lower()]
    
    for part in parts[1:]:
        result_parts.append(ACRONYM_MAPPINGS.get(part, part.capitalize()))
    
    return ''.join(result_parts)


def _extract_block_comment_text(line: str) -> str:
    """Extract text from a single-line block comment."""
    return re.sub(r'/\*\*?\s*|\s*\*/', '', line).strip()


def _process_comment_line(line: str, current_comment: List[str]) -> bool:
    """Process a comment line and return True if it was a comment."""
    # Block comment start
    if line.startswith('/*'):
        current_comment.clear()
        comment_text = _extract_block_comment_text(line) if '*/' in line else ''
        if comment_text:
            current_comment.append(comment_text)
        return True
    
    # Inside block comment
    if line.startswith('*'):
        comment_text = line.lstrip('* ').rstrip()
        is_valid = comment_text and comment_text != '/'
        if is_valid:
            current_comment.append(comment_text)
        return True
    
    # Single line comment
    if line.startswith('//'):
        current_comment.append(line.lstrip('/ ').strip())
        return True
    
    return False


def _parse_enum_value(line: str, current_comment: List[str]) -> Optional[StatusCode]:
    """Parse an enum value line and return StatusCode if matched."""
    enum_pattern = r'^(\w+)\s*=\s*(\d+)\s*(?:\[deprecated\s*=\s*true\])?\s*;?\s*(?://\s*(.*))?$'
    match = re.match(enum_pattern, line)
    
    if not match:
        return None
    
    name = match.group(1)
    code = int(match.group(2))
    inline_comment = match.group(3)
    deprecated = 'deprecated' in line.lower()
    
    comment = ' '.join(current_comment)
    if inline_comment:
        comment = f"{comment} {inline_comment}".strip() if comment else inline_comment
    
    return StatusCode(name=name, code=code, comment=comment.strip(), deprecated=deprecated)


def parse_proto_file(proto_path: str, verbose: bool = False) -> List[StatusCode]:
    """Parse response_code.proto to extract all status codes."""
    if verbose:
        print(f"Reading proto file: {proto_path}")
    
    with open(proto_path, 'r') as f:
        content = f.read()
    
    enum_match = re.search(r'enum\s+ResponseCodeEnum\s*\{(.*?)\}', content, re.DOTALL)
    if not enum_match:
        print("Error: Could not find ResponseCodeEnum in proto file")
        return []
    
    codes = []
    current_comment: List[str] = []
    
    for line in enum_match.group(1).split('\n'):
        line = line.strip()
        
        if not line:
            current_comment.clear()
            continue
        
        if _process_comment_line(line, current_comment):
            continue
        
        status_code = _parse_enum_value(line, current_comment)
        if status_code:
            codes.append(status_code)
            current_comment.clear()
    
    if verbose:
        print(f"Found {len(codes)} status codes in proto file")
    
    return codes


def parse_swift_status_codes(swift_path: str, verbose: bool = False) -> Dict[int, str]:
    """Parse Status.swift to find existing status codes."""
    if verbose:
        print(f"Reading Swift file: {swift_path}")
    
    with open(swift_path, 'r') as f:
        content = f.read()
    
    codes = {}
    init_pattern = r'case\s+(\d+):\s*self\s*=\s*\.(\w+)'
    
    for match in re.finditer(init_pattern, content):
        codes[int(match.group(1))] = match.group(2)
    
    if verbose:
        print(f"Found {len(codes)} status codes in Swift file")
    
    return codes


def find_missing_codes(proto_codes: List[StatusCode], swift_codes: Dict[int, str]) -> List[StatusCode]:
    """Find status codes that are in proto but not in Swift."""
    missing = [pc for pc in proto_codes if pc.code not in swift_codes]
    return sorted(missing, key=lambda x: x.code)


def generate_case_declaration(status: StatusCode) -> str:
    """Generate Swift enum case declaration with doc comment."""
    swift_name = proto_to_swift_case(status.name)
    lines = []
    
    if status.comment:
        comment = f"[Deprecated] {status.comment}" if status.deprecated else status.comment
        lines.append(f"    /// {comment}")
    elif status.deprecated:
        lines.append("    /// [Deprecated]")
    
    lines.append(f"    case {swift_name}  // = {status.code}")
    return '\n'.join(lines)


def generate_init_case(status: StatusCode) -> str:
    """Generate init(rawValue:) case line."""
    return f"        case {status.code}: self = .{proto_to_swift_case(status.name)}"


def generate_raw_value_case(status: StatusCode) -> str:
    """Generate rawValue property case line."""
    return f"        case .{proto_to_swift_case(status.name)}: return {status.code}"


def generate_all_cases_entry(status: StatusCode) -> str:
    """Generate allCases array entry."""
    return f"        .{proto_to_swift_case(status.name)},"


def generate_name_map_entry(status: StatusCode) -> str:
    """Generate nameMap dictionary entry."""
    return f'            {status.code}: "{status.name}",'


def _insert_before_marker(content: str, marker: str, new_content: str, section_name: str) -> str:
    """Insert new content before a marker in the file content."""
    if marker in content:
        return content.replace(marker, new_content + '\n' + marker)
    print(f"Warning: Could not find insertion point for {section_name}")
    return content


def _insert_before_pattern(content: str, pattern: str, new_content: str, 
                           replacement_suffix: str, section_name: str) -> str:
    """Insert new content before a regex pattern match."""
    match = re.search(pattern, content)
    if match:
        old_ending = match.group(0)
        new_ending = new_content + replacement_suffix
        return content.replace(old_ending, new_ending)
    print(f"Warning: Could not find insertion point for {section_name}")
    return content


def _log_verbose(verbose: bool, message: str) -> None:
    """Print message if verbose mode is enabled."""
    if verbose:
        print(message)


def _apply_swift_updates(content: str, missing_codes: List[StatusCode], verbose: bool) -> str:
    """Apply all Swift file updates and return modified content."""
    # 1. Add enum case declarations
    _log_verbose(verbose, "Adding enum case declarations...")
    case_declarations = '\n\n'.join(generate_case_declaration(c) for c in missing_codes)
    marker = "    /// swift-format-ignore: AlwaysUseLowerCamelCase\n    case unrecognized(Int32)"
    content = _insert_before_marker(content, marker, case_declarations + '\n', "case declarations")
    
    # 2. Add init(rawValue:) cases
    _log_verbose(verbose, "Adding init(rawValue:) cases...")
    init_cases = '\n'.join(generate_init_case(c) for c in missing_codes)
    content = _insert_before_marker(content, "        default: self = .unrecognized(rawValue)", 
                                    init_cases, "init cases")
    
    # 3. Add rawValue cases
    _log_verbose(verbose, "Adding rawValue cases...")
    raw_value_cases = '\n'.join(generate_raw_value_case(c) for c in missing_codes)
    content = _insert_before_marker(content, "        case .unrecognized(let i): return i",
                                    raw_value_cases, "rawValue cases")
    
    # 4. Add allCases entries
    _log_verbose(verbose, "Adding allCases entries...")
    all_cases_entries = '\n'.join(generate_all_cases_entry(c) for c in missing_codes)
    content = _insert_before_pattern(
        content,
        r'(    \]\n\})\n\n// minimal edit from proto-generated file:',
        all_cases_entries,
        '\n    ]\n}\n\n// minimal edit from proto-generated file:',
        "allCases entries"
    )
    
    # 5. Add nameMap entries
    _log_verbose(verbose, "Adding nameMap entries...")
    name_map_entries = '\n'.join(generate_name_map_entry(c) for c in missing_codes)
    content = _insert_before_pattern(
        content,
        r'(        \]\n\})\n\nextension Status: Sendable',
        name_map_entries,
        '\n        ]\n}\n\nextension Status: Sendable',
        "nameMap entries"
    )
    
    return content


def _write_file_with_backup(swift_path: str, content: str, verbose: bool) -> bool:
    """Write content to file with backup/restore on failure."""
    backup_path = swift_path + '.bak'
    if verbose:
        print(f"Creating backup at {backup_path}")
    shutil.copy2(swift_path, backup_path)
    
    try:
        with open(swift_path, 'w') as f:
            f.write(content)
        if verbose:
            print("Successfully wrote updated Status.swift")
        os.remove(backup_path)
        if verbose:
            print("Removed backup file")
        return True
    except Exception as e:
        print(f"Error writing file: {e}")
        print("Restoring from backup...")
        shutil.copy2(backup_path, swift_path)
        os.remove(backup_path)
        return False


def update_swift_file(swift_path: str, missing_codes: List[StatusCode], 
                      dry_run: bool = False, verbose: bool = False) -> bool:
    """Update Status.swift with missing status codes."""
    if not missing_codes:
        print("No missing codes to add.")
        return True
    
    with open(swift_path, 'r') as f:
        content = f.read()
    
    content = _apply_swift_updates(content, missing_codes, verbose)
    
    if dry_run:
        print("\n[DRY RUN] Would update Status.swift with the following changes:")
        print(f"  - Add {len(missing_codes)} enum case declarations")
        print(f"  - Add {len(missing_codes)} init(rawValue:) cases")
        print(f"  - Add {len(missing_codes)} rawValue cases")
        print(f"  - Add {len(missing_codes)} allCases entries")
        print(f"  - Add {len(missing_codes)} nameMap entries")
        return True
    
    return _write_file_with_backup(swift_path, content, verbose)


def main():
    parser = argparse.ArgumentParser(
        description='Synchronize Status.swift with response_code.proto'
    )
    parser.add_argument('--dry-run', action='store_true',
                        help='Preview changes without modifying files')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Show detailed output')
    
    args = parser.parse_args()
    
    script_dir = os.path.dirname(os.path.abspath(__file__))
    proto_path = os.path.normpath(os.path.join(script_dir, 'Protos', 'services', 'response_code.proto'))
    swift_path = os.path.normpath(os.path.join(script_dir, '..', 'Hiero', 'Status.swift'))
    
    print("Synchronizing Status.swift with response_code.proto...")
    if args.dry_run:
        print("[DRY RUN MODE]")
    print()
    
    if not os.path.exists(proto_path):
        print(f"Error: Proto file not found: {proto_path}")
        sys.exit(1)
    
    if not os.path.exists(swift_path):
        print(f"Error: Swift file not found: {swift_path}")
        sys.exit(1)
    
    proto_codes = parse_proto_file(proto_path, args.verbose)
    swift_codes = parse_swift_status_codes(swift_path, args.verbose)
    
    print(f"Proto file: {len(proto_codes)} status codes")
    print(f"Swift file: {len(swift_codes)} status codes")
    print()
    
    missing = find_missing_codes(proto_codes, swift_codes)
    
    if not missing:
        print("✓ Status.swift is in sync with response_code.proto")
        print("No updates needed.")
        sys.exit(0)
    
    print(f"Found {len(missing)} missing status code(s):")
    for code in missing:
        print(f"  - {proto_to_swift_case(code.name)} ({code.code})")
    print()
    
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
