Import-Module PSReadLine
Set-PSReadlineOption -EditMode Emacs

# fix Ctrl+l
Set-PSReadlineKeyHandler -Chord "Ctrl+l" -ScriptBlock {
    Clear-Host
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt($null, 0)
}

# Use gvim.exe if the editor is not specified
if ( -not (Test-Path env:EDITOR)) {
    $env:EDITOR = "gvim.exe"
}

$confdir = "$env:HOME\Documents\WindowsPowerShell"

# example: ~\Documents\WindowsPowerShell\basic.ps1
. "$confdir\basic.ps1"

# example: ~\Documents\WindowsPowerShell\function.ps1
. "$confdir\function.ps1"

# example: ~\Documents\WindowsPowerShell\alias.ps1
. "$confdir\alias.ps1"

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
