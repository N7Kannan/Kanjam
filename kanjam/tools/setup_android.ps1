# Windows version of setup_android.sh. Run from the project root:
#   powershell -ExecutionPolicy Bypass -File tools\setup_android.ps1
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'flutter was not found on your PATH' }

if (Test-Path android) {
  Write-Host 'android/ already exists - keeping it and only re-applying branding.'
} else {
  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("kanjam_" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tmp | Out-Null
  # --org + --project-name give the same application id as the original APK: com.kanjam.finance
  flutter create --org com.kanjam --project-name finance --platforms=android (Join-Path $tmp 'scaffold')
  Copy-Item -Recurse (Join-Path $tmp 'scaffold\android') .\android
  Remove-Item -Recurse -Force $tmp
}

$manifest = 'android\app\src\main\AndroidManifest.xml'
(Get-Content $manifest -Raw) -replace 'android:label="[^"]*"', 'android:label="KANJAM"' | Set-Content $manifest -NoNewline

Copy-Item -Recurse -Force 'android_overrides\res\*' 'android\app\src\main\res\'

$launch = @'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/black" />
</layer-list>
'@
foreach ($dir in 'drawable', 'drawable-v21') {
  $path = "android\app\src\main\res\$dir"
  New-Item -ItemType Directory -Force -Path $path | Out-Null
  Set-Content -Path "$path\launch_background.xml" -Value $launch
}

Write-Host ''
Write-Host 'Android project ready (application id com.kanjam.finance).'
Write-Host 'Next:  flutter pub get; dart fix --apply; flutter analyze; flutter test; flutter build apk --release'
