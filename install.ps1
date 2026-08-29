param(
    [switch]$NoStart
)

$ErrorActionPreference = 'Stop'

$sourceDir = Join-Path $PSScriptRoot 'helper'
$installDir = Join-Path $env:LOCALAPPDATA 'WSA-LINE-Tray'
$programsDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$startupDir = Join-Path $programsDir 'Startup'
$lineShortcutPath = Join-Path $programsDir 'LINE (Android).lnk'
$startupShortcutPath = Join-Path $startupDir 'LINE Android Tray.lnk'

New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $sourceDir 'WSA-Line-Tray.ps1') -Destination $installDir -Force
Copy-Item -LiteralPath (Join-Path $sourceDir 'Launch-LINE.vbs') -Destination $installDir -Force
Copy-Item -LiteralPath (Join-Path $sourceDir 'Launch-LINE-Tray.vbs') -Destination $installDir -Force

$wsaState = Join-Path $env:LOCALAPPDATA 'Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe\LocalState'
$installedIcon = Join-Path $wsaState 'jp.naver.line.android.ico'
if (Test-Path -LiteralPath $installedIcon) {
    Copy-Item -LiteralPath $installedIcon -Destination (Join-Path $installDir 'LINE.ico') -Force
}
else {
    Write-Warning 'LINE icon was not found. Launch LINE once, then run this installer again.'
}

$shell = New-Object -ComObject WScript.Shell
$wscriptPath = Join-Path $env:SystemRoot 'System32\wscript.exe'
$iconPath = Join-Path $installDir 'LINE.ico'
$iconLocation = if (Test-Path -LiteralPath $iconPath) { "$iconPath,0" } else { "$wscriptPath,0" }

$lineShortcut = $shell.CreateShortcut($lineShortcutPath)
$lineShortcut.TargetPath = $wscriptPath
$lineShortcut.Arguments = '"' + (Join-Path $installDir 'Launch-LINE.vbs') + '"'
$lineShortcut.WorkingDirectory = $installDir
$lineShortcut.IconLocation = $iconLocation
$lineShortcut.WindowStyle = 7
$lineShortcut.Description = 'Launch Android LINE with the tray helper'
$lineShortcut.Save()

$startupShortcut = $shell.CreateShortcut($startupShortcutPath)
$startupShortcut.TargetPath = $wscriptPath
$startupShortcut.Arguments = '"' + (Join-Path $installDir 'Launch-LINE-Tray.vbs') + '"'
$startupShortcut.WorkingDirectory = $installDir
$startupShortcut.IconLocation = $iconLocation
$startupShortcut.WindowStyle = 7
$startupShortcut.Description = 'Android LINE tray helper'
$startupShortcut.Save()

if (-not $NoStart) {
    Start-Process -FilePath $wscriptPath -ArgumentList ('"' + (Join-Path $installDir 'Launch-LINE-Tray.vbs') + '"')
}

Write-Host ''
Write-Host 'Setup completed.'
Write-Host 'Launch LINE from "LINE (Android)" in the Start menu.'
Write-Host 'Double-click the notification-area icon to show LINE.'
