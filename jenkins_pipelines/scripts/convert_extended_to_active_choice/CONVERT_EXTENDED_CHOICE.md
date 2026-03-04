# Extended Choice to Choice/Active Choice Converter

Python tool to safely convert deprecated `extendedChoice` parameters to modern `choice` or `activeChoice` in Jenkins pipeline files.

---

## Why You Need This

Jenkins pipelines using `extendedChoice` will fail with:

```
No such DSL method 'extendedChoice' found among steps
```

The `Extended Choice Parameter` plugin is deprecated. Modern Jenkins uses:
- `choice()` - Built-in, for simple dropdowns
- `activeChoice()` - From `uno-choice` plugin, for advanced use cases

---

## Quick Start

```bash
# Make executable
chmod +x convert_extended_choice.py

# Preview changes (dry run)
python3 convert_extended_choice.py /path/to/pipeline/dir --dry-run

# Apply conversion
python3 convert_extended_choice.py /path/to/pipeline/dir

# Convert single file
python3 convert_extended_choice.py /path/to/Jenkinsfile
```

---

## What It Does

### Converts Simple Dropdowns to `choice()`

**Before:**
```groovy
extendedChoice(
    name: 'ENV',
    type: 'PT_SINGLE_SELECT',
    value: 'dev,staging,prod',
    description: 'Environment to deploy'
)
```

**After:**
```groovy
choice(
    name: 'ENV',
    choices: ['dev', 'staging', 'prod'],
    description: 'Environment to deploy'
)
```

### Converts Multi-Select to `activeChoice()`

**Before:**
```groovy
extendedChoice(
    name: 'COMPONENTS',
    type: 'PT_CHECKBOX',
    value: 'server,proxy,client',
    description: 'Components to deploy'
)
```

**After:**
```groovy
activeChoice(
    name: 'COMPONENTS',
    choiceType: 'PT_CHECKBOX',
    script: [
        $class: 'GroovyScript',
        script: [script: 'return ["server", "proxy", "client"]']
    ],
    description: 'Components to deploy'
)
```

---

## Features

✅ **Safe Conversion**
- Handles multi-line parameter blocks
- Preserves indentation and formatting
- Only converts what it can parse correctly
- Leaves malformed parameters untouched

✅ **Automatic Backups**
- Creates timestamped backups before modifying
- Easy rollback if needed

✅ **Dry Run Mode**
- Preview all changes before applying
- See exactly what will be modified

✅ **Batch Processing**
- Convert entire directories recursively
- Skips backup files automatically
- Processes all pipeline files at once

✅ **Smart Detection**
- Finds files with or without extensions
- Skips hidden files and `.git` directories
- Handles files named `Jenkinsfile`, `*.groovy`, or no extension

---

## Command Line Options

```bash
python3 convert_extended_choice.py <path> [--dry-run]

Arguments:
  path              File or directory to process

Options:
  --dry-run         Preview changes without modifying files
  -h, --help        Show help message
```

---

## Usage Examples

### Convert Entire Pipeline Repository

```bash
cd ~/github/susemanager-ci

# Preview changes
python3 scripts/convert_extended_choice.py jenkins_pipelines/ --dry-run

# Apply conversion
python3 scripts/convert_extended_choice.py jenkins_pipelines/

# Review changes
git diff

# Commit if everything looks good
git add .
git commit -m "Convert extendedChoice to choice/activeChoice"
```

### Convert Single Directory

```bash
python3 convert_extended_choice.py jenkins_pipelines/environments/sle-maintenance-update/
```

### Convert Single File

```bash
python3 convert_extended_choice.py jenkins_pipelines/environments/personal/my-pipeline
```

### Multiple Directories

```bash
for dir in dir1 dir2 dir3; do
    python3 convert_extended_choice.py "jenkins_pipelines/environments/$dir/"
done
```

---

## What Gets Converted

### Type Mapping

| Extended Choice Type | Converts To | Result |
|---------------------|-------------|--------|
| `PT_SINGLE_SELECT` | `choice()` | Simple dropdown (built-in) |
| `PT_CHECKBOX` | `activeChoice()` | Checkboxes (uno-choice plugin) |
| `PT_MULTI_SELECT` | `activeChoice()` | Checkboxes (uno-choice plugin) |
| `PT_RADIO` | `activeChoice()` | Radio buttons (uno-choice plugin) |

