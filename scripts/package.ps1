$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$root = (Get-Location).Path
$release = Join-Path $root 'build/windows/x64/runner/Release'
$apk = Join-Path $root 'build/app/outputs/flutter-apk/app-release.apk'
if (!(Test-Path "$release/word_contacts.exe") -or !(Test-Path $apk)) { throw 'Missing release executable or APK; build both first.' }
$portable = Join-Path $root 'dist/windows/WordContactsPortable'
if (Test-Path $portable) { throw 'Portable folder already exists; move or back up its data before packaging.' }
New-Item -ItemType Directory -Force $portable, "$portable/data", "$portable/backups", 'dist/android', 'dist/source' | Out-Null
Copy-Item "$release/*" $portable -Recurse
# Include the redistributable MSVC runtime required on clean Windows machines.
$crt = $null
if ($env:VCToolsRedistDir) {
  $crt = Get-ChildItem "$env:VCToolsRedistDir/x64" -Directory -Filter 'Microsoft.VC*.CRT' | Select-Object -First 1
}
if (!$crt) {
  $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
  if (Test-Path $vswhere) {
    $vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vs) { $crt = Get-ChildItem "$vs/VC/Redist/MSVC/*/x64/Microsoft.VC*.CRT" -Directory | Sort-Object FullName -Descending | Select-Object -First 1 }
  }
}
if (!$crt) { throw 'MSVC x64 redistributable DLLs missing. Install Visual Studio C++ redistributables and rerun packaging.' }
Copy-Item "$($crt.FullName)/*.dll" $portable
# Also include runtime DLLs in the installer source tree.
Copy-Item "$($crt.FullName)/*.dll" $release
Copy-Item docs/portable_README.txt "$portable/README.txt"
Copy-Item $apk dist/android/WordContacts.apk
Compress-Archive -Path $portable -DestinationPath dist/windows/WordContactsPortable.zip -Force
$source = Join-Path ([IO.Path]::GetTempPath()) ('WordContactsSource-' + [guid]::NewGuid())
try {
  New-Item -ItemType Directory $source | Out-Null
  foreach ($name in @('lib','android','windows','test','scripts','installer','docs','pubspec.yaml','pubspec.lock','analysis_options.yaml','README.md','.gitignore')) {
    if (Test-Path $name) { Copy-Item $name $source -Recurse }
  }
  Get-ChildItem $source -Recurse -Force -File | Where-Object { $_.Name -match '\.(db|jks|keystore)$' -or $_.Name -in @('key.properties','local.properties') -or $_.FullName -match '[\\/](build|\.gradle|\.dart_tool)[\\/]' } | Remove-Item -Force
  Get-ChildItem $source -Directory -Recurse -Force | Where-Object { $_.Name -in @('build', '.gradle', '.dart_tool', 'ephemeral') } | Sort-Object { $_.FullName.Length } -Descending | Remove-Item -Recurse -Force
  Compress-Archive -Path "$source/*" -DestinationPath dist/source/WordContacts_Source.zip -Force
} finally { Remove-Item $source -Recurse -Force }
