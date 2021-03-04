---
name: 'Bug Fix'
about: 'A pull request that fixes a bug in a script'
title: '[BUG FIX] <Describe the fix in 20 words or less>'
labels: 'fix, needs review, high priority'
assignees: ''
---

<!-- Leave the ## Headings, --- dividers, and - [x] checkboxes in place; replace each paragraph with requested info -->
## Which script?

Describe which script this pull request is for, including the location within this repo.

e.g. PowerShell/Scripts/Some-Script.ps1

---

## What's it do?

A clear and concise description of the bug that this pull request fixes.

If this fixes a known bug with an open issue, tag it using a hash/pound symbol `#` and number e.g.

> This fixes #1

Also include any relevant code, using code fences and a language hint \[e.g. java, powershell] like below:

```powershell
.\Some-Script.ps1 -FixedParameter "No longer fails with","multiple strings"
```

---

## Screenshots

If applicable, add screenshots to help explain how this bug fix works. These can be hosted on GitHub, or as links to uploads on one of the following image hosting sites:

- [Imgur](https://imgur.com/upload)
- [Flickr](https://flickr.com)
- [500px](https://500px.com)
- [Google Photos](https://photos.google.com/login)
- [Dropbox](https://www.dropbox.com)

---

## Additional notes

Add any other context or relevant information here. This includes technical details, security considerations, and attributions for code included that was written by others (third-party). Any attributions must also be in the code as comments or in comment-based help. Any third-party code must be in the public domain or have a license compatible with the [MIT license][license], and this license should be included. Submissions with third-party code will be considered on a case-by-case basis.

---

## Checklist

Make sure you fulfill each of the following requirements. The *ready for merge* check can be left unticked if you want amendments and suggestions before a decision is made.

- [ ] Pull request **identifies** the script being fixed (*Which script?*).
- [ ] Pull request has a **descriptive** title and description (*What's it do?*).
- [ ] Any changes to the user experience are **documented** correctly with comment-based help.
- [ ] If a test suite exists for the script, changes have been **tested** and/or tests amended.
- [ ] I confirm that the changes are **my own work** and any code included that was written by others is **attributed**.

### Ready for merge

- [ ] Pull request is not a WIP and is **ready for merge**.

[license]: ./LICENSE "MIT License"
