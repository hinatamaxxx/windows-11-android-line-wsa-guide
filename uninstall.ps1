$ErrorActionPreference = 'Stop'

$installDir = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'WSA-LINE-Tray'))
$programsDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$shortcutPaths = @(
    (Join-Path $programsDir 'LINE (Android).lnk'),
    (Join-Path $programsDir 'Startup\LINE Android Tray.lnk')
)
$helperPath = Join-Path $installDir 'WSA-Line-Tray.ps1'

Get-CimInstance Win32_Process |
    Where-Object { $_.Name -eq 'powershell.exe' -and $_.CommandLine -like "*$helperPath*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

foreach ($shortcutPath in $shortcutPaths) {
    if (Test-Path -LiteralPath $shortcutPath) {
        Remove-Item -LiteralPath $shortcutPath -Force
    }
}

$expectedDir = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'WSA-LINE-Tray'))
if ($installDir -eq $expectedDir -and (Test-Path -LiteralPath $installDir)) {
    Remove-Item -LiteralPath $installDir -Recurse -Force
}

Write-Host 'Removed the tray helper and its shortcuts. LINE and WSA were not removed.'
