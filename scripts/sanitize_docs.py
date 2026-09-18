#!/usr/bin/env python3
"""
Script to sanitize sensitive information from documentation files
"""

import re
import os

# Define sensitive information mappings
REPLACEMENTS = {
    # Server names
    r'POSI1928': '<MFT_AGENT_PROD>',
    r'POSI1927': '<MFT_AGENT_NONPROD>',
    r'POSI1964': '<MFT_AGENT_MIG>',
    r'POSA1251': '<FILE_SERVER>',
    
    # File paths
    r'\\\\POSA1251\\file_transfer\\NBS': r'\\<FILE_SERVER>\file_transfer\NBS',
    r'D:\\AgressoMIFeed\\Staging': r'<STAGING_DRIVE>:\AgressoMIFeed\Staging',
    
    # Network shares
    r'\\\\wbbsmd\.co\.uk\\Corpdata\\Dept\\Data Centre Services\\TSA - Tech Ops team\\GoAnyWhere \(Managed File Transfer\)\\MFT_Schedules_XML_PROD': r'\\<NETWORK_SHARE>\MFT_Workflows\PROD',
    r'\\\\wbbsmd\.co\.uk\\Corpdata\\Dept\\Data Centre Services\\TSA - Tech Ops team\\GoAnyWhere \(Managed File Transfer\)\\MFT_ScheduleS_XML_UAT': r'\\<NETWORK_SHARE>\MFT_Workflows\UAT',
    
    # Hostnames/URLs
    r'uks-gateway\.unit4cloud\.com': '<AGRESSO_SFTP_HOST>',
    r'\\\\S-UKSBW-APPP06\\uk_wbs_prod\$': r'<AGRESSO_CLOUD>',
    r'wbbsmd\.co\.uk': '<DOMAIN>',
}

def sanitize_file(filepath):
    """Sanitize a single file"""
    print(f"Processing: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Apply all replacements
    for pattern, replacement in REPLACEMENTS.items():
        content = re.sub(pattern, replacement, content)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✓ Updated {filepath}")
        return True
    else:
        print(f"  - No changes needed for {filepath}")
        return False

def main():
    """Main function"""
    docs_dir = 'docs/testing'
    files_to_sanitize = [
        os.path.join(docs_dir, 'AWS_vs_OnPremise_vs_GoAnywhere_Test_Locations.md'),
        os.path.join(docs_dir, 'OAT-FILE-RECOVERY-TESTING-GUIDE.md'),
        os.path.join(docs_dir, 'OAT-FILE-RECOVERY-TEST-EXECUTION-PROCEDURES.md'),
    ]
    
    updated_count = 0
    for filepath in files_to_sanitize:
        if os.path.exists(filepath):
            if sanitize_file(filepath):
                updated_count += 1
        else:
            print(f"  ✗ File not found: {filepath}")
    
    print(f"\n{'='*60}")
    print(f"Sanitization complete! {updated_count} files updated.")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
