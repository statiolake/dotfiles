if (-not (Get-Module -ListAvailable -Name Use-RawPipeline))
{
    Write-Host "Use-RawPipeline not installed. Installing..."
    Install-Module -Name Use-RawPipeline -Scope CurrentUser
}

if (-not (Get-Module -ListAvailable -Name posh-git))
{
    Write-Host "posh-git not installed. installing..."
    Install-Module -Name posh-git -Scope CurrentUser
}

Import-Module posh-git -Arg 0,0,0
