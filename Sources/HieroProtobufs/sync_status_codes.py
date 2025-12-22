#!/usr/bin/env python3
"""
Synchronizes Status.swift with response_code.proto.

This script:
1. Parses response_code.proto to extract all ResponseCodeEnum values
2. Parses Status.swift to find existing status codes  
3. Generates Swift code for any missing status codes
4. Updates comments and deprecated status for existing codes
5. Updates Status.swift in all required sections

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
from typing import List, Dict, Optional, Tuple


@dataclass
class StatusCode:
    """Represents a status code from the proto file."""
    name: str           # e.g., "INVALID_TRANSACTION"
    code: int           # e.g., 1
    comment: str        # e.g., "For any error not handled by specific error codes listed below."
    deprecated: bool    # Whether the code is marked as deprecated


@dataclass
class SwiftStatusCode:
    """Represents a status code parsed from the Swift file."""
    swift_name: str     # e.g., "invalidTransaction"
    code: int           # e.g., 1
    comment: str        # The doc comment (without /// prefix)
    deprecated: bool    # Whether marked as deprecated in comment
    line_start: int     # Line number where comment starts (or case line if no comment)
    line_end: int       # Line number where case declaration ends


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
    """Parse Status.swift to find existing status codes (code -> swift_name mapping)."""
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


def parse_swift_comments(swift_path: str, verbose: bool = False) -> Dict[int, SwiftStatusCode]:
    """Parse Status.swift to extract comments for each status code."""
    with open(swift_path, 'r') as f:
        lines = f.readlines()
    
    codes: Dict[int, SwiftStatusCode] = {}
    
    # Pattern for case declaration with code comment
    case_pattern = r'^\s*case\s+(\w+)\s*//\s*=\s*(\d+)'
    
    i = 0
    while i < len(lines):
        line = lines[i]
        match = re.match(case_pattern, line)
        
        if match:
            swift_name = match.group(1)
            code = int(match.group(2))
            
            # Look backwards for doc comment
            comment_lines = []
            comment_start = i
            j = i - 1
            
            while j >= 0:
                prev_line = lines[j].strip()
                if prev_line.startswith('///'):
                    comment_text = prev_line[3:].strip()
                    comment_lines.insert(0, comment_text)
                    comment_start = j
                    j -= 1
                elif prev_line == '' or prev_line.startswith('case '):
                    break
                else:
                    break
            
            full_comment = ' '.join(comment_lines)
            deprecated = full_comment.startswith('[Deprecated]')
            
            # Remove [Deprecated] prefix for comparison
            clean_comment = full_comment
            if deprecated:
                clean_comment = full_comment[len('[Deprecated]'):].strip()
            
            codes[code] = SwiftStatusCode(
                swift_name=swift_name,
                code=code,
                comment=clean_comment,
                deprecated=deprecated,
                line_start=comment_start,
                line_end=i
            )
        
        i += 1
    
    if verbose:
        print(f"Parsed comments for {len(codes)} status codes")
    
    return codes


def find_comment_updates(proto_codes: List[StatusCode], 
                         swift_comments: Dict[int, SwiftStatusCode],
                         verbose: bool = False) -> List[Tuple[StatusCode, SwiftStatusCode]]:
    """Find status codes that need comment or deprecated status updates."""
    updates = []
    
    for proto_code in proto_codes:
        if proto_code.code not in swift_comments:
            continue
        
        swift_code = swift_comments[proto_code.code]
        
        # Check if comment differs
        proto_comment = proto_code.comment.strip()
        swift_comment = swift_code.comment.strip()
        
        comment_differs = proto_comment != swift_comment
        deprecated_differs = proto_code.deprecated != swift_code.deprecated
        
        if comment_differs or deprecated_differs:
            if verbose:
                if comment_differs:
                    print(f"  Comment differs for {proto_code.code}:")
                    print(f"    Proto: {proto_comment[:60]}...")
                    print(f"    Swift: {swift_comment[:60]}...")
                if deprecated_differs:
                    print(f"  Deprecated status differs for {proto_code.code}: "
                          f"proto={proto_code.deprecated}, swift={swift_code.deprecated}")
            updates.append((proto_code, swift_code))
    
    return updates


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


def _apply_comment_updates(content: str, updates: List[Tuple[StatusCode, SwiftStatusCode]], 
                           verbose: bool) -> str:
    """Update comments for existing status codes."""
    lines = content.split('\n')
    
    # Sort updates by line number in reverse order to avoid index shifting
    sorted_updates = sorted(updates, key=lambda x: x[1].line_start, reverse=True)
    
    for proto_code, swift_code in sorted_updates:
        _log_verbose(verbose, f"Updating comment for {swift_code.swift_name} (code {proto_code.code})")
        
        # Build new comment
        if proto_code.comment:
            if proto_code.deprecated:
                new_comment = f"    /// [Deprecated] {proto_code.comment}"
            else:
                new_comment = f"    /// {proto_code.comment}"
        elif proto_code.deprecated:
            new_comment = "    /// [Deprecated]"
        else:
            new_comment = None
        
        # Find the case line
        case_line_idx = swift_code.line_end
        
        # Remove old comment lines (from line_start to line before case)
        if swift_code.line_start < swift_code.line_end:
            # There are comment lines to remove
            del lines[swift_code.line_start:swift_code.line_end]
            case_line_idx = swift_code.line_start
        
        # Insert new comment before case line
        if new_comment:
            lines.insert(case_line_idx, new_comment)
    
    return '\n'.join(lines)


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
                      comment_updates: List[Tuple[StatusCode, SwiftStatusCode]],
                      dry_run: bool = False, verbose: bool = False) -> bool:
    """Update Status.swift with missing status codes and comment updates."""
    if not missing_codes and not comment_updates:
        print("No updates needed.")
        return True
    
    with open(swift_path, 'r') as f:
        content = f.read()
    
    # Apply comment updates first (before adding new codes changes line numbers)
    if comment_updates:
        content = _apply_comment_updates(content, comment_updates, verbose)
    
    # Then apply missing codes
    if missing_codes:
        content = _apply_swift_updates(content, missing_codes, verbose)
    
    if dry_run:
        print("\n[DRY RUN] Would update Status.swift with the following changes:")
        if missing_codes:
            print(f"  - Add {len(missing_codes)} new status code(s)")
        if comment_updates:
            print(f"  - Update {len(comment_updates)} comment(s)/deprecated status(es)")
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
    swift_comments = parse_swift_comments(swift_path, args.verbose)
    
    print(f"Proto file: {len(proto_codes)} status codes")
    print(f"Swift file: {len(swift_codes)} status codes")
    print()
    
    # Find missing codes
    missing = find_missing_codes(proto_codes, swift_codes)
    
    # Find comment/deprecated updates
    comment_updates = find_comment_updates(proto_codes, swift_comments, args.verbose)
    
    if not missing and not comment_updates:
        print("✓ Status.swift is in sync with response_code.proto")
        print("No updates needed.")
        sys.exit(0)
    
    # Report missing codes
    if missing:
        print(f"Found {len(missing)} missing status code(s):")
        for code in missing:
            print(f"  - {proto_to_swift_case(code.name)} ({code.code})")
        print()
    
    # Report comment updates
    if comment_updates:
        print(f"Found {len(comment_updates)} comment/deprecated update(s):")
        for proto_code, swift_code in comment_updates:
            print(f"  - {swift_code.swift_name} ({proto_code.code})")
        print()
    
    success = update_swift_file(swift_path, missing, comment_updates, args.dry_run, args.verbose)
    
    if success:
        if args.dry_run:
            print("\n[DRY RUN] No files were modified.")
        else:
            changes = []
            if missing:
                changes.append(f"{len(missing)} new status code(s)")
            if comment_updates:
                changes.append(f"{len(comment_updates)} comment update(s)")
            print(f"\n✓ Status.swift updated successfully with {', '.join(changes)}!")
        sys.exit(0)
    else:
        print("\n✗ Failed to update Status.swift")
        sys.exit(1)


if __name__ == "__main__":
    main()
