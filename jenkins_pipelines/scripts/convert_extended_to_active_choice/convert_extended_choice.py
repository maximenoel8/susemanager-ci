#!/usr/bin/env python3
"""
Simple extendedChoice to activeChoice converter
Handles variable references and maintains proper formatting
"""

import re
import sys
from pathlib import Path
from datetime import datetime


def convert_extended_choice_block(block: str, indent: str) -> str:
    """Convert a single extendedChoice block"""

    # Extract parameters
    name = re.search(r"name:\s*['\"]([^'\"]+)['\"]", block)
    choice_type = re.search(r"type:\s*['\"]([^'\"]+)['\"]", block)
    value = re.search(r"value:\s*([^,\n]+)", block)
    desc = re.search(r"description:\s*['\"]([^'\"]+)['\"]", block)

    if not name:
        return block  # Can't parse

    name = name.group(1)
    choice_type = choice_type.group(1) if choice_type else 'PT_CHECKBOX'
    value_raw = value.group(1).strip() if value else ''
    description = desc.group(1) if desc else ''

    # Build activeChoice
    result = f"{indent}activeChoice(\n"
    result += f"{indent}    name: '{name}',\n"
    result += f"{indent}    choiceType: '{choice_type}',\n"
    result += f"{indent}    script: [\n"
    result += f"{indent}        $class: 'GroovyScript',\n"
    result += f"{indent}        script: [script: 'return {value_raw}']\n"
    result += f"{indent}    ]"

    if description:
        result += f",\n{indent}    description: '{description}'"

    result += f"\n{indent}),"  # ADD COMMA HERE

    return result


def convert_file(filepath: Path, dry_run: bool = False):
    """Convert one file"""

    content = filepath.read_text()

    if 'extendedChoice' not in content:
        return False

    print(f"Processing: {filepath.name}")

    lines = content.split('\n')
    new_lines = []
    i = 0
    changed = False

    while i < len(lines):
        line = lines[i]

        if 'extendedChoice(' in line:
            # Get indent
            indent = re.match(r'^(\s*)', line).group(1)

            # Collect full block
            block_lines = [line]
            paren_depth = line.count('(') - line.count(')')

            j = i + 1
            while paren_depth > 0 and j < len(lines):
                block_lines.append(lines[j])
                paren_depth += lines[j].count('(') - lines[j].count(')')
                j += 1

            block = '\n'.join(block_lines)

            # Convert
            converted = convert_extended_choice_block(block, indent)

            new_lines.append(converted)
            changed = True
            i = j
            print(f"  ✓ Converted extendedChoice")
            continue

        new_lines.append(line)
        i += 1

    if not changed:
        print(f"  ⊘ No changes")
        return False

    new_content = '\n'.join(new_lines)

    if dry_run:
        print(f"  [DRY RUN] Preview:")
        print(new_content[:500])
        return False

    # Create backup
    backup = filepath.with_suffix(f'.backup-{datetime.now().strftime("%Y%m%d-%H%M%S")}')
    backup.write_text(content)
    print(f"  ✓ Backup: {backup.name}")

    # Write new content
    filepath.write_text(new_content)
    print(f"  ✓ Saved")

    return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 convert.py <file_or_directory> [--dry-run]")
        sys.exit(1)

    path = Path(sys.argv[1])
    dry_run = '--dry-run' in sys.argv

    print("="*60)
    print("Extended Choice to Active Choice Converter")
    print("="*60)
    print()

    if path.is_file():
        convert_file(path, dry_run)
    else:
        for f in sorted(path.rglob('*')):
            if not f.is_file():
                continue
            if '-BACKUP' in f.name or '.backup-' in f.name:
                continue
            if f.name.startswith('.'):
                continue

            convert_file(f, dry_run)

    print()
    print("="*60)
    print("Done!")
    print("="*60)


if __name__ == '__main__':
    main()
