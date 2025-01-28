param(
  [Parameter(Position = 0, Mandatory = $true)]
  [ValidateSet("desktop", "core")]
  [string]$type
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$installDir = Join-Path (Get-Item $scriptDir).FullName $type

Write-Host "Using install directory: $installDir"

# Define paths
$mkisofsExe = Join-Path $scriptDir "mkisofs.exe"
$sourceDir = Join-Path $installDir "secondary_iso"
$outputIso = Join-Path $installDir "secondary.iso"

# Verify paths exist
if (-not (Test-Path $mkisofsExe)) {
  throw "mkisofs.exe not found at: $mkisofsExe"
}
if (-not (Test-Path $sourceDir)) {
  throw "Source directory not found at: $sourceDir"
}

# https://developer.hashicorp.com/packer/integrations/hashicorp/hyperv/latest/components/builder/iso#creating-an-iso-from-a-directory
$mkisofsArgs = @(
  "-r", # rationalized Rock Ridge directory info
  "-iso-level 4",
  "-UDF",
  "-V", "Secondary", # Volume label
  "-output", $outputIso, # Output file
  $sourceDir      # Source directory
)

Write-Host "Creating ISO from $sourceDir"
Write-Host "Using command: $mkisofsExe $($mkisofsArgs -join ' ')"

try {
  & $mkisofsExe $mkisofsArgs
  if ($LastExitCode -ne 0) {
    throw "mkisofs failed with exit code $LastExitCode"
  }
  Write-Host "ISO created successfully at: $outputIso"
}
catch {
  Write-Error "Failed to create ISO: $_"
  exit 1
}