$ErrorActionPreference = "Stop"

$targets = @(
  (Join-Path $env:USERPROFILE ".codex\skills\imagegen\SKILL.md"),
  (Join-Path $env:USERPROFILE ".codex\skills\.system\imagegen\SKILL.md")
)

$marker = "<!-- image-gen-fuck-link -->"
$insert = @'
<!-- image-gen-fuck-link -->

## Companion Skill: image-gen-fuck

When the built-in `image_gen` tool is not exposed or unavailable, and the companion skill exists at:

```text
%USERPROFILE%\.codex\skills\image-gen-fuck\SKILL.md
```

load and follow `$image-gen-fuck` before deciding that CLI fallback is blocked. In that case, prefer its wrapper:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\image-gen-fuck\scripts\invoke_imagegen_cli.ps1" -ShowConfig
```

If `effectiveHasApiKey` is `true`, CLI fallback is configured even when the current shell does not already have a global `OPENAI_API_KEY`. Use the same wrapper for `generate`, `edit`, and `generate-batch` commands instead of calling `scripts/image_gen.py` directly. The wrapper reads Codex++ settings or the fallback key file, temporarily sets `OPENAI_API_KEY` and `OPENAI_BASE_URL` for the Python child process, and restores the previous environment afterward.

Do not ask the user to set a persistent `OPENAI_API_KEY` when `$image-gen-fuck` reports `effectiveHasApiKey: true`.
'@

$replacementMap = [ordered]@{
  '- **Fallback CLI mode:** `scripts/image_gen.py` CLI. Use when the user explicitly asks for the CLI/API/model path, or after the user explicitly confirms a true model-native transparency fallback with `gpt-image-1.5`. Requires `OPENAI_API_KEY`.' =
    '- **Fallback CLI mode:** `scripts/image_gen.py` CLI. Use when the user explicitly asks for the CLI/API/model path, or after the user explicitly confirms a true model-native transparency fallback with `gpt-image-1.5`. Requires `OPENAI_API_KEY` unless the companion `$image-gen-fuck` skill is installed and its wrapper reports `effectiveHasApiKey: true`.'
  '- If the built-in tool fails or is unavailable, tell the user the CLI fallback exists and that it requires `OPENAI_API_KEY`. Proceed only if the user explicitly asks for that fallback.' =
    '- If the built-in tool fails or is unavailable, tell the user the CLI fallback exists. If `$image-gen-fuck` is installed, check its wrapper config before saying `OPENAI_API_KEY` is missing. Proceed only if the user explicitly asks for that fallback.'
  '- If the user explicitly asks for CLI mode, use the bundled `scripts/image_gen.py` workflow. Do not create one-off SDK runners.' =
    '- If the user explicitly asks for CLI mode, use the bundled `scripts/image_gen.py` workflow. If `$image-gen-fuck` is installed, invoke it through `$image-gen-fuck`''s `scripts/invoke_imagegen_cli.ps1` wrapper. Do not create one-off SDK runners.'
  '17. If the user explicitly chooses or confirms the CLI fallback, then use the fallback-only docs for model, quality, size, `input_fidelity`, masks, output format, and output paths.' =
    '17. If the user explicitly chooses or confirms the CLI fallback, then use the fallback-only docs for model, quality, size, `input_fidelity`, masks, output format, and output paths. If `$image-gen-fuck` is installed, load it and use its wrapper for the actual CLI invocation.'
  '- `OPENAI_API_KEY` must be set for live API calls.' =
    '- `OPENAI_API_KEY` must be set for direct live API calls. If `$image-gen-fuck` is installed, its wrapper may provide `OPENAI_API_KEY` temporarily from Codex++ settings or the fallback key file.'
}

foreach ($target in $targets) {
  if (-not (Test-Path -LiteralPath $target)) {
    Write-Warning "Missing target: $target"
    continue
  }

  $backup = "$target.bak-image-gen-fuck-link-$(Get-Date -Format yyyyMMdd-HHmmss)"
  Copy-Item -LiteralPath $target -Destination $backup -Force

  $content = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
  $pattern = "(?s)<!-- image-gen-fuck-link -->.*?(?=\r?\n## When to use)"
  if ([regex]::IsMatch($content, $pattern)) {
    $content = [regex]::Replace($content, $pattern, $insert.TrimEnd() + "`r`n")
  } else {
    $anchor = "## When to use"
    $index = $content.IndexOf($anchor)
    if ($index -lt 0) {
      throw "Cannot find anchor '$anchor' in $target"
    }
    $content = $content.Insert($index, $insert.TrimEnd() + "`r`n`r`n")
  }

  foreach ($entry in $replacementMap.GetEnumerator()) {
    $content = $content.Replace($entry.Key, $entry.Value)
  }

  [System.IO.File]::WriteAllText($target, $content, [System.Text.UTF8Encoding]::new($false))
  Write-Host "Linked image-gen-fuck in: $target"
  Write-Host "Backup: $backup"
}
