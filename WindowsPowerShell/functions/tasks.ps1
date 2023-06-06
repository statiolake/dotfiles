using namespace System.Collections.Generic;
using namespace System.Text;
using namespace System.Linq;

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
    class Context {
        # Prefixes, the prefix just before current braces.
        [List[StringBuilder]] $Prefixes

        # BraceArgs, the current-level brace arguments.
        [List[string]] $BraceArgs

        Context() {
            $this.Prefixes = [List[StringBuilder]]::new()
            $this.BraceArgs = [List[string]]::new()

            # Add default prefix
            $this.Prefixes.Add([StringBuilder]::new())
        }
    }

    # $stack, the all previous level contexts.
    $stack = [Stack[Context]]::new()
    # $context, the current context.
    $context = [Context]::new()

    function prefixesToBraceArgs ($prefixes, $braceArgs) {
        foreach ($prefix in $prefixes) {
            $braceArgs.Add($prefix.ToString())
        }
    }

    foreach ($ch in $BraceText.ToCharArray()) {
        switch ($ch) {
            '{' {
                # Push current context and start new one
                $stack.Push($context)
                $context = [Context]::new()
            }
            ',' {
                # End of the current context: Append all of current prefixes to
                # previous BraceArgs.
                $prevContext = $stack.Pop()
                prefixesToBraceArgs $context.Prefixes $prevContext.BraceArgs

                # Start of a new context: the next argument should be processed
                # within a new context.
                $stack.Push($prevContext)
                $context = [Context]::new()
            }
            '}' {
                # End of the current context: Append all of current prefixes to
                # previous BraceArgs.
                $prevContext = $stack.Pop()
                prefixesToBraceArgs $context.Prefixes $prevContext.BraceArgs

                # Use the previous context as current one.
                $context = $prevContext

                # This is also the end of the brace expansion: all BraceArgs
                # should be now moved to Prefixes.
                $expanded = [List[StringBuilder]]::new()
                foreach ($prefix in $context.Prefixes) {
                    foreach ($arg in $context.BraceArgs) {
                        $expanded.Add(
                            [StringBuilder]::new($prefix).Append($arg))
                    }
                }
                $context.Prefixes = $expanded

                # Remove ended BraceArgs
                $context.BraceArgs.Clear()
            }
            default {
                # Add this character to all current prefixes
                foreach ($prefix in $context.Prefixes) {
                    $prefix.Append($ch) | Out-Null
                }
            }
        }
    }

    # Expansion completed. Convert all string builder to string.
    return $context.Prefixes | ForEach-Object { $_.ToString() }
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
