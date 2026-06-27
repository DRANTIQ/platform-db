# Apply platform-db migrations in order. Requires DATABASE_URL.
# Usage (PowerShell):
#   $env:DATABASE_URL = "postgresql://...?sslmode=require"
#   .\scripts\migrate.ps1

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$envFile = Join-Path $root ".env"
if (-not $env:DATABASE_URL -and (Test-Path $envFile)) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*DATABASE_URL=(.+)$') {
            $env:DATABASE_URL = $Matches[1].Trim().Trim('"').Trim("'")
        }
    }
}

if (-not $env:DATABASE_URL) {
    Write-Error "DATABASE_URL is not set. Add it to platform-db/.env or set `$env:DATABASE_URL"
    exit 1
}

if ($env:DATABASE_URL -notmatch 'sslmode=' -and $env:DATABASE_URL -notmatch 'ssl=') {
    if ($env:DATABASE_URL -match '\?') {
        $env:DATABASE_URL += '&sslmode=require'
    } else {
        $env:DATABASE_URL += '?sslmode=require'
    }
}

if (Get-Command python -ErrorAction SilentlyContinue) {
    python (Join-Path $root "scripts\migrate.py")
    exit $LASTEXITCODE
}

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