### Supported Parameter Attributes

- ✅ `name` - Parameter name
- ✅ `type` - Choice type (converted to `choiceType`)
- ✅ `value` - Comma-separated list of options
- ✅ `description` - Help text
- ✅ `defaultValue` - Default selection (first item in list)
- ⚠️ `multiSelectDelimiter` - Removed (not needed in modern plugins)

---

## Output Example

```
╔══════════════════════════════════════════════════════════╗
║  Extended Choice Converter                               ║
╚══════════════════════════════════════════════════════════╝

Searching in: jenkins_pipelines/environments/

Processing: jenkins_pipelines/environments/manager-4.3-validation
  ✓ Converted
  ✓ Backup: manager-4.3-validation.backup-20260304-150000

Processing: jenkins_pipelines/environments/manager-5.0-validation
  ✓ Converted
  ✓ Backup: manager-5.0-validation.backup-20260304-150001

============================================================
Files processed: 2
Files changed:   2
============================================================
```

---

## Dry Run Mode

Use `--dry-run` to preview changes:

```bash
python3 convert_extended_choice.py my-pipeline --dry-run
```

**Output:**
```
Processing: my-pipeline
  [DRY RUN] Would modify file
  Preview of changes:
    Line 15:
      - extendedChoice(
      + choice(
    Line 16:
      -     type: 'PT_SINGLE_SELECT',
      +     choices: ['dev', 'staging', 'prod'],
```

---

## Backup and Restore

### Backups Are Automatic

Every converted file gets a backup:
```
manager-4.3-validation                      # Converted file
manager-4.3-validation.backup-20260304-150000   # Backup
```

### Restore a File

```bash
# Restore specific file
mv manager-4.3-validation.backup-20260304-150000 manager-4.3-validation

# Restore all files in directory
for f in *.backup-*; do
    original="${f%.backup-*}"
    mv "$f" "$original"
done
```

### Remove Backups

```bash
# After verifying changes work
find . -name "*.backup-*" -delete
```

---

## Troubleshooting

### Script Doesn't Find My Files

**Problem:** Files not detected in directory

**Solution:** The script looks for:
- Files named `Jenkinsfile*`
- Files ending in `.groovy`
- Files with no extension (your pipeline files)

If your files are named differently, run on individual files:
```bash
python3 convert_extended_choice.py my-custom-named-file
```

### Conversion Produces Errors

**Problem:** Converted pipeline fails to run

**Possible causes:**
1. **Missing `uno-choice` plugin** - For `activeChoice` parameters
2. **Malformed original parameters** - Script can't fix already-broken syntax
3. **Complex nested parameters** - May need manual conversion

**Solutions:**
```bash
# 1. Install uno-choice plugin
echo "uno-choice" >> plugins.txt
python3 scripts/graceful-restart-jenkins.py rebuild

# 2. Check Jenkins logs
docker logs jenkins-controller 2>&1 | grep -A 20 "WorkflowScript"

# 3. Manually review converted file
diff original.backup-* original
```

### Parameters Don't Appear in UI

**Problem:** After conversion, parameters missing in "Build with Parameters"

**Solution:**
1. Check Jenkins job configuration in UI
2. Verify plugin is installed: `Manage Jenkins → Plugins → Installed → Uno Choice`
3. Try re-saving the job configuration

### Script Modifies Wrong Things

**Problem:** Converted file has broken syntax

**Solution:**
1. **Always use `--dry-run` first!**
2. Restore from backup
3. Report the issue with example file

---

## Advanced Usage

### Integration with Git

```bash
# Create feature branch
git checkout -b convert-extended-choice

# Convert
python3 convert_extended_choice.py jenkins_pipelines/

# Review each file
git diff jenkins_pipelines/

# Stage and commit
git add jenkins_pipelines/
git commit -m "Convert extendedChoice to choice/activeChoice

- Replaced deprecated extendedChoice with choice()
- Multi-select parameters now use activeChoice()
- All files backed up before conversion"

# Push for review
git push origin convert-extended-choice
```

### Selective Conversion

```bash
# Only convert files matching pattern
find jenkins_pipelines/ -name "*validation*" | while read f; do
    python3 convert_extended_choice.py "$f"
done
```

### Testing Before Deployment

