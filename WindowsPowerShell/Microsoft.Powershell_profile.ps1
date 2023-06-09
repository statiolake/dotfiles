﻿if ($PSVersionTable.PSVersion.Major -ge 7)
{
  Import-Module PSReadLine
  Set-PSReadlineOption -EditMode Emacs

  # fix Ctrl+l
  Set-PSReadlineKeyHandler -Chord "Ctrl+l" -ScriptBlock {
    Clear-Host
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt($null, 0)
  }

  # default editor
  if ( -not $env:EDITOR )
  {
    $env:EDITOR = "v.exe"
  }

  $confdir = (Get-Item $profile).DirectoryName

  # example: ~\Documents\WindowsPowerShell\basic.ps1
  . "$confdir\basic.ps1"

  # example: ~\Documents\WindowsPowerShell\function.ps1
  . "$confdir\function.ps1"

  # example: ~\Documents\WindowsPowerShell\alias.ps1
  . "$confdir\alias.ps1"

  # I need to load plugins after alias.ps1 (which sets alias `g` for git)
  # example: ~\Documents\WindowsPowerShell\plugins.ps1
  . "$confdir\plugins.ps1"

  # Chocolatey profile
  $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
  if (Test-Path($ChocolateyProfile))
  {
    Import-Module "$ChocolateyProfile"
  }
}
