---
name: release
description: Run the fragalysis-stack release process. Finds the most recent open GitHub ticket whose title begins with "release" (case-insensitive), reads the fragalysis-backend and fragalysis-frontend versions from its body, updates the image tags in the build workflow, commits to master, and tags a stack release. Use when the user asks to "do a release", "cut a release", "run the release process", or invokes /release.
---

# Fragalysis stack release

This repo contains no application code — a release means pointing the stack build at specific
**fragalysis-backend** and **fragalysis-frontend** image tags, committing that change, then tagging
this repo so GitHub Actions builds and deploys the stack. Background: see `CLAUDE.md` ("Releasing").

A release ticket drives the process. The ticket body names the backend and frontend versions to use,
each on its own bullet point in a flexible format, e.g. `- backend 2026.06.1` and `- frontend 2026.05.7`.

This process tags and (via CI/AWX) deploys to **staging** and, for `N.N.N` tags, **production**. It is
outward-facing and hard to reverse, so **confirm with the user before committing, pushing, or tagging.**

## Step 1 — Find the release ticket

Find the most recent **open** issue in `xchem/fragalysis-stack` whose title begins with "release"
(case-insensitive). Fetch candidates and pick the newest by `createdAt`:

```bash
gh issue list --repo xchem/fragalysis-stack --state open \
  --json number,title,body,createdAt --limit 100
```

Filter to titles matching `^\s*release\b` (case-insensitive) and choose the one with the latest
`createdAt`. If none is found, **stop** and tell the user no release ticket exists — do not invent
versions. If you find more than one, report them and confirm which to use.

## Step 2 — Extract the backend and frontend versions

From the chosen ticket's body, find the version that follows the word `backend` and the version that
follows the word `frontend` (both case-insensitive). Be format-flexible: the version may be separated
by a space, colon, dash, or "v", and may live in a bullet, table, or sentence. A version is a
dotted-number token like `2026.06.1`. This Python snippet captures the first version token appearing
after each keyword:

```bash
gh issue view <NUMBER> --repo xchem/fragalysis-stack --json body -q .body | python3 -c '
import re, sys
body = sys.stdin.read()
def find(keyword):
    m = re.search(rf"{keyword}\b\D*?(\d+(?:\.\d+)+)", body, re.IGNORECASE)
    return m.group(1) if m else None
be, fe = find("backend"), find("frontend")
print(f"BE_IMAGE_TAG={be}")
print(f"FE_IMAGE_TAG={fe}")
'
```

If either version is missing or doesn't look like a valid tag, **stop** and ask the user — never guess.
Show both extracted versions to the user and confirm they are correct before changing any files.

## Step 3 — Generate the stack tag

The stack tag is generated automatically as `YYYY.MM.ITERATION`, where `YYYY.MM` is the **current**
year and month and `ITERATION` is one greater than the highest iteration already used in tags for this
same year/month (starting at `1` if there are none). For example, in June 2026, if `2026.06.1` already
exists the new tag is `2026.06.2`; if no `2026.06.*` tag exists yet it is `2026.06.1`.

Compute it from the existing remote tags so nothing local/stale is missed:

```bash
git ls-remote --tags origin | sed -E 's#.*refs/tags/##; s/\^\{\}$//' | sort -u | python3 -c '
import sys, datetime, re
prefix = datetime.date.today().strftime("%Y.%m")  # e.g. 2026.06
highest = 0
for line in sys.stdin:
    m = re.fullmatch(rf"{re.escape(prefix)}\.(\d+)", line.strip())
    if m:
        highest = max(highest, int(m.group(1)))
print(f"{prefix}.{highest + 1}")
'
```

This is a `YYYY.MM.N` tag, so it will deploy to production. Show the generated tag to the user and
confirm before using it.

## Step 4 — Update the build workflow

Edit `.github/workflows/build-main.yaml` and set the two values under the top-level `env:` block to the
versions from Step 2:

```yaml
  BE_IMAGE_TAG: <backend version>
  FE_IMAGE_TAG: <frontend version>
```

Change only these two lines. Show the diff (`git diff .github/workflows/build-main.yaml`).

## Step 5 — Commit to master

Per `CLAUDE.md`, this change is committed directly to `master`. Confirm the working tree is on `master`
and otherwise clean. Use a message matching the existing history style (`git log --oneline -5`), e.g.:

```
build: Use of b/e <backend version> f/e <frontend version>
```

After confirming with the user, commit and push:

```bash
git add .github/workflows/build-main.yaml
git commit -m "build: Use of b/e <backend version> f/e <frontend version>"
git push origin master
```

## Step 6 — Tag the stack release

After the commit is pushed, create the release/tag (this is what triggers the build + deploy). Confirm
with the user first, then:

```bash
gh release create <stack tag> --repo xchem/fragalysis-stack \
  --title "<stack tag>" \
  --notes "Stack release using backend <backend version> and frontend <frontend version> (ticket #<NUMBER>)."
```

## Step 7 — Report and close out

- Link the triggered workflow run (`gh run list --repo xchem/fragalysis-stack --limit 3`) so the user
  can watch the ~10–20 min build/deploy.
- Ask whether to comment on and/or close the release ticket (#<NUMBER>) referencing the new tag. Only do
  so if the user agrees.

## Guardrails

- Never fabricate versions or a tag — if anything is ambiguous or missing, stop and ask.
- Confirm with the user before each outward-facing action: the commit/push (Step 5) and the tag (Step 6).
- Only the two `*_IMAGE_TAG` lines in the workflow should change.
