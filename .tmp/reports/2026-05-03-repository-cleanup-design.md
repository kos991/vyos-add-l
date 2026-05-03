# Repository Cleanup Design

## Goal

Clean up the repository so a maintainer can understand and verify the VyOS build project without running a full multi-hour ISO build.

## Current Problems

- Documentation still references `KawaiiNetworks/vyos-unofficial`, `6.18-main`, arm64/BPI-R4 flows, and a missing `scripts/generate_img.sh` file.
- Build scripts assume required environment variables, tools, and upstream directories are present, but failures are not always explicit.
- Download steps for Landscape artifacts do not fail fast on HTTP errors and do not isolate temporary files well.
- CI has only the long VyOS build path. There is no quick validation for shell syntax, stale documentation references, or missing patch/script references.

## Scope

### Documentation

- Update README and Landscape documentation to describe this repository as `kos991/vyos-add-l`.
- Make the primary supported build target explicit: `generic-amd64` VyOS ISO.
- Remove or clearly mark stale arm64/SD-card image instructions that do not match the current scripts.
- Remove references to `scripts/generate_img.sh` unless the file is restored later.
- Keep Landscape usage documentation, but align links and commands with this repository.

### Scripts

- Add defensive shell settings where practical: `set -euo pipefail`.
- Quote variable expansions that represent paths.
- Add explicit environment checks for `PROJECT_ROOT` and `VYOS_BUILD_ROOT` before scripts use them.
- Add explicit tool checks for commands used by each script, such as `git`, `patch`, `curl`, `unzip`, and `dpkg-deb`.
- Change Landscape downloads to fail fast with `curl --fail --location --show-error`.
- Use a script-owned temporary directory for Landscape package assembly and cleanup it predictably.
- Keep the build order and package list unchanged.

### CI

- Add a fast validation job separate from the existing full build job.
- Validate shell script syntax without running the build.
- Validate that script-referenced patch files exist.
- Validate that documentation no longer contains known stale repository references.
- Keep the existing full build and release behavior unchanged.

## Out Of Scope

- No Landscape version upgrade.
- No kernel patch behavior changes.
- No package list changes.
- No architecture expansion beyond the current `amd64` build flow.
- No full local ISO build as part of this cleanup.

## Validation

- Run the new fast validation command locally if the local shell environment allows it.
- Run equivalent PowerShell checks for repository consistency when Linux shell execution is unavailable.
- Confirm `git status --short` shows only intentional files.
- CI should catch stale docs, missing patch references, and shell syntax errors before the long build job starts.

## Risks

- Shell syntax validation may require Git Bash, WSL, or a Linux CI runner; local Windows Git Bash can fail independently of script correctness.
- Upstream `vyos-build` and `vyos-1x` are still unpinned, so patch drift remains possible outside the fast checks.
- Existing Chinese documentation may need careful encoding preservation during edits.
