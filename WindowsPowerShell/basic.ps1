# Set prompt
function Prompt () {
    # Save last status before running bunch of commands to construct prompt...
    $last_status = $?

    $location = Get-Location
    $now = Get-Date
    $time_string = [String]::Format(
        "{0:00}:{1:00}:{2:00}",
        $now.Hour,
        $now.Minute,
        $now.Second
    )
    $face = ($last_status ? "('-')/" : "('-';)")

    $security_identity = (
        [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    )
    $is_admin = $security_identity.IsInRole(
        [System.Security.Principal.WindowsBuiltInRole] "Administrator"
    )
    $prompt_char = $is_admin ? '#' : '>'

    $location = $ExecutionContext.SessionState.Path.CurrentLocation

    Write-Host $time_string -NoNewline -ForegroundColor White
    Write-Host " " -NoNewline
    Write-Host ([String]::Format("{0}@{1}", $env:USERNAME, $env:COMPUTERNAME)) -NoNewline -ForegroundColor Green
    Write-Host ":" -NoNewline
    Write-Host $location -NoNewline -ForegroundColor Blue
    Write-Host

    $rest = [String]::Format("{0}{1} ", $face, $prompt_char)
    if ($location.Provider.Name -eq "FileSystem") {
        $notify_location = "$([char]27)]9;9;`"$($location.ProviderPath)`"$([char]27)\"
        $rest += $notify_location
    }

    return $rest
}
