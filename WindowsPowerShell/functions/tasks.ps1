function Set-LocationToWorkspace () {
    make_workspace
    $path = workspace_path -d
    Set-Location $path
}


# Add command-line switch for disabling displaying `CommandType`
function Get-CommandPath ($Query, [switch] $NoCommandType) {
    $ErrorActionPreference = "Stop"
    $cmd = Get-Command $Query

    $output = ""
    if (!$NoCommandType) {
        $output = "[" + $cmd.CommandType + "] "
    }
    $output += $cmd.Definition

    Write-Output $output
}

function Expand-BashLikeBrace ($BraceText) {
    $ErrorActionPreference = "Stop"
    $result = @()
    foreach ($text in $BraceText) {
        if ($text -match "(.*?){(.*?)}(.*)") {
            $head = $Matches[1]
            $m = $Matches[2]
            $tail = $Matches[3]
            $captures = [Regex]::Matches($m, "^(?:(.*?)(?<!(?<!\\)\\),)*(.*)$").Groups[1..2].Captures

            $expanded = $captures | % { "$head$_$tail" }
            $result += Expand-BashLikeBrace $expanded
        }
        else {
            $result += @($text)
        }
    }
    return $result
}

function Invoke-PipedCommand ($ScriptBlock) {
    Begin { $piped = @() }
    Process { $piped += $input }
    End { Invoke-Command  -NoNewScope $ScriptBlock -ArgumentList $piped }
}


function Get-CommittedGitLine () {
    $log = git log --numstat --pretty="%%H" --author=statiolake --no-merges
    $log | awk 'NF==3 {plus+=$1; minus+=$2} END {printf(\"%d (+%d, -%d)\n\", plus+minus, plus, minus)}'
}


function Update-Editor () {
    $editor = Read-Host -Prompt "What editor do you want to use"
    if ($editor -eq "") {
        Write-Output "You entered a blank name. Do nothing now. exit."
        return
    }
    else {
        if ($editor -eq "gvim.exe") {
            Write-Output "apply context menu settings for GVim..."
            regedit $env:HOME\cabinet\settings\reg_contextmenu_prefer_gvim.reg
        }
        elseif ($editor -eq "nvim.exe") {
            Write-Output "apply context menu settings for Neovim..."
            regedit $env:HOME\cabinet\settings\reg_contextmenu_prefer_nvim.reg
        }
        elseif ($editor -eq "nvim-qt.exe") {
            Write-Output "apply context menu settings for Neovim-qt..."
            regedit $env:HOME\cabinet\settings\reg_contextmenu_prefer_nvimqt.reg
        }
        elseif ($editor -eq "code.exe") {
            Write-Output "apply context menu settings for VSCode..."
            regedit $env:HOME\cabinet\settings\reg_contextmenu_prefer_vscode.reg
        }

        [System.Environment]::SetEnvironmentVariable('EDITOR', $editor, [System.EnvironmentVariableTarget]::User)
        Write-Output "change editor from $env:EDITOR to $editor."
        $env:EDITOR = $editor
        Write-Output "Some other files needs to be updated. Change them manually with your new favorite editor!"

        & "$env:EDITOR" `
            "$env:HOME\dev\github\procon-assistant\target\release\config.json" `
            "$env:HOME\dev\github\memo_v2\target\release\config.json" `
            "$env:HOME\.gitconfig"
    }
}

function Find-Uwp () {
    $query = $args[0]
    $uwpapps = Get-AppxPackage -Name *$query*
    if ($uwpapps.Length -eq 0) {
        Write-Output "Found no packages."
    }
    elseif ($uwpapps.Length -eq 1) {
        Write-Output "Found only one package. to launch this:"

        $PackageFamilyName = $uwpapps.PackageFamilyName
        $ApplicationIDs = ($uwpapps | Get-AppxPackageManifest).Package.Applications.Application.Id

        foreach ($ApplicationID in $ApplicationIDs) {
            $command = "Start-Process shell:AppsFolder\" + $PackageFamilyName + "!" + $ApplicationID
            Write-Output "> $command"
        }
    }
    else {
        Write-Output "Found multiple packages; Possible candidates are:"
        foreach ($uwpapp in $uwpapps) {
            $PackageFamilyName = $uwpapp.PackageFamilyName
            Write-Output "* $PackageFamilyName"
            $ApplicationIDs = ($uwpapp | Get-AppxPackageManifest).Package.Applications.Application.Id
            foreach ($ApplicationID in $ApplicationIDs) {
                Write-Output "    + $ApplicationID"
            }
        }
    }
}

function Stop-Emacs () {
    emacsclient -e "(skk-reread-private-jisyo t)" > $null 2> $null
    emacsclient -e "(kill-emacs)"
}

function Start-Emacs () {
    runemacs --daemon
}

function Restart-Emacs () {
    Write-Output "killing emacs..."
    Stop-Emacs
    Write-Output "restarting emacs..."
    Start-Emacs
}
