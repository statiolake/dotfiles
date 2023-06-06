# Set prompt
function Prompt () {
    # Save last status before running bunch of commands to construct prompt...
    $lastStatus = $?

    $location = Get-Location
    $now = Get-Date
    $timeString = [String]::Format(
        "{0:00}:{1:00}:{2:00}",
        $now.Hour,
        $now.Minute,
        $now.Second
    )
    $face = ($lastStatus ? "('-')/" : "('-';)")

    $securityIdentity = (
        [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    )
    $isAdmin = $securityIdentity.IsInRole(
        [System.Security.Principal.WindowsBuiltInRole] "Administrator"
    )
    $promptChar = $isAdmin ? '#' : '>'

    $location = $ExecutionContext.SessionState.Path.CurrentLocation

    Write-Host $timeString -NoNewline -ForegroundColor White
    Write-Host " " -NoNewline
    Write-Host ([String]::Format("{0}@{1}", $env:USERNAME, $env:COMPUTERNAME)) -NoNewline -ForegroundColor Green
    Write-Host ":" -NoNewline
    Write-Host $location -NoNewline -ForegroundColor Blue
    Write-Host

    if ($location.Provider.Name -eq "FileSystem") {
        $notifyLocation = "$([char]27)]9;9;`"$($location.ProviderPath)`"$([char]27)\"
        Write-Host $notifyLocation -NoNewline
    }

    return [String]::Format("{0}{1} ", $face, $promptChar)
}
