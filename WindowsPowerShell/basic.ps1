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

    Write-Host $time_string -NoNewline -ForegroundColor White
    Write-Host " " -NoNewline
    Write-Host ([String]::Format("{0}@{1}", $env:USERNAME, $env:COMPUTERNAME)) -NoNewline -ForegroundColor Green
    Write-Host ":" -NoNewline
    Write-Host (Get-Location) -NoNewline -ForegroundColor Blue
    Write-Host

    [String]::Format("{0}{1} ", $face, $prompt_char)
}
