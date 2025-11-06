---
title: "How we used Radicle with GitHub Actions"
subtitle: "Quick guide to trying Radicle without dropping GitHub or whatever CI you’re using."
author: rudolfs
layout: blog
---

A chat with [burrito]({{ "users/did:key:z6MkrubmdTJKR42YZd7yDYysyx4JRez1wmvxjpmhzhTMKxsr" | explore }}) aka [Dietrich Ayala](https://metafluff.com) today sparked the idea to write down how we started dogfooding Radicle before we had our native Radicle CI going. He also encouraged me to just set a deadline for writing blog posts in general, so this had to be written and published by the end of today.

We wanted to dogfood Radicle as soon as possible, but there was one caveat: we didn't have a solution for CI at the time. So what we did was just reuse our existing GitHub actions and push both to Radicle and GitHub. The code review would happen in Radicle, and GitHub would run our tests. For easy visual indication, we used workflow status badges generated for each branch pushed to GitHub.

The screenshot below shows how this looks in the Desktop app.
<img src="/assets/images/blog/radicle-with-github-actions-screenshot.png" class="screenshot"/>

The workflow was as simple as:

1. Create a branch and commit your changes
2. Push the changes to GitHub with `git push github rudolfs/breadcrumb-tweak:rudolfs/breadcrumb-tweak`
3. Copy the build badge links to your clipboard, see script below
4. Open a patch on Radicle via `git push rad HEAD:refs/patches`, paste the build badges into the patch body and submit it

When we addressed changes from code review and submitted a new revision, we pushed it to both Radicle and GitHub to trigger another build, the badges updated automatically.

```sh
$ git push github rudolfs/breadcrumb-tweak:rudolfs/breadcrumb-tweak
$ git push rad
```

The `rad` remote is set up for you automatically when you initialize a project with `rad init`. The GitHub remote can be set up manually via `git remote add github git@github.com:radicle-dev/radicle-interface.git` pointing to a copy of the project which lives on your GitHub account.

```sh
$ git remote -v

github	git@github.com:radicle-dev/radicle-interface.git (fetch)
github	git@github.com:radicle-dev/radicle-interface.git (push)
rad	rad://z4V1sjrXqjvFdnCUbxPFqd5p4DtH5 (fetch)
rad	rad://z4V1sjrXqjvFdnCUbxPFqd5p4DtH5/z6MkwPUeUS2fJMfc2HZN1RQTQcTTuhw4HhPySB8JeUg2mVvx (push)
```

Bash script that automatically copies the build badge links to the clipboard.

```bash
#!/bin/bash
set -euo pipefail
branchName=$(git branch --show-current)
previewBranchName="${branchName//\//-}"
workflowBranchName="${branchName//\//%2F}"
# Use a here document to include the text and pipe it to sed
sed -e "s|<branchName>|$branchName|g" \
  -e "s|<workflowBranchName>|$workflowBranchName|g" \
  -e "s|<previewBranchName>|$previewBranchName|g" <<'EOF' | pbcopy
![check](https://github.com/radicle-dev/radicle-interface/actions/workflows/check.yml/badge.svg?branch=<branchName>) ![check-visual](https://github.com/radicle-dev/radicle-interface/actions/workflows/check-visual.yml/badge.svg?branch=<branchName>) ![check-unit-test](https://github.com/radicle-dev/radicle-interface/actions/workflows/check-unit-test.yml/badge.svg?branch=<branchName>) ![check-http-client-unit-test](https://github.com/radicle-dev/radicle-interface/actions/workflows/check-http-client-unit-test.yml/badge.svg?branch=<branchName>) ![check-radicle-httpd](https://github.com/radicle-dev/radicle-interface/actions/workflows/check-radicle-httpd.yml/badge.svg?branch=<branchName>) ![check-e2e](https://github.com/radicle-dev/radicle-interface/actions/workflows/check-e2e.yml/badge.svg?branch=<branchName>) ![check-build](https://github.com/radicle-dev/radicle-interface/actions/workflows/check-build.yml/badge.svg?branch=<branchName>) ![check-http](https://github.com/radicle-dev/radicle-interface/actions/workflows/check-radicle-httpd.yml/badge.svg?branch=<branchName>)
👉 [Preview](https://radicle-interface-git-<previewBranchName>-radicle.vercel.app)
👉 [Workflow runs](https://github.com/radicle-dev/radicle-interface/actions?query=branch%3A<workflowBranchName>)
👉 [Branch on GitHub](https://github.com/radicle-dev/radicle-interface/tree/<branchName>)
EOF
```

This is how we used to run tests and builds. Now, we're dogfooding [our own CI solution]({{ "rad:zwTxygwuz5LDGBq255RA2CbNGrz8" | explore }}) together with [Woodpecker]({{ "rad:z39Cf1XzrvCLRZZJRUZnx9D1fj5ws" | explore }}). If you want to learn more about CI in Radicle, check out the conversations on [Zulip](https://radicle.zulipchat.com/#narrow/channel/452370-radicle-ci).
