[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("2.0", "2.1")]
  [string]$FactorioVersion,

  [ValidatePattern("^\d+\.\d+\.\d+$")]
  [string]$ModVersion
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$versions = @{ "2.0" = "0.2.6"; "2.1" = "0.2.7" }
if (-not $ModVersion) {
  $ModVersion = $versions[$FactorioVersion]
}

$outputDirectory = Join-Path $projectRoot ("dist\\Factorio-" + $FactorioVersion)
$archivePath = Join-Path $outputDirectory ("quick-swap-belt_" + $ModVersion + ".zip")
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("quick-swap-belt-" + [guid]::NewGuid())
$stagingDirectory = Join-Path $temporaryRoot ("quick-swap-belt_" + $ModVersion)

try {
  New-Item -ItemType Directory -Path $stagingDirectory -Force | Out-Null
  foreach ($item in Get-ChildItem -LiteralPath $projectRoot -Force) {
    if ($item.Name -notin @(".git", "dist")) {
      Copy-Item -LiteralPath $item.FullName -Destination $stagingDirectory -Recurse -Force
    }
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
    Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
  }
}
