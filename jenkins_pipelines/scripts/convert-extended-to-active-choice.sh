#!/bin/bash
# convert-extended-to-active-choice.sh
# Converts extendedChoice parameters to activeChoice in Jenkinsfiles
# This fixes compatibility with modern Jenkins using uno-choice plugin

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Extended Choice to Active Choice Converter             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Check if file or directory argument provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file_or_directory>"
    echo ""
    echo "Examples:"
    echo "  $0 Jenkinsfile"
    echo "  $0 jenkins_pipelines/"
    echo "  $0 /path/to/repo/jenkins_pipelines/environments/"
    exit 1
fi

TARGET="$1"
BACKUP_SUFFIX=".backup-$(date +%Y%m%d-%H%M%S)"
FILES_CHANGED=0
FILES_PROCESSED=0

# Function to convert a single file
convert_file() {
    local file="$1"

    # Skip if not a text file or doesn't exist
    if [ ! -f "$file" ]; then
        return
    fi

    # Check if file contains extendedChoice
    if ! grep -q "extendedChoice" "$file"; then
        return
    fi

    FILES_PROCESSED=$((FILES_PROCESSED + 1))

    echo -e "${YELLOW}Processing: $file${NC}"

    # Create backup
    cp "$file" "${file}${BACKUP_SUFFIX}"
    echo "  ✓ Created backup: ${file}${BACKUP_SUFFIX}"

    # Perform replacements
    # Pattern 1: extendedChoice(...) -> activeChoice(...)
    sed -i 's/extendedChoice(\s*/activeChoice(/g' "$file"

    # Pattern 2: Common parameter conversions
    # multiSelectDelimiter -> (not needed in activeChoice, remove it)
    sed -i '/multiSelectDelimiter:/d' "$file"

    # Pattern 3: type: 'PT_' conversions
    sed -i 's/type:\s*['"'"'"]\?PT_SINGLE_SELECT['"'"'"]\?/choiceType: '\''PT_SINGLE_SELECT'\''/g' "$file"
    sed -i 's/type:\s*['"'"'"]\?PT_MULTI_SELECT['"'"'"]\?/choiceType: '\''PT_CHECKBOX'\''/g' "$file"
    sed -i 's/type:\s*['"'"'"]\?PT_CHECKBOX['"'"'"]\?/choiceType: '\''PT_CHECKBOX'\''/g' "$file"
    sed -i 's/type:\s*['"'"'"]\?PT_RADIO['"'"'"]\?/choiceType: '\''PT_RADIO'\''/g' "$file"

    # Pattern 4: value -> defaultValue (if not already defaultValue)
    sed -i 's/\bvalue:\s*/defaultValue: /g' "$file"

    FILES_CHANGED=$((FILES_CHANGED + 1))
    echo -e "  ${GREEN}✓ Converted extendedChoice to activeChoice${NC}"

    # Show diff
    echo "  Changes:"
    diff -u "${file}${BACKUP_SUFFIX}" "$file" | grep "^[-+]" | grep -v "^[-+][-+][-+]" | head -10 || true
    echo ""
}

# Process files
if [ -f "$TARGET" ]; then
    # Single file
    convert_file "$TARGET"
elif [ -d "$TARGET" ]; then
    # Directory - find all Jenkinsfiles and .groovy files
    echo "Searching for files in: $TARGET"
    echo ""

    # Find all text files that might be Jenkinsfiles
    # Include: Jenkinsfile*, *.groovy, *.jenkins, and files without extensions
    while IFS= read -r -d '' file; do
        # Skip backup files
        [[ "$file" =~ \.backup- ]] && continue

        # Skip directories
        [ -d "$file" ] && continue

        convert_file "$file"
    done < <(find "$TARGET" -type f \( -name "Jenkinsfile*" -o -name "*.groovy" -o -name "*.jenkins" \) -print0; \
             find "$TARGET" -type f ! -name "*.*" ! -path "*/\.*" -print0)
else
    echo -e "${RED}ERROR: $TARGET is neither a file nor a directory${NC}"
    exit 1
fi

# Summary
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Conversion Summary                                      ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo "  Files processed: $FILES_PROCESSED"
echo "  Files changed:   $FILES_CHANGED"
echo ""

if [ $FILES_CHANGED -gt 0 ]; then
    echo -e "${GREEN}✓ Conversion complete!${NC}"
    echo ""
    echo "Backups created with suffix: $BACKUP_SUFFIX"
    echo ""
    echo "To restore a file:"
    echo "  mv filename${BACKUP_SUFFIX} filename"
    echo ""
    echo "To remove all backups:"
    echo "  find . -name '*${BACKUP_SUFFIX}' -delete"
else
    echo "No files needed conversion."
fi
