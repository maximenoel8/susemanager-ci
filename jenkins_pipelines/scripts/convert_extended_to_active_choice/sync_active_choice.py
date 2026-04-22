#!/usr/bin/env python3
"""
sync_active_choice.py

Syncs minion lists from build-validation (extendedChoice) to
build-validation-active-choice (activeChoice), using a compact format.

For each pipeline file in build-validation that defines a `def minionList`:
  - If the corresponding file in build-validation-active-choice already has
    an activeChoice block → updates only the minion list.
  - If the file is a shell (no properties block) → generates the full file
    by copying the source and converting extendedChoice → activeChoice.

The generated activeChoice format is compact (boilerplate on one line) with
minions grouped by family, matching the original minionList line structure.

Usage:
    python3 sync_active_choice.py [--dry-run]
    python3 sync_active_choice.py --bv-dir /path/to/build-validation
                                  --bac-dir /path/to/build-validation-active-choice
"""

import re
import os
import argparse

BV_DEFAULT  = os.path.join(os.path.dirname(__file__), '../../environments/build-validation')
BAC_DEFAULT = os.path.join(os.path.dirname(__file__), '../../environments/build-validation')

# Match the minionList variable block (stops before properties/stage/other def)
minion_block_re = re.compile(
    r"def minionList\s*=\s*(.*?)(?=\n[ \t]*(?:properties|stage|def [^m]))",
    re.DOTALL
)

# Match extendedChoice block including trailing comma
extendedchoice_re = re.compile(
    r"            extendedChoice\(name: 'minions_to_run'.*?description: 'Node list to run during BV'\),",
    re.DOTALL
)

# Match minionList variable definition — continuation lines are quoted strings (optional // prefix)
minionlist_re = re.compile(
    r"    def minionList = '[^\n]*'\n"          # single-line variant
    r"|    def minionList = '[^\n]*' \+\n"      # multi-line: first line
    r"(?:[ \t]+(?://)?[ \t]*'[^\n]*\n)*"        # continuation lines (quoted strings, optional // comment)
)


def extract_minion_groups(content):
    """
    Extract minion groups from minionList, preserving line structure.
    Each source line becomes one group in the return block.
    Commented-out lines are skipped.
    Returns list of groups, each group is a list of 'minion:selected' strings.
    """
    m = minion_block_re.search(content)
    if not m:
        return None
    groups = []
    for line in m.group(1).split('\n'):
        stripped = line.strip()
        if stripped.startswith('//'):
            continue
        items = []
        for quoted in re.findall(r"'([^']+)'", stripped):
            for minion in re.split(r',\s*', quoted):
                minion = minion.strip()
                if minion:
                    items.append("'" + minion + ":selected'")
        if items:
            groups.append(items)
    return groups


def build_active_choice(groups, indent='            '):
    """
    Build a compact activeChoice block with minions grouped by family.
    Boilerplate is on one line; return [...] is expanded with one group per line.
    """
    i2 = indent + '    '   # return [ / ]
    i3 = indent + '        '  # items

    return_lines = [i2 + 'return [']
    for j, group in enumerate(groups):
        comma = ',' if j < len(groups) - 1 else ''
        return_lines.append(i3 + ', '.join(group) + comma)
    return_lines.append(i2 + ']')
    return_block = '\n'.join(return_lines)

    return (
        indent + "activeChoice(name: 'minions_to_run', description: 'Node list to run during BV', "
        "choiceType: 'PT_CHECKBOX', script: [$class: 'GroovyScript', "
        "script: [$class: 'SecureGroovyScript', sandbox: true, script: \"\"\"\n"
        + return_block + "\n"
        + indent + "\"\"\".stripIndent()], "
        "fallbackScript: [$class: 'SecureGroovyScript', sandbox: true, "
        "script: \"return ['error_loading_minions']\"]]),\n"
    )


def replace_active_choice(content, new_ac):
    """Replace an existing activeChoice(name: 'minions_to_run' ...) block."""
    start = content.find("            activeChoice(name: 'minions_to_run'")
    if start == -1:
        return content
    end = content.find("]]),\n", start)
    if end == -1:
        return content
    end += len("]]),\n")
    return content[:start] + new_ac + content[end:]


def sync(bv_dir, bac_dir, dry_run=False):
    updated = []
    generated = []
    skipped = []

    for fname in sorted(os.listdir(bv_dir)):
        src = os.path.join(bv_dir, fname)
        dst = os.path.join(bac_dir, fname)

        if not os.path.isfile(src) or not os.path.isfile(dst):
            continue

        src_content = open(src).read()
        dst_content = open(dst).read()

        if 'def minionList' not in src_content:
            skipped.append((fname, 'no minionList in source'))
            continue

        groups = extract_minion_groups(src_content)
        if not groups:
            skipped.append((fname, 'could not parse minion groups'))
            continue

        new_ac = build_active_choice(groups)

        if "activeChoice(name: 'minions_to_run'" in dst_content:
            # Update minion list in existing activeChoice block
            new_dst = replace_active_choice(dst_content, new_ac)
            if new_dst == dst_content:
                skipped.append((fname, 'already up to date'))
            else:
                if not dry_run:
                    open(dst, 'w').write(new_dst)
                updated.append(fname)

        elif 'extendedChoice(' in dst_content:
            # Replace extendedChoice in destination
            new_dst = extendedchoice_re.sub(new_ac.rstrip('\n'), dst_content)
            new_dst = minionlist_re.sub('', new_dst)
            if not dry_run:
                open(dst, 'w').write(new_dst)
            updated.append(fname)

        else:
            # Shell file: generate full content from source
            new_src = extendedchoice_re.sub(new_ac.rstrip('\n'), src_content)
            if new_src == src_content:
                skipped.append((fname, 'extendedChoice not found in source'))
                continue
            new_src = minionlist_re.sub('', new_src)
            if "activeChoice(name: 'minions_to_run'" not in new_src:
                skipped.append((fname, 'sanity check failed after substitution'))
                continue
            if not dry_run:
                open(dst, 'w').write(new_src)
            generated.append(fname)

    tag = '[DRY RUN] ' if dry_run else ''

    print(f"{tag}Updated (minion list synced): {len(updated)}")
    for f in updated:
        print(f"  {f}")

    print(f"\n{tag}Generated (full file from source): {len(generated)}")
    for f in generated:
        print(f"  {f}")

    if skipped:
        print(f"\nSkipped: {len(skipped)}")
        for f, reason in skipped:
            print(f"  {f} ({reason})")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--bv-dir',  default=BV_DEFAULT,  help='Path to build-validation directory')
    parser.add_argument('--bac-dir', default=BAC_DEFAULT, help='Path to build-validation-active-choice directory')
    parser.add_argument('--dry-run', action='store_true',  help='Preview changes without writing files')
    args = parser.parse_args()

    bv_dir  = os.path.realpath(args.bv_dir)
    bac_dir = os.path.realpath(args.bac_dir)

    print(f"Source : {bv_dir}")
    print(f"Target : {bac_dir}")
    if args.dry_run:
        print("Mode   : DRY RUN\n")
    else:
        print()

    sync(bv_dir, bac_dir, dry_run=args.dry_run)


if __name__ == '__main__':
    main()
