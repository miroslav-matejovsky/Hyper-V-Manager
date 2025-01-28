# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (!(Test-Path -Path "logs")) {
  New-Item -ItemType Directory -Path "logs"
}

$env:PACKER_LOG = 1
$env:PACKER_LOG_PATH = "logs/packer.log"