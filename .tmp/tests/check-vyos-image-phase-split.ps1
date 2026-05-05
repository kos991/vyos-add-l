$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scriptPath = Join-Path $repoRoot "scripts/patch-and-build-vyos-image.sh"
$workflowPath = Join-Path $repoRoot ".github/workflows/build-vyos.yml"

$script = Get-Content -Raw $scriptPath
$workflow = Get-Content -Raw $workflowPath

foreach ($required in @(
    "VYOS_IMAGE_PHASE",
    "prepare)",
    "dry-run)",
    "build)",
    "--dry-run"
)) {
    if (-not $script.Contains($required)) {
        throw "Missing image script phase marker: $required"
    }
}

foreach ($required in @(
    "Prepare VyOS image inputs",
    "Validate VyOS image configuration",
    "VYOS_IMAGE_PHASE=prepare",
    "VYOS_IMAGE_PHASE=dry-run",
    "VYOS_IMAGE_PHASE=build"
)) {
    if (-not $workflow.Contains($required)) {
        throw "Missing workflow image phase marker: $required"
    }
}

$prepareIndex = $workflow.IndexOf("Prepare VyOS image inputs")
$validateIndex = $workflow.IndexOf("Validate VyOS image configuration")
$buildIndex = $workflow.IndexOf("Build VyOS image")
if (-not (($prepareIndex -lt $validateIndex) -and ($validateIndex -lt $buildIndex))) {
    throw "Workflow image phases are not ordered prepare -> validate -> build"
}

