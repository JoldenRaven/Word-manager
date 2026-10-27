$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
New-Item -ItemType Directory -Force dist | Out-Null
$steps = [System.Collections.Generic.List[string]]::new()
try {
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Install Flutter stable and add it to PATH.' }
foreach ($argsList in @(@('pub','get'), @('analyze'), @('test'))) {
  & flutter @argsList
  if ($LASTEXITCODE -ne 0) { throw "Flutter $argsList failed" }
  $steps.Add("PASS: flutter $argsList")
}
& "$PSScriptRoot/build_windows.ps1"
$steps.Add("PASS: Windows release build")
& "$PSScriptRoot/build_android.ps1"
$steps.Add("PASS: Android release build")
& "$PSScriptRoot/package.ps1"
$steps.Add("PASS: portable, APK and source packaging")
$iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue
if (!$iscc) {
  $candidate = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6/ISCC.exe'
  if (Test-Path $candidate) { $iscc = $candidate }
}
$installerStatus = 'Not built: Inno Setup unavailable.'
if ($iscc) { & $iscc installer/WordContacts.iss; if ($LASTEXITCODE -ne 0) { throw 'Installer failed' }; $installerStatus = 'Built in this run.' } else { Write-Warning 'Inno Setup 6 not found; install it and run ISCC.exe installer/WordContacts.iss.' }
$steps.Add("Installer: $installerStatus")
@("# Build report", "Date: $(Get-Date -Format o)", 'flutter pub get, analyze, test, Windows release and Android release completed successfully.', "Installer: $installerStatus", 'Manual platform acceptance remains to be performed.') | Set-Content dist/BUILD_REPORT.md -Encoding UTF8

} catch {
  $steps.Add("FAILED: $($_.Exception.Message)")
  throw
} finally {
  @('# Build results', "Date: $(Get-Date -Format o)", $steps, 'Manual Windows/Android acceptance: not performed by this script.') | Set-Content dist/TEST_REPORT.md -Encoding UTF8
}
