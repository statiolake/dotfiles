if (-not (Get-Module -ListAvailable -Name Use-RawPipeline)) {
    Write-Host "Use-RawPipeline not installed. Installing..."
    Install-Module -Name Use-RawPipeline -Scope CurrentUser
}
