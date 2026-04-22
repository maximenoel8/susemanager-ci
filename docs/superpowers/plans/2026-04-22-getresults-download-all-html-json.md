# getresults: Download all HTML/JSON results Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `get_by_extensions()` to the `Cucumber` class and use it in `get_results()` so that all `.html` and `.json` files in `CUCUMBER_RESULTS` on the controller are downloaded to Jenkins, instead of only files matching the `output.*` prefix.

**Architecture:** A new `get_by_extensions(remotedir, localdir, extensions)` method lists the remote directory via SFTP, filters by file extension, and downloads each match. `get_results()` in `terracumber-cli` replaces the two old `cucumber.get()` pattern calls with a single `get_by_extensions()` call. Everything else (directory downloads, `spacewalk-debug.tar.bz2`) is untouched.

**Tech Stack:** Python 3, paramiko (SFTP), unittest + unittest.mock

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `terracumber/cucumber.py` | Modify | Add `get_by_extensions()` method |
| `terracumber-cli` | Modify | Replace two `cucumber.get()` pattern calls in `get_results()` |
| `tests/test_cucumber_get_by_extensions.py` | Create | Unit tests for `get_by_extensions()` |

---

### Task 1: Write failing tests for `get_by_extensions()`

**Files:**
- Create: `tests/test_cucumber_get_by_extensions.py`

- [ ] **Step 1: Create the test file**

```python
# tests/test_cucumber_get_by_extensions.py
import os
import stat
import unittest
from unittest.mock import MagicMock, call, patch


class FakeSFTPAttr:
    """Minimal stand-in for paramiko.SFTPAttributes."""
    def __init__(self, filename, is_dir=False):
        self.filename = filename
        self.st_mode = stat.S_IFDIR if is_dir else stat.S_IFREG


class TestGetByExtensions(unittest.TestCase):

    def _make_cucumber(self):
        """Return a Cucumber instance with a mocked SSH client."""
        import terracumber.cucumber as cu
        with patch('terracumber.cucumber.paramiko.SSHClient') as mock_ssh_cls:
            instance = cu.Cucumber.__new__(cu.Cucumber)
            instance.ssh_client = MagicMock()
        return instance

    # --- happy path ---

    def test_downloads_matching_extensions(self):
        """Files whose extension is in the list are downloaded."""
        from terracumber.cucumber import Cucumber
        c = self._make_cucumber()

        entries = [
            FakeSFTPAttr('output_core.html'),
            FakeSFTPAttr('output_core.json'),
            FakeSFTPAttr('notes.txt'),          # excluded
            FakeSFTPAttr('subdir', is_dir=True), # excluded
        ]
        mock_sftp = MagicMock()
        mock_sftp.listdir_attr.return_value = entries
        c.ssh_client.open_sftp.return_value = mock_sftp

        with patch.object(c, 'copy_atime_mtime'):
            result = c.get_by_extensions('/remote/results', '/local/out', ['.html', '.json'])

        mock_sftp.get.assert_any_call('/remote/results/output_core.html', '/local/out/output_core.html')
        mock_sftp.get.assert_any_call('/remote/results/output_core.json', '/local/out/output_core.json')
        self.assertEqual(mock_sftp.get.call_count, 2)
        self.assertEqual(sorted(result), sorted([
            '/remote/results/output_core.html',
            '/remote/results/output_core.json',
        ]))

    def test_excludes_txt_files(self):
        """txt files are never downloaded."""
        from terracumber.cucumber import Cucumber
        c = self._make_cucumber()

        entries = [FakeSFTPAttr('core_html_path.txt')]
        mock_sftp = MagicMock()
        mock_sftp.listdir_attr.return_value = entries
        c.ssh_client.open_sftp.return_value = mock_sftp

        with patch.object(c, 'copy_atime_mtime'):
            result = c.get_by_extensions('/remote/results', '/local/out', ['.html', '.json'])

        mock_sftp.get.assert_not_called()
        self.assertEqual(result, [])

    def test_excludes_subdirectories(self):
        """Subdirectories are never downloaded."""
        from terracumber.cucumber import Cucumber
        c = self._make_cucumber()

        entries = [FakeSFTPAttr('cucumber_report', is_dir=True)]
        mock_sftp = MagicMock()
        mock_sftp.listdir_attr.return_value = entries
        c.ssh_client.open_sftp.return_value = mock_sftp

        with patch.object(c, 'copy_atime_mtime'):
            result = c.get_by_extensions('/remote/results', '/local/out', ['.html', '.json'])

        mock_sftp.get.assert_not_called()
        self.assertEqual(result, [])

    def test_preserves_atime_mtime(self):
        """copy_atime_mtime is called for every downloaded file."""
        from terracumber.cucumber import Cucumber
        c = self._make_cucumber()

        entries = [FakeSFTPAttr('output_sanity.html')]
        mock_sftp = MagicMock()
        mock_sftp.listdir_attr.return_value = entries
        c.ssh_client.open_sftp.return_value = mock_sftp

        with patch.object(c, 'copy_atime_mtime') as mock_cp:
            c.get_by_extensions('/remote/results', '/local/out', ['.html', '.json'])

        mock_cp.assert_called_once_with(
            '/remote/results/output_sanity.html',
            '/local/out/output_sanity.html',
        )

    def test_empty_directory_returns_empty_list(self):
        """An empty remote directory returns an empty list without raising."""
        from terracumber.cucumber import Cucumber
        c = self._make_cucumber()

        mock_sftp = MagicMock()
        mock_sftp.listdir_attr.return_value = []
        c.ssh_client.open_sftp.return_value = mock_sftp

        with patch.object(c, 'copy_atime_mtime'):
            result = c.get_by_extensions('/remote/results', '/local/out', ['.html', '.json'])

        self.assertEqual(result, [])
        mock_sftp.get.assert_not_called()


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: Run the tests — confirm they fail**

```bash
cd /app && python -m pytest tests/test_cucumber_get_by_extensions.py -v
```

Expected: `AttributeError` or `ImportError` — `get_by_extensions` does not exist yet.

---

### Task 2: Implement `get_by_extensions()` in `Cucumber`

**Files:**
- Modify: `terracumber/cucumber.py` (after the `get()` method, around line 91)

- [ ] **Step 3: Add the method to `cucumber.py`**

Open `terracumber/cucumber.py` and insert the following method after the closing `return(copied_files)` line of `get()` (after line 91), before `put_file`:

```python
    def get_by_extensions(self, remotedir, localdir, extensions):
        """Get all files from a remote directory whose extension is in `extensions`.

        Keyword arguments:
        remotedir  - A string with the full remote directory path
        localdir   - A string with the local directory to copy files into
        extensions - A list of file extensions to include, e.g. ['.html', '.json']

        Returns a list of remote paths that were downloaded.
        Subdirectories and files with other extensions are silently skipped.
        """
        import stat as _stat
        downloaded = []
        sftp_client = self.ssh_client.open_sftp()
        for entry in sftp_client.listdir_attr(remotedir):
            if not _stat.S_ISREG(entry.st_mode):
                continue
            _, ext = os.path.splitext(entry.filename)
            if ext not in extensions:
                continue
            remote_path = remotedir.rstrip('/') + '/' + entry.filename
            local_path = localdir.rstrip('/') + '/' + entry.filename
            sftp_client.get(remote_path, local_path)
            self.copy_atime_mtime(remote_path, local_path)
            downloaded.append(remote_path)
        return downloaded
