# Apply platform-db migrations in order. Requires DATABASE_URL.
# Usage (PowerShell):
#   $env:DATABASE_URL = "postgresql://..."
#   .\scripts\migrate.ps1

$ErrorActionPreference = "Stop"

if (-not $env:DATABASE_URL) {
    Write-Error "DATABASE_URL is not set"
    exit 1
}

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$migrationsDir = Join-Path $root "migrations"
$files = Get-ChildItem -Path $migrationsDir -Filter "*.sql" | Sort-Object Name

if ($files.Count -eq 0) {
    Write-Error "No migrations found in $migrationsDir"
    exit 1
}

foreach ($file in $files) {
    Write-Host "Applying $($file.BaseName) ..."
    & psql $env:DATABASE_URL -v ON_ERROR_STOP=1 -f $file.FullName
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Write-Host "Done."
