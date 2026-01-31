#!/usr/bin/env python3
"""
Script to update Swift file headers with a professional format.
"""

import os
import re
from pathlib import Path
from datetime import datetime

# Header template
HEADER_TEMPLATE = """//
//  {filename}
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
"""

def get_file_description(filename: str) -> str:
    """Generate a brief description based on filename."""
    # Remove .swift extension
    name = filename.replace('.swift', '')
    
    # Common patterns
    descriptions = {
        'App': 'Application entry point',
        'ContentView': 'Main content view',
        'ViewModel': 'View model',
        'View': 'View component',
        'Model': 'Data model',
        'Service': 'Service layer',
        'Manager': 'Manager class',
        'Component': 'UI component',
        'Extension': 'Extension',
        'Theme': 'Theme configuration',
        'Icon': 'Icon definitions',
    }
    
    for key, desc in descriptions.items():
        if key in name:
            return desc
    
    return 'Swift file'

def update_header(file_path: Path) -> bool:
    """Update the header in a Swift file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Pattern to match the old header (lines starting with //)
        # Matches: optional whitespace, // filename, // project name, //, // Created by..., //
        old_header_pattern = r'^\s*//\s*\n\s*//\s+.*?\n\s*//\s+.*?\n\s*//\s*\n\s*//\s+Created by.*?\n\s*//\s*\n'
        
        # Check if old header exists
        if not re.search(old_header_pattern, content, re.MULTILINE):
            return False
        
        # Extract filename
        filename = file_path.name
        
        # Generate new header
        new_header = HEADER_TEMPLATE.format(filename=filename)
        
        # Replace old header with new one
        new_content = re.sub(old_header_pattern, new_header, content, flags=re.MULTILINE)
        
        # Only write if content changed
        if new_content != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
        
        return False
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Main function to update all Swift file headers."""
    # Get the project root (parent of scripts directory)
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    # Find all Swift files
    swift_files = list(project_root.rglob('*.swift'))
    
    # Filter out files in hidden directories or build directories
    swift_files = [
        f for f in swift_files 
        if '.build' not in str(f) and 
           '.xcodeproj' not in str(f) and
           'DerivedData' not in str(f)
    ]
    
    updated_count = 0
    
    print(f"Found {len(swift_files)} Swift files")
    print("Updating headers...\n")
    
    for swift_file in sorted(swift_files):
        relative_path = swift_file.relative_to(project_root)
        if update_header(swift_file):
            print(f"✓ Updated: {relative_path}")
            updated_count += 1
        else:
            print(f"⊘ Skipped: {relative_path} (no old header found)")
    
    print(f"\n✓ Updated {updated_count} file(s)")

if __name__ == '__main__':
    main()
