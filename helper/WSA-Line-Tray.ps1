param(
    [switch]$Show
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public static class WsaLineWindowNative
{
    private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetClassName(IntPtr hWnd, StringBuilder className, int count);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int command);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool PostMessage(IntPtr hWnd, uint message, IntPtr wParam, IntPtr lParam);

    public static IntPtr[] FindLineWindows()
    {
        var windows = new List<IntPtr>();
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam)
        {
            var className = new StringBuilder(256);
            GetClassName(hWnd, className, className.Capacity);
            if (className.ToString() == "jp.naver.line.android")
            {
                windows.Add(hWnd);
            }
            return true;
        }, IntPtr.Zero);
        return windows.ToArray();
    }

    public static bool AnyLineWindowVisible()
    {
        foreach (var window in FindLineWindows())
        {
            if (IsWindowVisible(window)) return true;
        }
        return false;
    }
}
'@

$showEvent = [System.Threading.EventWaitHandle]::new(
    $false,
    [System.Threading.EventResetMode]::AutoReset,
    'Local\WSA_LINE_TRAY_SHOW'
)

$createdNew = $false
$mutex = [System.Threading.Mutex]::new($true, 'Local\WSA_LINE_TRAY', [ref]$createdNew)
if (-not $createdNew) {
    [void]$showEvent.Set()
    $showEvent.Dispose()
    $mutex.Dispose()
    exit 0
}

function Get-LineWindows {
    return [WsaLineWindowNative]::FindLineWindows()
}

$script:shouldHide = $true
$script:forceHideUntil = [DateTime]::UtcNow

function Start-Line {
    $windows = @(Get-LineWindows)
    if ($windows.Count -eq 0) {
        Start-Process 'wsa://jp.naver.line.android'
        for ($attempt = 0; $attempt -lt 90; $attempt++) {
            Start-Sleep -Milliseconds 500
            $windows = @(Get-LineWindows)
            if ($windows.Count -gt 0) { break }
        }
    }
    return $windows
}

function Show-Line {
    $script:shouldHide = $false
    foreach ($window in @(Start-Line)) {
        [void][WsaLineWindowNative]::ShowWindow($window, 9)
        [void][WsaLineWindowNative]::SetForegroundWindow($window)
    }
}

function Hide-LineWindows {
    foreach ($window in @(Get-LineWindows)) {
        [void][WsaLineWindowNative]::ShowWindow($window, 0)
    }
}

function Hide-Line {
    $script:shouldHide = $true
    $script:forceHideUntil = [DateTime]::UtcNow.AddSeconds(2)
    Hide-LineWindows
}

function Close-Line {
    $script:shouldHide = $true
    foreach ($window in @(Get-LineWindows)) {
        [void][WsaLineWindowNative]::PostMessage($window, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
    }
}

$notifyIcon = [System.Windows.Forms.NotifyIcon]::new()
$notifyIcon.Text = 'LINE (Android / WSA)'
$iconPath = Join-Path $PSScriptRoot 'LINE.ico'
if (Test-Path -LiteralPath $iconPath) {
    $notifyIcon.Icon = [System.Drawing.Icon]::new($iconPath)
}
else {
    $notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
}
$notifyIcon.Visible = $true

$menu = [System.Windows.Forms.ContextMenuStrip]::new()
$showItem = $menu.Items.Add('Show LINE')
$hideItem = $menu.Items.Add('Hide to tray')
$closeItem = $menu.Items.Add('Close LINE')
[void]$menu.Items.Add('-')
$exitItem = $menu.Items.Add('Exit tray helper')

$showItem.add_Click({ Show-Line })
$hideItem.add_Click({ Hide-Line })
$closeItem.add_Click({ Close-Line })
$exitItem.add_Click({
    $notifyIcon.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})
$notifyIcon.add_DoubleClick({ Show-Line })
$notifyIcon.ContextMenuStrip = $menu

$timer = [System.Windows.Forms.Timer]::new()
$timer.Interval = 1000
$timer.add_Tick({
    if ($showEvent.WaitOne(0)) {
        Show-Line
        return
    }

    if ($script:shouldHide -and @(Get-LineWindows).Count -gt 0) {
        if ([DateTime]::UtcNow -lt $script:forceHideUntil) {
            Hide-LineWindows
        }
        elseif ([WsaLineWindowNative]::AnyLineWindowVisible()) {
            $script:shouldHide = $false
        }
    }
})
$timer.Start()

try {
    [void](Start-Line)
    if ($Show) {
        Show-Line
    }
    else {
        $script:forceHideUntil = [DateTime]::UtcNow.AddSeconds(10)
        Hide-LineWindows
    }
    [System.Windows.Forms.Application]::Run()
}
finally {
    $timer.Dispose()
    $notifyIcon.Dispose()
    $menu.Dispose()
    $showEvent.Dispose()
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
