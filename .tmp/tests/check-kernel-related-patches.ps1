param(
    [string]$VyOSBuildRoot = ".tmp/cache/vyos-build-current"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$vyosBuild = Resolve-Path (Join-Path $repoRoot $VyOSBuildRoot)
$patches = @(
    "patches/vyos-build/0011-build-linux-package-toml.patch",
    "patches/vyos-build/0013-build-linux-firmware.patch",
    "patches/vyos-build/0014-build-qat.patch"
)

foreach ($patch in $patches) {
    $patchPath = Join-Path $repoRoot $patch
    & 'C:\Program Files\Git\cmd\git.exe' -C $vyosBuild apply --check --ignore-space-change $patchPath
    if ($LASTEXITCODE -ne 0) {
        throw "Patch check failed: $patch"
    }
}
