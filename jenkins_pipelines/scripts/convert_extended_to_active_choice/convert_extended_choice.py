#!/usr/bin/env python3
"""
convert_extended_choice.py
Safely converts extendedChoice parameters to choice in Jenkins pipeline files
"""

import re
import sys
import argparse
from pathlib import Path
from datetime import datetime
from typing import Tuple


from typing import Tuple

class SafeExtendedChoiceConverter:
    def __init__(self, dry_run: bool = False):
        self.dry_run = dry_run
        self.files_processed = 0
        self.files_changed = 0

    def convert_file_content(self, content: str) -> Tuple[str, bool]:
        """
        Convert extendedChoice to choice - line by line for safety.
        Only converts simple single-line extendedChoice declarations.
        Returns (new_content, was_changed)
        """
        lines = content.split('\n')
        new_lines = []
        changed = False
        i = 0

        while i < len(lines):
            line = lines[i]

            # Check if this line starts an extendedChoice
            if 'extendedChoice(' in line:
                # Collect the full extendedChoice block (handle multi-line)
                block_lines = [line]
                paren_count = line.count('(') - line.count(')')

                # Continue collecting lines until parentheses are balanced
                j = i + 1
                while paren_count > 0 and j < len(lines):
                    block_lines.append(lines[j])
                    paren_count += lines[j].count('(') - lines[j].count(')')
                    j += 1

                # Join the block
                block = '\n'.join(block_lines)

                # Try to convert this block
                converted = self.convert_extended_choice_block(block)
                if converted != block:
                    new_lines.append(converted)
                    changed = True
                    i = j  # Skip the lines we consumed
                    continue

            new_lines.append(line)
            i += 1

        return '\n'.join(new_lines), changed

    def convert_extended_choice_block(self, block: str) -> str:
        """Convert a single extendedChoice block to choice"""

        # Extract parameters using regex
        name_match = re.search(r'name:\s*[\'"]([^\'"]+)[\'"]', block)
        type_match = re.search(r'type:\s*[\'"]?([^\'"]+)[\'"]?', block)
        value_match = re.search(r'value:\s*[\'"]([^\'"]+)[\'"]', block)
        desc_match = re.search(r'description:\s*[\'"]([^\'"]+)[\'"]', block)

        if not (name_match and value_match):
            # Can't parse, return original
            return block

        name = name_match.group(1)
        values = [v.strip() for v in value_match.group(1).split(',')]
        description = desc_match.group(1) if desc_match else ''
        choice_type = type_match.group(1) if type_match else 'PT_SINGLE_SELECT'

        # Only convert PT_SINGLE_SELECT to simple choice
        if 'PT_SINGLE_SELECT' not in choice_type:
            # For other types, keep original or use activeChoice
            return self.convert_to_active_choice(name, values, description, choice_type)

        # Build choice parameter
        indent = self.get_indent(block)
        choices_str = ', '.join([f"'{v}'" for v in values])

        result = f"{indent}choice(\n"
        result += f"{indent}    name: '{name}',\n"
        result += f"{indent}    choices: [{choices_str}]"
        if description:
            result += f",\n{indent}    description: '{description}'"
        result += f"\n{indent})"

        return result

    def convert_to_active_choice(self, name: str, values: list, description: str, choice_type: str) -> str:
        """Convert to activeChoice for multi-select types"""
        indent = "        "

        type_map = {
            'PT_CHECKBOX': 'PT_CHECKBOX',
            'PT_MULTI_SELECT': 'PT_CHECKBOX',
            'PT_RADIO': 'PT_RADIO'
        }
        choice_type = type_map.get(choice_type, 'PT_SINGLE_SELECT')

        choices_str = ', '.join([f'"{v}"' for v in values])

        result = f"{indent}activeChoice(\n"
        result += f"{indent}    name: '{name}',\n"
        result += f"{indent}    choiceType: '{choice_type}',\n"
        result += f"{indent}    script: [\n"
        result += f"{indent}        $class: 'GroovyScript',\n"
        result += f"{indent}        script: [script: 'return [{choices_str}]']\n"
        result += f"{indent}    ]"
        if description:
            result += f",\n{indent}    description: '{description}'"
        result += f"\n{indent})"

        return result

    def get_indent(self, text: str) -> str:
        """Get the indentation from the first line"""
        match = re.match(r'^(\s*)', text)
        return match.group(1) if match else ''

    def convert_file(self, filepath: Path) -> bool:
        """Convert a single file. Returns True if changed."""
        try:
            # Read file
            content = filepath.read_text(encoding='utf-8')

            # Check if contains extendedChoice
            if 'extendedChoice' not in content:
                return False

            self.files_processed += 1
            print(f"Processing: {filepath}")

            # Convert
            new_content, changed = self.convert_file_content(content)

            if not changed:
                print(f"  ⊘ No changes needed")
                return False

            if self.dry_run:
                print(f"  [DRY RUN] Would modify file")
                print(f"  Preview of changes:")
                # Show a diff-like output
                old_lines = content.split('\n')
                new_lines = new_content.split('\n')
                for i, (old, new) in enumerate(zip(old_lines, new_lines), 1):
                    if old != new:
                        print(f"    Line {i}:")
                        print(f"      - {old}")
                        print(f"      + {new}")
                return False

            # Create backup
            timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
            backup_path = filepath.with_suffix(f'.backup-{timestamp}')
            filepath.write_text(content, encoding='utf-8')  # Write original as backup
            backup_path.write_text(content, encoding='utf-8')

            # Write converted content
            filepath.write_text(new_content, encoding='utf-8')

            print(f"  ✓ Converted")
            print(f"  ✓ Backup: {backup_path.name}")

            self.files_changed += 1
            return True

        except Exception as e:
            print(f"  ✗ Error: {e}")
            import traceback
            traceback.print_exc()
            return False

    def process_path(self, path: Path):
        """Process a file or directory"""
        if path.is_file():
            self.convert_file(path)
        else:
            print(f"Searching in: {path}\n")
            for filepath in sorted(path.rglob('*')):
                # Skip if not a file
                if not filepath.is_file():
                    continue

                # Skip backup files
                if '.backup-' in filepath.name or filepath.name.endswith('-BACKUP'):
                    continue

                # Skip hidden files
                if any(part.startswith('.') for part in filepath.parts):
                    continue

                self.convert_file(filepath)

    def print_summary(self):
        """Print summary"""
        print("\n" + "="*60)
        print(f"Files processed: {self.files_processed}")
        print(f"Files changed:   {self.files_changed}")
        print("="*60)


def main():
    parser = argparse.ArgumentParser(description='Convert extendedChoice to choice/activeChoice')
    parser.add_argument('path', type=Path, help='File or directory to process')
    parser.add_argument('--dry-run', action='store_true', help='Preview changes without modifying files')

    args = parser.parse_args()

    if not args.path.exists():
        print(f"Error: {args.path} does not exist")
        sys.exit(1)

    print("╔══════════════════════════════════════════════════════════╗")
    print("║  Extended Choice Converter                               ║")
    print("╚══════════════════════════════════════════════════════════╝\n")

    converter = SafeExtendedChoiceConverter(dry_run=args.dry_run)
    converter.process_path(args.path)
    converter.print_summary()


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrupted")
        sys.exit(1)
