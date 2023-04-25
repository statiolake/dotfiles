# cmd.exe implemented commands
Set-Alias -Name mklink -Value Start-CmdMklink

# tasks
Set-Alias -Name which -Value Get-CommandPath
Set-Alias -Name cdwork -Value Set-LocationToWorkspace
Set-Alias -Name gcl -Value Get-CommittedGitLine
Set-Alias -Name changeeditor -Value Update-Editor
Set-Alias -Name plt -Value procon-lib-tester

# alias wrappers
Set-Alias -Name lsvimrc -Value Get-VimConfigs
Set-Alias -Name vivimrc -Value Edit-VimConfig
Set-Alias -Name deinconf -Value Edit-DeinConfig
Set-Alias -Name viemacsd -Value Edit-EmacsConfig
Set-Alias -Name vipowershellcfg -Value Edit-PowerShellConfig
Set-Alias -Name viwicurio -Value Open-WicurioVim

Remove-Item alias:ls
Set-Alias -Name ls -Value Start-Exa
Set-Alias -Name ll -Value Start-ExaList
Set-Alias -Name la -Value Start-ExaListAll
Set-Alias -Name tt -Value Start-CargoTestCerussite
Set-Alias -Name par -Value Start-ProconAssistantRun

Set-Alias -Name ^ -Value Expand-BashLikeBrace

# programs
Set-Alias -Name g -Value hub
Set-Alias -Name v -Value $env:EDITOR
Set-Alias -Name c -Value code
Set-Alias -Name pa -Value procon-assistant
Set-Alias -Name pad -Value $env:HOME\dev\github\procon-assistant\target\debug\procon-assistant
