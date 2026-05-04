param(
    [string]$VyOSBuildRoot = ".tmp/cache/vyos-build-current"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$vyosBuild = Resolve-Path (Join-Path $repoRoot $VyOSBuildRoot)
$patchPath = Join-Path $repoRoot "patches/vyos-build/0011-build-linux-package-toml.patch"
$packageToml = Join-Path $vyosBuild "scripts/package-build/linux-kernel/package.toml"

& 'C:\Program Files\Git\cmd\git.exe' -C $vyosBuild reset --hard HEAD | Out-Null
& 'C:\Program Files\Git\cmd\git.exe' -C $vyosBuild apply --ignore-space-change $patchPath
if ($LASTEXITCODE -ne 0) {
    throw "Failed to apply linux kernel package patch"
}

try {
    $text = Get-Content -Raw $packageToml
    $match = [regex]::Match(
        $text,
        '(?s)\[\[packages\]\]\s*name = "linux-firmware"\s*commit_id = "([^"]+)"\s*scm_url = "([^"]+)"'
    )
    if (-not $match.Success) {
        throw "linux-firmware package block not found"
    }

    $commitId = $match.Groups[1].Value
    $scmUrl = $match.Groups[2].Value
    & 'C:\Program Files\Git\cmd\git.exe' ls-remote --exit-code $scmUrl $commitId | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "linux-firmware ref not found: $scmUrl $commitId"
    }
}
finally {
    & 'C:\Program Files\Git\cmd\git.exe' -C $vyosBuild reset --hard HEAD | Out-Null
}

