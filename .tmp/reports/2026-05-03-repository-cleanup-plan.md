# Repository Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the repository documentation, scripts, and CI consistent with the current `kos991/vyos-add-l` amd64 VyOS ISO build flow.

**Architecture:** Keep the repository shape stable and modify existing files only. Documentation states the supported build path, shell scripts fail early with clear checks, and GitHub Actions gains a fast validation job before the long build job.

**Tech Stack:** Markdown, Bash, GitHub Actions YAML, PowerShell validation commands for local Windows checks.

---

## File Structure

- Modify `README.md`: primary project overview, supported build target, build flow, and removal of stale arm64/SD-card references.
- Modify `LANDSCAPE-QUICKSTART.md`: quickstart links, repository name, branch, amd64 target, and GitHub Actions links.
- Modify `LANDSCAPE-INTEGRATION.md`: repository links and supported build target references.
- Modify `scripts/build-all.sh`: defensive shell mode, tool checks, quoted paths, and explicit environment exports.
- Modify `scripts/patch-and-build-vyos-1x.sh`: defensive shell mode, environment checks, tool checks, and quoted paths.
- Modify `scripts/patch-and-build-kernel.sh`: defensive shell mode, environment checks, tool checks, and quoted paths.
- Modify `scripts/patch-and-build-kernel-related-packages.sh`: defensive shell mode, environment checks, tool checks, and quoted paths.
- Modify `scripts/patch-and-build-vyos-image.sh`: defensive shell mode, environment checks, tool checks, and quoted paths.
- Modify `scripts/build-landscape-package.sh`: defensive shell mode, tool checks, fail-fast downloads, private temp directory, cleanup trap, and quoted paths.
- Modify `scripts/set_kernel_version.sh`: defensive shell mode, environment checks, quoted paths, and missing target file check.
- Modify `.github/workflows/build-vyos.yml`: add a fast validation job and make the existing full build depend on it.

## Task 1: Documentation Consistency

**Files:**
- Modify: `README.md`
- Modify: `LANDSCAPE-QUICKSTART.md`
- Modify: `LANDSCAPE-INTEGRATION.md`

- [ ] **Step 1: Run stale-reference check and confirm it fails**

Run:

```powershell
Select-String -Path README.md,LANDSCAPE-QUICKSTART.md,LANDSCAPE-INTEGRATION.md -Pattern 'KawaiiNetworks/vyos-unofficial|vyos-unofficial|6\.18-main|generate_img\.sh|vyos-arm64-build|huihuimoe|BPI-R4'
```

Expected: FAIL for cleanup purposes by printing existing stale references in the three documentation files.

- [ ] **Step 2: Update `README.md`**

Replace the old project introduction and build flow with content that states:

```markdown
# vyos-add-l

`vyos-add-l` is a personal VyOS build orchestration repository for producing a custom `generic-amd64` VyOS ISO.

The build integrates:

- VyOS rolling packages from upstream `vyos-build` and `vyos-1x`
- Linux kernel `6.18.20`, configured in `build.conf`
- Landscape eBPF Router as the `landscape-router` package
- BPF/BTF/XDP kernel support for eBPF networking
- nexttrace and selected operational packages
- Additional kernel-related packages and firmware used by the current amd64 build flow

## Supported Target

- Architecture: `amd64`
- Image profile: `generic`
- Output: `build/vyos-<version>-generic-amd64.iso`

The previous arm64/BPI-R4 SD-card image notes are not part of the current scripted build flow in this repository.
```

Keep the existing useful wireless example only if it is explicitly marked as historical or hardware-specific, otherwise remove it from the primary quick path.

- [ ] **Step 3: Update Landscape docs**

In `LANDSCAPE-QUICKSTART.md` and `LANDSCAPE-INTEGRATION.md`, replace:

```text
https://github.com/KawaiiNetworks/vyos-unofficial
vyos-unofficial
6.18-main
```

with:

```text
https://github.com/kos991/vyos-add-l
vyos-add-l
master
```

Make all build examples produce or reference `build/vyos-*.iso` for amd64. Remove references to nonexistent `scripts/generate_img.sh`.

- [ ] **Step 4: Re-run stale-reference check**

Run:

