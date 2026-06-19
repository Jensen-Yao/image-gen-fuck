param(
  [Parameter(Position = 0)]
  [ValidateSet("generate", "edit", "generate-batch")]
  [string]$Command = "",
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$ImageGenArgs = @(),
  [switch]$ShowConfig
)

$ErrorActionPreference = "Stop"

function Read-JsonObject([string]$Path) {
  if (Test-Path -LiteralPath $Path) {
    try {
      return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    } catch {
      Write-Warning "Existing JSON could not be parsed: $Path"
    }
  }
  return $null
}

function Get-PropertyValue($Object, [string]$Name, $Default = $null) {
  if ($Object -and ($Object.PSObject.Properties.Name -contains $Name)) {
    return $Object.$Name
  }
  return $Default
}

function Get-EnvSnapshot([string[]]$Names) {
  $snapshot = @{}
  foreach ($name in ($Names | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)) {
    $item = Get-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    $snapshot[$name] = if ($item) { [string]$item.Value } else { $null }
  }
  return $snapshot
}

function Restore-EnvSnapshot($Snapshot) {
  foreach ($name in $Snapshot.Keys) {
    if ($null -eq $Snapshot[$name]) {
      Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
    } else {
      Set-Item -LiteralPath "Env:$name" -Value $Snapshot[$name]
    }
  }
}

$settingsPath = Join-Path $env:APPDATA "Codex++\settings.json"
$secretPath = Join-Path $env:USERPROFILE ".codex\secrets\imagegen-openai-key.txt"
$imageGenCli = Join-Path $env:USERPROFILE ".codex\skills\.system\imagegen\scripts\image_gen.py"
$settings = Read-JsonObject $settingsPath

$enabled = [bool](Get-PropertyValue $settings "cliWrapperEnabled" $false)
$settingsKey = [string](Get-PropertyValue $settings "cliWrapperApiKey" "")
$secretKey = if (Test-Path -LiteralPath $secretPath) { (Get-Content -LiteralPath $secretPath -Raw).Trim() } else { "" }
$apiKey = if ($enabled -and -not [string]::IsNullOrWhiteSpace($settingsKey)) { $settingsKey.Trim() } else { $secretKey }
$baseUrl = if ($enabled -and -not [string]::IsNullOrWhiteSpace([string](Get-PropertyValue $settings "cliWrapperBaseUrl" ""))) {
  [string](Get-PropertyValue $settings "cliWrapperBaseUrl" "")
} else {
  "https://code.codingplay.top/v1"
}
$envName = if ($enabled -and -not [string]::IsNullOrWhiteSpace([string](Get-PropertyValue $settings "cliWrapperApiKeyEnv" ""))) {
  [string](Get-PropertyValue $settings "cliWrapperApiKeyEnv" "")
} else {
  "OPENAI_API_KEY"
}

if ($ShowConfig) {
  [pscustomobject]@{
    cliWrapperEnabled = $enabled
    cliWrapperBaseUrl = $baseUrl
    cliWrapperApiKeyEnv = $envName
    settingsHasApiKey = -not [string]::IsNullOrWhiteSpace($settingsKey)
    secretFileExists = Test-Path -LiteralPath $secretPath
    effectiveHasApiKey = -not [string]::IsNullOrWhiteSpace($apiKey)
    imageGenCliExists = Test-Path -LiteralPath $imageGenCli
    settingsPath = $settingsPath
    secretPath = $secretPath
    imageGenCli = $imageGenCli
  } | ConvertTo-Json -Depth 5
  exit 0
}

if ([string]::IsNullOrWhiteSpace($Command)) {
  throw "Command is required. Use generate, edit, or generate-batch."
}

if ([string]::IsNullOrWhiteSpace($apiKey)) {
  throw "ImageGen API key is missing. Configure Codex++ settings or create: $secretPath"
}

if (-not (Test-Path -LiteralPath $imageGenCli)) {
  throw "Cannot find image_gen.py: $imageGenCli"
}

$envNames = @($envName, "OPENAI_API_KEY", "OPENAI_BASE_URL")
$snapshot = Get-EnvSnapshot $envNames

try {
  Set-Item -LiteralPath "Env:$envName" -Value $apiKey
  $env:OPENAI_API_KEY = $apiKey
  $env:OPENAI_BASE_URL = $baseUrl.Trim()

  & python $imageGenCli $Command @ImageGenArgs
  $exitCode = if ($LASTEXITCODE -is [int]) { $LASTEXITCODE } else { 0 }
} finally {
  Restore-EnvSnapshot $snapshot
}

exit $exitCode
