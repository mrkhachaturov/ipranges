#!/usr/bin/env python3
"""
Fix corrupted IP files and ensure proper CIDR format.
This script cleans up IP files that may contain extra text or malformed content.
"""

import argparse
import os
import re
import glob
from pathlib import Path


def is_valid_cidr(ip_str):
    """Check if a string is a valid CIDR notation."""
    # Remove any whitespace
    ip_str = ip_str.strip()
    
    # Basic CIDR pattern: x.x.x.x/y or x:x:x:x:x:x:x:x/y
    cidr_pattern = r'^(\d{1,3}\.){3}\d{1,3}(/\d{1,2})?$|^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}(/\d{1,3})?$'
    
    if not re.match(cidr_pattern, ip_str):
        return False
    
    # For IPv4, check octet ranges
    if '.' in ip_str:
        parts = ip_str.split('/')[0].split('.')
        for part in parts:
            if not (0 <= int(part) <= 255):
                return False
    
    # For IPv6, basic format check is sufficient
    return True


def clean_ip_file(file_path):
    """Clean an IP file and remove corrupted content."""
    print(f"Cleaning {file_path}...")
    
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return False
    
    cleaned_lines = []
    corrupted_count = 0
    
    for line_num, line in enumerate(lines, 1):
        line = line.strip()
        if not line:
            continue
            
        if is_valid_cidr(line):
            cleaned_lines.append(line)
        else:
            print(f"  Line {line_num}: Removing corrupted content: {line[:50]}...")
            corrupted_count += 1
    
    if corrupted_count > 0:
        print(f"  Removed {corrupted_count} corrupted lines")
        
        # Write cleaned content back
        try:
            with open(file_path, 'w') as f:
                for line in cleaned_lines:
                    f.write(line + '\n')
            print(f"  ✅ Cleaned {file_path}")
            return True
        except Exception as e:
            print(f"  ❌ Error writing {file_path}: {e}")
            return False
    else:
        print(f"  ✅ {file_path} is already clean")
        return False


def main():
    parser = argparse.ArgumentParser(description='Fix corrupted IP files and ensure proper CIDR format')
    parser.add_argument('--file', help='Specific file to fix')
    parser.add_argument('--all', action='store_true', help='Fix all IP files in the project')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be fixed without making changes')
    
    args = parser.parse_args()
    
    if args.dry_run:
        print("DRY RUN MODE - No files will be modified")
    
    if args.file:
        # Fix specific file
        if os.path.exists(args.file):
            if not args.dry_run:
                clean_ip_file(args.file)
            else:
                print(f"Would fix: {args.file}")
        else:
            print(f"File not found: {args.file}")
            return 1
    
    elif args.all:
        # Fix all IP files
        project_root = Path(__file__).parent.parent
        
        # Find all IP files
        ip_files = []
        for pattern in ['**/ipv4.txt', '**/ipv6.txt', '**/ipv4_merged.txt', '**/ipv6_merged.txt']:
            ip_files.extend(project_root.glob(pattern))
        
        print(f"Found {len(ip_files)} IP files to check")
        
        fixed_count = 0
        for ip_file in sorted(ip_files):
            if not args.dry_run:
                if clean_ip_file(str(ip_file)):
                    fixed_count += 1
            else:
                print(f"Would check: {ip_file}")
        
        if not args.dry_run:
            print(f"\nFixed {fixed_count} files")
        else:
            print(f"\nWould check {len(ip_files)} files")
    
    else:
        parser.print_help()
        return 1
    
    return 0


if __name__ == '__main__':
    exit(main())