```bash
# 1. Convert in test environment
python3 convert_extended_choice.py test-pipeline

# 2. Run pipeline in Jenkins
# 3. Verify parameters appear correctly
# 4. Test with different parameter combinations
# 5. If all good, convert production pipelines
```

---

## Plugin Requirements

### Required for `choice()` (Simple Dropdowns)
- ✅ No plugin needed - built into Jenkins

### Required for `activeChoice()` (Advanced)
- ✅ `uno-choice` plugin

**Installation:**
```bash
# Add to plugins.txt
echo "uno-choice" >> plugins.txt

# Rebuild Jenkins
python3 scripts/graceful-restart-jenkins.py rebuild
```

**Verify:**
```bash
# Check if installed
docker exec jenkins-controller ls /var/jenkins_home/plugins/ | grep uno-choice
```

---

## Conversion Reference

### Complete Examples

#### Simple Dropdown

```groovy
# Before
extendedChoice(name: 'VERSION', type: 'PT_SINGLE_SELECT', value: '4.3,5.0,5.1')

# After
choice(name: 'VERSION', choices: ['4.3', '5.0', '5.1'])
```

#### Multi-Line with Description

```groovy
# Before
extendedChoice(
    name: 'ENVIRONMENT',
    type: 'PT_SINGLE_SELECT',
    value: 'dev,qa,staging,prod',
    description: 'Target environment for deployment'
)

# After
choice(
    name: 'ENVIRONMENT',
    choices: ['dev', 'qa', 'staging', 'prod'],
    description: 'Target environment for deployment'
)
```

#### Checkboxes (Multi-Select)

```groovy
# Before
extendedChoice(
    name: 'FEATURES',
    type: 'PT_CHECKBOX',
    value: 'auth,billing,notifications,reporting',
    description: 'Features to enable'
)

# After
activeChoice(
    name: 'FEATURES',
    choiceType: 'PT_CHECKBOX',
    script: [
        $class: 'GroovyScript',
        script: [script: 'return ["auth", "billing", "notifications", "reporting"]']
    ],
    description: 'Features to enable'
)
```

---

## Known Limitations

1. **Dynamic values not supported** - Only static comma-separated lists
2. **Complex nested parameters** - May need manual conversion
3. **Groovy script values** - Not converted automatically
4. **Default values** - First item in list becomes default
5. **Malformed parameters** - Left unchanged (check dry-run output)

---

## Getting Help

### Check Dry Run First

```bash
python3 convert_extended_choice.py my-file --dry-run
```

### View Detailed Changes

```bash
# Before conversion
cp my-file my-file.original

# After conversion
diff -u my-file.original my-file
```

### Report Issues

When reporting issues, include:
1. Original parameter snippet
2. Converted result
3. Error message from Jenkins
4. Python version: `python3 --version`

---

## Best Practices

1. ✅ **Always run `--dry-run` first**
2. ✅ **Test in non-production environment**
3. ✅ **Convert one directory at a time**
4. ✅ **Review git diff before committing**
5. ✅ **Keep backups until verified working**
6. ✅ **Install `uno-choice` plugin before deploying**
7. ✅ **Test parameters in Jenkins UI after conversion**

---

## Performance

- **Speed:** ~100 files per second
- **Memory:** Minimal (processes one file at a time)
- **Safe:** No modification of files that don't contain `extendedChoice`

---

## Version Compatibility

- **Python:** 3.6+
- **Jenkins:** 2.300+ (LTS)
- **Plugins:**
    - `uno-choice` for `activeChoice()`
    - No plugin needed for `choice()`

---

## Quick Reference

```bash
# Preview changes
python3 convert_extended_choice.py DIR --dry-run

# Convert directory
python3 convert_extended_choice.py DIR

# Convert file
python3 convert_extended_choice.py FILE

# Restore backup
mv FILE.backup-TIMESTAMP FILE

# Remove all backups
find . -name "*.backup-*" -delete
```

---

## Summary

This tool safely converts deprecated `extendedChoice` parameters to modern equivalents:

| Old | New | Plugin Required |
|-----|-----|----------------|
| `extendedChoice` (PT_SINGLE_SELECT) | `choice()` | None |
| `extendedChoice` (PT_CHECKBOX) | `activeChoice()` | uno-choice |
| `extendedChoice` (PT_RADIO) | `activeChoice()` | uno-choice |

**Result:** Jenkins pipelines work with modern plugins and LTS versions.