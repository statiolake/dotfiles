using namespace System.Collections.Generic;
using namespace System.Text;
using namespace System.Linq;

function Set-LocationToWorkspace ()
{
    $path = workspace_path -d
    Set-Location $path
}


function Expand-BashLikeBrace ($BraceText)
{
    $ErrorActionPreference = "Stop"
    class Context
    {
        # Prefixes, the prefix just before current braces.
        [List[StringBuilder]] $Prefixes

        # BraceArgs, the current-level brace arguments.
        [List[string]] $BraceArgs

        Context()
        {
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

    function prefixesToBraceArgs ($prefixes, $braceArgs)
    {
        foreach ($prefix in $prefixes)
        {
            $braceArgs.Add($prefix.ToString())
        }
    }

    foreach ($ch in $BraceText.ToCharArray())
    {
        switch ($ch)
        {
            '{'
            {
                # Push current context and start new one
                $stack.Push($context)
                $context = [Context]::new()
            }
            ','
            {
                # End of the current context: Append all of current prefixes to
                # previous BraceArgs.
                $prevContext = $stack.Pop()
                prefixesToBraceArgs $context.Prefixes $prevContext.BraceArgs

                # Start of a new context: the next argument should be processed
                # within a new context.
                $stack.Push($prevContext)
                $context = [Context]::new()
            }
            '}'
            {
                # End of the current context: Append all of current prefixes to
                # previous BraceArgs.
                $prevContext = $stack.Pop()
                prefixesToBraceArgs $context.Prefixes $prevContext.BraceArgs

                # Use the previous context as current one.
                $context = $prevContext

                # This is also the end of the brace expansion: all BraceArgs
                # should be now moved to Prefixes.
                $expanded = [List[StringBuilder]]::new()
                foreach ($prefix in $context.Prefixes)
                {
                    foreach ($arg in $context.BraceArgs)
                    {
                        $expanded.Add(
                            [StringBuilder]::new($prefix).Append($arg))
                    }
                }
                $context.Prefixes = $expanded

                # Remove ended BraceArgs
                $context.BraceArgs.Clear()
            }
            default
            {
                # Add this character to all current prefixes
                foreach ($prefix in $context.Prefixes)
                {
                    $prefix.Append($ch) | Out-Null
                }
            }
        }
    }

    # Expansion completed. Convert all string builder to string.
    return $context.Prefixes | ForEach-Object { $_.ToString() }
}

function Invoke-PipedCommand ($ScriptBlock)
{
    Begin
    { $piped = @() 
    }
    Process
    { $piped += $input 
    }
    End
    { Invoke-Command  -NoNewScope $ScriptBlock -ArgumentList $piped 
    }
}


function Get-CommittedGitLine ()
{
    $log = git log --numstat --pretty="%%H" --author=statiolake --no-merges
    $log | awk 'NF==3 {plus+=$1; minus+=$2} END {printf(\"%d (+%d, -%d)\n\", plus+minus, plus, minus)}'
}

function Find-Uwp ()
{
    $query = $args[0]
    $uwpapps = Get-AppxPackage -Name *$query*
    if ($uwpapps.Length -eq 0)
    {
        Write-Output "Found no packages."
    } elseif ($uwpapps.Length -eq 1)
    {
        Write-Output "Found only one package. to launch this:"

        $PackageFamilyName = $uwpapps.PackageFamilyName
        $ApplicationIDs = ($uwpapps | Get-AppxPackageManifest).Package.Applications.Application.Id

        foreach ($ApplicationID in $ApplicationIDs)
        {
            $command = "Start-Process shell:AppsFolder\" + $PackageFamilyName + "!" + $ApplicationID
            Write-Output "> $command"
        }
    } else
    {
        Write-Output "Found multiple packages; Possible candidates are:"
        foreach ($uwpapp in $uwpapps)
        {
            $PackageFamilyName = $uwpapp.PackageFamilyName
            Write-Output "* $PackageFamilyName"
            $ApplicationIDs = ($uwpapp | Get-AppxPackageManifest).Package.Applications.Application.Id
            foreach ($ApplicationID in $ApplicationIDs)
            {
                Write-Output "    + $ApplicationID"
            }
        }
    }
}
