$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw 'Windows build failed' }
