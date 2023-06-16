function Start-CmdMklink ()
{
    cmd.exe /c mklink $args
}

function Get-VimConfigs ()
{
    Get-ChildItem $env:HOME\.vim\conf\vimrc.* | Format-Wide -AutoSize
}

function Edit-VimConfig ()
{
    & "$env:EDITOR" "$env:HOME\.vim\conf\vimrc.$($args[0])"
}

function Edit-DeinConfig ()
{
    & "$env:EDITOR" "${env:HOME}\.vim\conf\vimrc.plugins.dein"
}

function Edit-EmacsConfig ()
{
    runemacs "$env:HOME\.emacs.d\conf\$($args[0]).el"
}

function Edit-PowerShellConfig ()
{
    if ($args.Length -eq 0)
    {
        & "$env:EDITOR" "$env:HOME\Documents\WindowsPowerShell\Microsoft.Powershell_profile.ps1"
    } else
    {
        & "$env:EDITOR" "$env:HOME\Documents\WindowsPowerShell\$($args[0]).ps1"
    }
}

function Open-WicurioVim ()
{
    gvim -c "set ft=wicurio tw=0"
}

function Restore-Artworks ()
{
    extract-common.exe ".artwork" "conf.bin" "${env:HOME}\storage\artworks\art" "${env:HOME}\storage\artworks\art\.backup"
}

function Restore-Commics ()
{
    extract-common.exe ".comics" "conf.bin" "${env:HOME}\storage\artworks\com" "${env:HOME}\storage\artworks\com\.backup"
}

function Start-ProconAssistantRun ()
{
    procon-assistant run $args
}

function Start-CargoTestCerussite ()
{
    cargo test-cerussite $args
}

function Start-Exa ()
{
    exa $args
}

function Start-ExaList ()
{
    exa -l $args
}

function Start-ExaListAll ()
{
    exa -la $args
}