```powershell
Select-String -Path README.md,LANDSCAPE-QUICKSTART.md,LANDSCAPE-INTEGRATION.md -Pattern 'KawaiiNetworks/vyos-unofficial|vyos-unofficial|6\.18-main|generate_img\.sh|vyos-arm64-build|huihuimoe'
```

Expected: no output.

- [ ] **Step 5: Commit documentation cleanup**

Run:

```bash
git add README.md LANDSCAPE-QUICKSTART.md LANDSCAPE-INTEGRATION.md
git commit -m "docs: align repository documentation"
```

## Task 2: Shell Script Hardening

**Files:**
- Modify: `scripts/build-all.sh`
- Modify: `scripts/patch-and-build-vyos-1x.sh`
- Modify: `scripts/patch-and-build-kernel.sh`
- Modify: `scripts/patch-and-build-kernel-related-packages.sh`
- Modify: `scripts/patch-and-build-vyos-image.sh`
- Modify: `scripts/build-landscape-package.sh`
- Modify: `scripts/set_kernel_version.sh`

- [ ] **Step 1: Run current script consistency check and confirm it reports issues**

Run:

```powershell
Select-String -Path scripts\*.sh -Pattern 'curl -L|rm -rf \$|cp \$|cd \$|patch -p1 < \$|mv \./\*\.deb \$|sed -i "s/\^kernel_version'
```

Expected: output showing unquoted paths and non-fail-fast downloads.

- [ ] **Step 2: Add common hardening pattern to shell scripts**

At the top of executable build scripts, use:

```bash
#!/bin/bash

set -euo pipefail
```

For `scripts/build-all.sh`, which currently has no shebang, add the same shebang and defensive mode before any variable use.

- [ ] **Step 3: Add environment checks**

For scripts that require `PROJECT_ROOT` and `VYOS_BUILD_ROOT`, add this block near the top after `set -euo pipefail`:

```bash
: "${PROJECT_ROOT:?PROJECT_ROOT is not set}"
: "${VYOS_BUILD_ROOT:?VYOS_BUILD_ROOT is not set}"
```

For `scripts/build-all.sh`, keep it as the root script that computes and exports:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export VYOS_BUILD_ROOT="${PROJECT_ROOT}/vyos-build"
```

- [ ] **Step 4: Add tool checks**

Add `command -v` checks matching each script's commands. Example for `build-landscape-package.sh`:

```bash
for tool in curl dpkg-deb unzip; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "Required tool not found: ${tool}" >&2
        exit 1
    fi
