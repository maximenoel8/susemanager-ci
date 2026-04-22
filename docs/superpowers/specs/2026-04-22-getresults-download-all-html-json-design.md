# Design: Download all HTML/JSON results in getresults step

**Date:** 2026-04-22
**Status:** Approved

## Problem

When `--runstep getresults` is executed, terracumber downloads files from the controller to the Jenkins worker. The current implementation uses hardcoded regex patterns (`output.*\.html`, `output.*\.json`) to fetch files individually via SFTP. This misses files like `cucumber_report.html` (at the root of `CUCUMBER_RESULTS`) and any other HTML/JSON files not matching the `output.*` prefix. As a result, these files are absent from the Jenkins workspace and cannot be opened via Jenkins.

## Goal

Download **all** `.html` and `.json` files from the `CUCUMBER_RESULTS` directory on the controller to the Jenkins workspace, uncompressed, so they can be opened directly in Jenkins. Exclude `.txt` files and all other extensions.

## Approach

**Approach C — SFTP directory listing with extension filtering (Python-native)**

Add a new method `get_by_extensions(remotedir, localdir, extensions)` to the `Cucumber` class in `terracumber/cucumber.py`. This method:

1. Opens an SFTP client
2. Calls `listdir_attr(remotedir)` to list all entries in the remote directory
3. Skips subdirectories — only processes regular files
4. Downloads each file whose suffix is in `extensions` to `localdir`
5. Preserves atime/mtime using the existing `copy_atime_mtime()` helper
6. Logs a warning if no files matched

In `terracumber-cli`, `get_results()` replaces the two hardcoded file pattern calls for `output.*\.html` and `output.*\.json` with a single call:

```python
cucumber.get_by_extensions(config['CUCUMBER_RESULTS'], args.outputdir, ['.html', '.json'])
```

## What stays unchanged

- `spacewalk-debug.tar.bz2` download (kept as-is via existing `cucumber.get()`)
- Recursive directory downloads: `screenshots`, `cucumber_report`, `logs`, `results_junit`
- No new CLI arguments
- `.txt` files are excluded implicitly (not in the extensions list)

## Files to modify

| File | Change |
|------|--------|
| `terracumber/cucumber.py` | Add `get_by_extensions()` method |
| `terracumber-cli` | Replace two `cucumber.get()` calls with one `cucumber.get_by_extensions()` call in `get_results()` |

## Out of scope

- Downloading `.txt` files
- Changing the directory downloads (`screenshots`, `cucumber_report`, etc.)
- Adding new CLI flags
- Changing `saltshaker_getresults` behaviour