```

- [ ] **Step 4: Run the tests — confirm they pass**

```bash
cd /app && python -m pytest tests/test_cucumber_get_by_extensions.py -v
```

Expected: all 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add terracumber/cucumber.py tests/test_cucumber_get_by_extensions.py
git commit -m "feat: add get_by_extensions() to Cucumber for extension-based SFTP download"
```

---

### Task 3: Update `get_results()` in `terracumber-cli`

**Files:**
- Modify: `terracumber-cli` (the `get_results()` function, around lines where `files = [...]` is defined)

- [ ] **Step 6: Replace the two pattern-based file downloads**

In `terracumber-cli`, find the `get_results()` function. It currently reads:

```python
    files = ['output.*\.html', 'output.*\.json', 'spacewalk-debug\.tar\.bz2']
    directories = ['screenshots', 'cucumber_report', 'logs', 'results_junit']
    for copyfile in files:
        try:
            cucumber.get('%s/%s' % (config['CUCUMBER_RESULTS'], copyfile),
                         '%s' % args.outputdir)
        except FileNotFoundError:
            logger.warning("Nothing matched %s/%s at %s!", config['CUCUMBER_RESULTS'],
                           copyfile, ctl_creds['hostname'])
```

Replace it with:

```python
    downloaded = cucumber.get_by_extensions(
        config['CUCUMBER_RESULTS'], args.outputdir, ['.html', '.json'])
    if not downloaded:
        logger.warning("No .html or .json files found in %s at %s!",
                       config['CUCUMBER_RESULTS'], ctl_creds['hostname'])
    try:
        cucumber.get('%s/%s' % (config['CUCUMBER_RESULTS'], 'spacewalk-debug\.tar\.bz2'),
                     '%s' % args.outputdir)
    except FileNotFoundError:
        logger.warning("Nothing matched %s/%s at %s!", config['CUCUMBER_RESULTS'],
                       'spacewalk-debug.tar.bz2', ctl_creds['hostname'])
    directories = ['screenshots', 'cucumber_report', 'logs', 'results_junit']
```

- [ ] **Step 7: Verify the CLI still imports cleanly**

```bash
cd /app && python terracumber-cli --help
```

Expected: usage/help text printed, no import errors.

- [ ] **Step 8: Commit**

```bash
git add terracumber-cli
git commit -m "feat: use get_by_extensions() in get_results() to download all html/json files"
```

---

## Self-Review

**Spec coverage:**
- ✅ All `.html` and `.json` files downloaded — `get_by_extensions(['.html', '.json'])`
- ✅ `.txt` files excluded — not in extension list
- ✅ Files uncompressed on Jenkins side — downloaded individually via SFTP `get()`
- ✅ `spacewalk-debug.tar.bz2` unchanged — kept as separate `cucumber.get()` call
- ✅ Directory downloads unchanged — `directories` list untouched
- ✅ No new CLI arguments

**Placeholder scan:** None found.

**Type consistency:** `get_by_extensions()` returns `list[str]` (remote paths). Called in `get_results()` and result checked with `if not downloaded`. Consistent throughout.
