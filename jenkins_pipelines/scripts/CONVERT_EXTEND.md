# Converting extendedChoice to activeChoice

## Why This is Needed

The `Extended Choice Parameter` plugin is deprecated. Modern Jenkins uses the `Active Choices` plugin (`uno-choice`) instead.

**Error you'll see:**
```
No such DSL method 'extendedChoice' found among steps
```

---

## Quick Fix with Script

```bash
# Make script executable
chmod +x convert-extended-to-active-choice.sh

# Convert a single file
bash convert-extended-to-active-choice.sh /path/to/Jenkinsfile

# Convert entire directory
bash convert-extended-to-active-choice.sh jenkins_pipelines/

# Convert multiple directories
for dir in dir1 dir2 dir3; do
  bash convert-extended-to-active-choice.sh "$dir"
done
```

---

## Manual Conversion Reference

### Before (Extended Choice):

```groovy
parameters {
    extendedChoice(
        name: 'ENV',
        type: 'PT_SINGLE_SELECT',
        value: 'dev,staging,prod',
        defaultValue: 'dev',
        description: 'Environment to deploy',
        multiSelectDelimiter: ','
    )
}
```

### After (Active Choice):

```groovy
parameters {
    activeChoice(
        name: 'ENV',
        choiceType: 'PT_SINGLE_SELECT',
        script: [
            $class: 'GroovyScript',
            script: [
                script: 'return ["dev", "staging", "prod"]'
            ]
        ],
        description: 'Environment to deploy'
    )
}
```

---

## Common Conversions

### 1. Simple Dropdown (Single Select)

**Before:**
```groovy
extendedChoice(
    name: 'VERSION',
    type: 'PT_SINGLE_SELECT',
    value: '4.3,5.0,5.1',
    defaultValue: '5.1'
)
```

**After:**
```groovy
activeChoice(
    name: 'VERSION',
    choiceType: 'PT_SINGLE_SELECT',
    script: [
        $class: 'GroovyScript',
        script: [
            script: 'return ["4.3", "5.0", "5.1"]'
        ]
    ]
)
```

### 2. Multi-Select (Checkboxes)

**Before:**
```groovy
extendedChoice(
    name: 'COMPONENTS',
    type: 'PT_CHECKBOX',
    value: 'server,proxy,client',
    defaultValue: 'server',
    multiSelectDelimiter: ','
)
```

**After:**
```groovy
activeChoice(
    name: 'COMPONENTS',
    choiceType: 'PT_CHECKBOX',
    script: [
        $class: 'GroovyScript',
        script: [
            script: 'return ["server", "proxy", "client"]'
        ]
    ]
)
```

### 3. Radio Buttons

**Before:**
```groovy
extendedChoice(
    name: 'ACTION',
    type: 'PT_RADIO',
    value: 'deploy,rollback,restart'
)
```

**After:**
```groovy
activeChoice(
    name: 'ACTION',
    choiceType: 'PT_RADIO',
    script: [
        $class: 'GroovyScript',
        script: [
            script: 'return ["deploy", "rollback", "restart"]'
        ]
    ]
)
```

---

## Key Differences

| Extended Choice | Active Choice | Notes |
|----------------|---------------|-------|
| `type` | `choiceType` | Parameter name changed |
| `value` | `script` | Now uses Groovy script returning list |
| `multiSelectDelimiter` | N/A | Removed, not needed |
| `defaultValue` | First item in list | Or use `@Field` annotation |

---

## Alternative: Use Standard choice()

For simple static lists, you can also use the built-in `choice()` parameter:

**Before (extendedChoice):**
```groovy
extendedChoice(
    name: 'ENV',
    type: 'PT_SINGLE_SELECT',
    value: 'dev,staging,prod',
    defaultValue: 'dev'
)
```

**After (standard choice):**
```groovy
choice(
    name: 'ENV',
    choices: ['dev', 'staging', 'prod'],
    description: 'Environment'
)
```

**Pros:** Simpler, no plugin needed  
**Cons:** Less flexible, no dynamic choices

---

## Testing Your Conversion

1. **Save the converted Jenkinsfile**
2. **Run the pipeline**
3. **Verify parameters appear correctly** in "Build with Parameters"
4. **Check the parameter values** are passed correctly to the pipeline

---

## Troubleshooting

### Parameters don't appear

- Check Jenkins logs for Groovy script errors
- Verify `uno-choice` plugin is installed
- Ensure Groovy script syntax is correct

### Wrong parameter type displayed

- Double-check `choiceType` value:
    - `PT_SINGLE_SELECT` - dropdown
    - `PT_CHECKBOX` - checkboxes
    - `PT_RADIO` - radio buttons

### Values not populating

- Test the Groovy script in Jenkins Script Console
- Ensure the script returns a List<String>

---

## Bulk Conversion

For entire repository:

```bash
# Clone your Jenkins pipeline repo
git clone https://github.com/SUSE/susemanager-ci.git
cd susemanager-ci

# Run conversion on all Jenkinsfiles
find . -name "Jenkinsfile*" -o -name "*.groovy" | while read file; do
  bash /path/to/convert-extended-to-active-choice.sh "$file"
done

# Review changes
git diff

# Commit if looks good
git add .
git commit -m "Convert extendedChoice to activeChoice for Jenkins compatibility"
git push
```

---

## Plugin Requirements

Ensure `uno-choice` plugin is installed:

```txt
# In plugins.txt
uno-choice
```

Then rebuild:
```bash
python3 scripts/graceful-restart-jenkins.py rebuild
```