done
```

Use the smallest needed tool list per script:

```text
build-all.sh: git sudo bash
patch-and-build-vyos-1x.sh: git patch
patch-and-build-kernel.sh: cp patch
patch-and-build-kernel-related-packages.sh: patch
patch-and-build-vyos-image.sh: patch cp date mkdir mv
build-landscape-package.sh: curl chmod dpkg-deb mkdir rm unzip
set_kernel_version.sh: sed
```

- [ ] **Step 5: Quote path variables**

Convert path operations to quoted form. Examples:

```bash
cd "${VYOS_BUILD_ROOT}"
cp "${PROJECT_ROOT}/patches/main/linux-kernel-bpf-btf.config" "${VYOS_BUILD_ROOT}/scripts/package-build/linux-kernel/config/00-bpf-btf.config"
mv ./*.deb "${VYOS_BUILD_ROOT}/packages/"
```

Keep globs such as `./*.deb` unquoted where glob expansion is intended.

- [ ] **Step 6: Harden Landscape package downloads**

In `scripts/build-landscape-package.sh`, replace `/tmp/static.zip` and static build paths with a private temp root:

```bash
BUILD_DIR="$(mktemp -d)"
INSTALL_DIR="${BUILD_DIR}/install"
STATIC_ZIP="${BUILD_DIR}/static.zip"
trap 'rm -rf "${BUILD_DIR}"' EXIT
```

Use fail-fast downloads:

```bash
curl --fail --location --show-error -o "${INSTALL_DIR}/opt/vyos/landscape/landscape-webserver" \
    "https://github.com/ThisSeanZhang/landscape/releases/download/v${LANDSCAPE_VERSION}/landscape-webserver-${LANDSCAPE_ARCH}"

curl --fail --location --show-error -o "${STATIC_ZIP}" \
    "https://github.com/ThisSeanZhang/landscape/releases/download/v${LANDSCAPE_VERSION}/static.zip"
```

- [ ] **Step 7: Re-run script consistency check**

Run:

```powershell
Select-String -Path scripts\*.sh -Pattern 'curl -L|/tmp/static\.zip|rm -rf \$\{|cp \$PROJECT_ROOT|cd \$VYOS_BUILD_ROOT|patch -p1 < \$PROJECT_ROOT|sed -i "s/\^kernel_version'
```

Expected: no output for the stale unsafe patterns.

- [ ] **Step 8: Commit script hardening**

Run:

```bash
git add scripts/*.sh
git commit -m "build: harden build scripts"
```

## Task 3: Fast CI Validation

**Files:**
- Modify: `.github/workflows/build-vyos.yml`

- [ ] **Step 1: Confirm workflow lacks fast validation**

Run:

```powershell
Select-String -Path .github\workflows\build-vyos.yml -Pattern 'fast_validation|Validate shell scripts|Validate documentation references|Validate patch references'
```

Expected: no output.

- [ ] **Step 2: Add a fast validation job before the full build**

Add this job before `build_and_release`:

```yaml
  fast_validation:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.inputs.ref || github.ref_name }}

      - name: Validate shell scripts
        run: |
          bash -n scripts/*.sh

      - name: Validate documentation references
        run: |
          ! grep -R -n -E 'KawaiiNetworks/vyos-unofficial|vyos-unofficial|6\.18-main|generate_img\.sh|vyos-arm64-build|huihuimoe' \
            README.md LANDSCAPE-QUICKSTART.md LANDSCAPE-INTEGRATION.md

      - name: Validate script patch references
        run: |
          python3 - <<'PY'
          from pathlib import Path
          import re
          missing = []
          for script in Path("scripts").glob("*.sh"):
              text = script.read_text(encoding="utf-8")
              for match in re.finditer(r"\$PROJECT_ROOT/(patches/[^\\s\"']+)", text):
                  path = Path(match.group(1))
                  if not path.exists():
                      missing.append(f"{script}: {path}")
          if missing:
              raise SystemExit("Missing patch references:\n" + "\n".join(missing))
          PY
```

Set the existing `build_and_release` job to depend on it:

```yaml
    needs: fast_validation
```

- [ ] **Step 3: Validate YAML text locally**

Run:

```powershell
Select-String -Path .github\workflows\build-vyos.yml -Pattern 'fast_validation|needs: fast_validation|Validate shell scripts|Validate documentation references|Validate script patch references'
```

Expected: output for all required CI validation markers.

- [ ] **Step 4: Commit CI validation**

Run:

```bash
git add .github/workflows/build-vyos.yml
git commit -m "ci: add fast repository validation"
```

## Final Verification

- [ ] **Step 1: Run repository stale-reference check**

```powershell
Select-String -Path README.md,LANDSCAPE-QUICKSTART.md,LANDSCAPE-INTEGRATION.md -Pattern 'KawaiiNetworks/vyos-unofficial|vyos-unofficial|6\.18-main|generate_img\.sh|vyos-arm64-build|huihuimoe'
```

Expected: no output.

- [ ] **Step 2: Run local patch-reference check with PowerShell**

```powershell
$missing = @()
Get-ChildItem scripts -Filter *.sh | ForEach-Object {
  $script = $_
  Select-String -Path $script.FullName -Pattern '\$PROJECT_ROOT/(patches/[^ "'']+)' -AllMatches | ForEach-Object {
    foreach ($match in $_.Matches) {
      $path = Join-Path (Get-Location) $match.Groups[1].Value
      if (-not (Test-Path $path)) {
        $missing += "$($script.Name): $($match.Groups[1].Value)"
      }
    }
  }
}
if ($missing.Count -gt 0) {
  $missing
  exit 1
}
```

Expected: no output and exit code 0.

- [ ] **Step 3: Run Git Bash syntax check if available**

```powershell
& 'C:\Program Files\Git\bin\bash.exe' -n scripts/*.sh
```

Expected: exit code 0. If local Git Bash fails with a Windows runtime error, record that local limitation and rely on the CI Linux validation job for shell syntax.

- [ ] **Step 4: Check final Git state**

```bash
git status --short
git log --oneline -5
```

Expected: clean worktree after the final commit, with the design and cleanup commits visible.
