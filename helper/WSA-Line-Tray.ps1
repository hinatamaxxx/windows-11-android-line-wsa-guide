param(
    [switch]$Show
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

// A hidden TOP-LEVEL window receives session messages (a message-only window would not).
// Handle these in C# so shutdown does not depend on PowerShell event dispatch.
public sealed class WsaLineSessionWindow : NativeWindow, IDisposable
{
    private readonly NotifyIcon tray;
    private readonly Timer timer;
    public bool EndingRequested { get; private set; }

    public WsaLineSessionWindow(NotifyIcon tray, Timer timer)
    {
        this.tray = tray;
        this.timer = timer;
        CreateHandle(new CreateParams {
            Caption = "WSA LINE Tray Session", Parent = IntPtr.Zero,
            Style = 0, ExStyle = 0x80
        });
    }

    protected override void WndProc(ref Message message)
    {
        if (message.Msg == 0x0011) // WM_QUERYENDSESSION: always allow shutdown.
        {
            EndingRequested = true;
            message.Result = new IntPtr(1);
            return;
        }
        if (message.Msg == 0x0016) // WM_ENDSESSION
        {
            if (message.WParam != IntPtr.Zero)
            {
                EndingRequested = true;
                timer.Stop();
                tray.Visible = false;
                Application.ExitThread();
            }
            else
            {
                // Shutdown was cancelled: resume normal operation.
                EndingRequested = false;
            }
            message.Result = IntPtr.Zero;
            return;
        }
        if (message.Msg == 0x0010) // Graceful helper-only exit.
        {
            EndingRequested = true;
            timer.Stop();
            tray.Visible = false;
            Application.ExitThread();
            message.Result = IntPtr.Zero;
            return;
        }
        base.WndProc(ref message);
    }

    public void Dispose() { DestroyHandle(); }
}

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
    public static extern bool ShowWindowAsync(IntPtr hWnd, int command);

    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);

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
            if (IsWindowVisible(window) && !IsIconic(window)) return true;
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
$script:launchDeadline = [DateTime]::MinValue
$script:pendingDisplay = $false
$script:hideAfter = @{}

function Start-Line {
    if ($sessionWindow.EndingRequested) { return @() }
    $windows = @(Get-LineWindows)
    if ($windows.Count -eq 0 -and [DateTime]::UtcNow -ge $script:launchDeadline) {
        $script:launchDeadline = [DateTime]::UtcNow.AddSeconds(45)
        Start-Process 'wsa://jp.naver.line.android'
    }
    return $windows
}

function Show-Line {
    if ($sessionWindow.EndingRequested) { return }
    $script:hideAfter.Clear()
    $script:shouldHide = $false
    $windows = @(Start-Line)
    $script:pendingDisplay = ($windows.Count -eq 0)
    foreach ($window in $windows) {
        [void][WsaLineWindowNative]::ShowWindowAsync($window, 9)
        [void][WsaLineWindowNative]::SetForegroundWindow($window)
    }
}

function Hide-LineWindows {
    if ($sessionWindow.EndingRequested) { return }
    $windows = @(Get-LineWindows)
    $currentHandles = @($windows | ForEach-Object { $_.ToInt64() })
    foreach ($key in @($script:hideAfter.Keys)) {
        if ($key -notin $currentHandles) { $script:hideAfter.Remove($key) }
    }
    foreach ($window in $windows) {
        $key = $window.ToInt64()
        if ($script:hideAfter.ContainsKey($key) -and
            [DateTime]::UtcNow -lt $script:hideAfter[$key]) { continue }

        if ([WsaLineWindowNative]::IsIconic($window)) {
            # WSA's compositor must process minimization before SW_HIDE.
            # Hiding a normal WSA window directly can leave a blank frame behind.
            if ([WsaLineWindowNative]::IsWindowVisible($window)) {
                [void][WsaLineWindowNative]::ShowWindowAsync($window, 0)
            }
            $script:hideAfter.Remove($key)
        }
        else {
            # SW_SHOWMINNOACTIVE: do not steal focus. Finish on a later timer tick,
            # keeping the Windows message loop responsive during the wait.
            [void][WsaLineWindowNative]::ShowWindowAsync($window, 7)
            $script:hideAfter[$key] = [DateTime]::UtcNow.AddMilliseconds(700)
        }
    }
}

function Hide-Line {
    if ($sessionWindow.EndingRequested) { return }
    $script:shouldHide = $true
    $script:forceHideUntil = [DateTime]::UtcNow.AddSeconds(2)
    Hide-LineWindows
}

function Close-Line {
    if ($sessionWindow.EndingRequested) { return }
    $script:hideAfter.Clear()
    $script:pendingDisplay = $false
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
$timer.Interval = 250
$timer.add_Tick({
    if ($sessionWindow.EndingRequested) { return }
    if ($showEvent.WaitOne(0)) {
        Show-Line
        return
    }

    # Poll for LINE without blocking the Windows message loop.
    if ($script:pendingDisplay) {
        if (@(Get-LineWindows).Count -gt 0) {
            $script:pendingDisplay = $false
            if ($script:shouldHide) {
                $script:forceHideUntil = [DateTime]::UtcNow.AddSeconds(10)
                Hide-LineWindows
            }
            else { Show-Line }
        }
        elseif ([DateTime]::UtcNow -ge $script:launchDeadline) {
            $script:pendingDisplay = $false
        }
    }

    if ($script:shouldHide -and @(Get-LineWindows).Count -gt 0) {
        if ([DateTime]::UtcNow -lt $script:forceHideUntil -or $script:hideAfter.Count -gt 0) {
            Hide-LineWindows
        }
        elseif ([WsaLineWindowNative]::AnyLineWindowVisible()) {
            $script:shouldHide = $false
        }
    }
})
$sessionWindow = [WsaLineSessionWindow]::new($notifyIcon, $timer)

try {
    $timer.Start()
    # Defer launch until the message loop is running.
    $launchTimer = [System.Windows.Forms.Timer]::new()
    $launchTimer.Interval = 100
    $launchTimer.add_Tick({
        if ($sessionWindow.EndingRequested) { return }
        $launchTimer.Stop()
        if ($Show) {
            Show-Line
        }
        else {
            $windows = @(Start-Line)
            $script:pendingDisplay = ($windows.Count -eq 0)
            $script:forceHideUntil = [DateTime]::UtcNow.AddSeconds(10)
            Hide-LineWindows
        }
    })
    $launchTimer.Start()
    [System.Windows.Forms.Application]::Run()
}
finally {
    if ($launchTimer) { $launchTimer.Dispose() }
    $timer.Dispose()
    $sessionWindow.Dispose()
    $notifyIcon.Dispose()
    $menu.Dispose()
    $showEvent.Dispose()
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
