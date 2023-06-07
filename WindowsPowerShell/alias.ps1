# cmdlets
Set-Alias -Name which -Value Get-Command

# cmd.exe implemented commands
Set-Alias -Name mklink -Value Start-CmdMklink

# tasks
Set-Alias -Name cdwork -Value Set-LocationToWorkspace
Set-Alias -Name gcl -Value Get-CommittedGitLine
Set-Alias -Name changeeditor -Value Update-Editor
Set-Alias -Name plt -Value procon-lib-tester

Set-Alias -Name tt -Value Start-CargoTestCerussite
Set-Alias -Name par -Value Start-ProconAssistantRun

Set-Alias -Name ^ -Value Expand-BashLikeBrace
Set-Alias -Name _ -Value Invoke-PipedCommand

# programs
Set-Alias -Name pa -Value procon-assistant
Set-Alias -Name pad -Value $env:HOME\dev\github\procon-assistant\target\debug\procon-assistant
