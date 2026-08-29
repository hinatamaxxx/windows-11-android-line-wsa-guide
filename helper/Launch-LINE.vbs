Option Explicit

Dim shell, fileSystem, basePath, powershellPath, helperPath, command
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

basePath = fileSystem.GetParentFolderName(WScript.ScriptFullName)
powershellPath = shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
helperPath = basePath & "\WSA-Line-Tray.ps1"
command = Chr(34) & powershellPath & Chr(34) & _
    " -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " & _
    Chr(34) & helperPath & Chr(34) & " -Show"

shell.Run command, 0, False
