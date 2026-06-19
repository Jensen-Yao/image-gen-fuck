param(
  [switch]$SkipCodexPlus,
  [switch]$Force
)

$ErrorActionPreference = "Stop"

function Ensure-Directory([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Read-JsonObject([string]$Path) {
  if (Test-Path -LiteralPath $Path) {
    try {
      return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
      $backup = "$Path.bak-invalid-$(Get-Date -Format yyyyMMdd-HHmmss)"
      Copy-Item -LiteralPath $Path -Destination $backup -Force
      Write-Warning "Existing JSON could not be parsed. Backed up to: $backup"
    }
  }
  return [pscustomobject]@{}
}

function Set-Property($Object, [string]$Name, $Value) {
  if ($Object.PSObject.Properties.Name -contains $Name) {
    $Object.$Name = $Value
  } else {
    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
  }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillSource = Join-Path $repoRoot "skills\image-gen-fuck"
$skillDest = Join-Path $env:USERPROFILE ".codex\skills\image-gen-fuck"

if (-not (Test-Path -LiteralPath $skillSource)) {
  throw "Cannot find skill source: $skillSource"
}

Ensure-Directory (Split-Path -Parent $skillDest)
if ((Test-Path -LiteralPath $skillDest) -and -not $Force) {
  $backup = "$skillDest.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
  Copy-Item -LiteralPath $skillDest -Destination $backup -Recurse -Force
  Write-Host "Existing skill backed up: $backup"
}
Copy-Item -LiteralPath $skillSource -Destination (Split-Path -Parent $skillDest) -Recurse -Force
Write-Host "Installed skill: $skillDest"

if (-not $SkipCodexPlus) {
  $userScriptSource = Join-Path $repoRoot "codex-plus-plus\user_scripts\imagegen-cli-settings.js"
  $codexPlusDir = Join-Path $env:APPDATA "Codex++"
  $userScriptsDir = Join-Path $codexPlusDir "user_scripts"
  $userScriptDest = Join-Path $userScriptsDir "imagegen-cli-settings.js"
  $userScriptsJson = Join-Path $codexPlusDir "user_scripts.json"

  if (-not (Test-Path -LiteralPath $userScriptSource)) {
    throw "Cannot find Codex++ user script source: $userScriptSource"
  }

  Ensure-Directory $userScriptsDir
  if ((Test-Path -LiteralPath $userScriptDest) -and -not $Force) {
    $backup = "$userScriptDest.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item -LiteralPath $userScriptDest -Destination $backup -Force
    Write-Host "Existing user script backed up: $backup"
  }
  Copy-Item -LiteralPath $userScriptSource -Destination $userScriptDest -Force

  Ensure-Directory $codexPlusDir
  $userScriptConfig = Read-JsonObject $userScriptsJson
  Set-Property $userScriptConfig "user:imagegen-cli-settings.js" $true
  $userScriptConfig | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $userScriptsJson -Encoding UTF8

  Write-Host "Installed Codex++ user script: $userScriptDest"
  Write-Host "Enabled Codex++ user script: $userScriptsJson"
}

Write-Host "Done. Restart Codex++ or reload user scripts."
