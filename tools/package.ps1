[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("2.0", "2.1")]
  [string]$FactorioVersion,

  [ValidatePattern("^\d+\.\d+\.\d+$")]
  [string]$ModVersion
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$versions = @{ "2.0" = "0.3.6"; "2.1" = "0.3.7" }
if (-not $ModVersion) {
  $ModVersion = $versions[$FactorioVersion]
}

$outputDirectory = Join-Path $projectRoot ("dist\\Factorio-" + $FactorioVersion)
$archivePath = Join-Path $outputDirectory ("quick-swap_" + $ModVersion + ".zip")
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("quick-swap-" + [guid]::NewGuid())
$stagingDirectory = Join-Path $temporaryRoot ("quick-swap_" + $ModVersion)

try {
  New-Item -ItemType Directory -Path $stagingDirectory -Force | Out-Null
  # Explicit release contents keep local settings and future development files out.
  foreach ($name in @("info.json", "control.lua", "data.lua", "scripts", "locale",
      "thumbnail.png", "changelog.txt", "README.md", "docs")) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $name) -Destination $stagingDirectory -Recurse -Force -ErrorAction Stop
  }

  $manifestPath = Join-Path $stagingDirectory "info.json"
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
  $manifest.version = $ModVersion
  $manifest.factorio_version = $FactorioVersion
  $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding utf8

  New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
  if (Test-Path -LiteralPath $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force
  }
  Compress-Archive -LiteralPath $stagingDirectory -DestinationPath $archivePath -CompressionLevel Optimal
  Write-Output "Created $archivePath"
}
finally {
  if (Test-Path -LiteralPath $temporaryRoot) {
    $resolvedStagingRoot = [System.IO.Path]::GetFullPath($temporaryRoot)
    $expectedTempParent = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\')
    if ((Split-Path -Parent $resolvedStagingRoot) -ne $expectedTempParent -or
        (Split-Path -Leaf $resolvedStagingRoot) -notlike "quick-swap-*") {
      throw "Refusing to remove an unexpected staging path: $resolvedStagingRoot"
    }
    Remove-Item -LiteralPath $resolvedStagingRoot -Recurse -Force
  }
}
