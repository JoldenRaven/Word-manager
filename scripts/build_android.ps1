$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw 'Android build failed' }
