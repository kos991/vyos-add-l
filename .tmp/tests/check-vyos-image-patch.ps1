param(
    [string]$VyOSBuildRoot = ".tmp/cache/vyos-build-current"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$vyosBuild = Resolve-Path (Join-Path $repoRoot $VyOSBuildRoot)
$patchPath = Join-Path $repoRoot "patches/vyos-build/0015-add-nexttrace-and-landscape.patch"

& 'C:\Program Files\Git\cmd\git.exe' -C $vyosBuild reset --hard HEAD | Out-Null
& 'C:\Program Files\Git\cmd\git.exe' -C $vyosBuild apply --check $patchPath
if ($LASTEXITCODE -ne 0) {
    throw "VyOS image patch check failed"
}

