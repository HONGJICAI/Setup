$ErrorActionPreference = 'Stop'

Write-Host '==> Scoop apps (scoop.txt)'

$scoopDir = if ($env:SCOOP) { $env:SCOOP } else { "$env:USERPROFILE\scoop" }
$apps = Get-Content (Join-Path $PSScriptRoot 'scoop.txt') |
    ForEach-Object { ($_ -replace '#.*$', '').Trim() } |
    Where-Object { $_ }

# Add every bucket referenced as `bucket/app`.
$buckets = $apps | Where-Object { $_ -like '*/*' } | ForEach-Object { $_.Split('/')[0] } | Sort-Object -Unique
foreach ($bucket in $buckets) {
    if (-not (Test-Path "$scoopDir\buckets\$bucket")) {
        scoop bucket add $bucket
        if ($LASTEXITCODE -ne 0) { throw "Failed to add bucket $bucket" }
    }
}

$failed = @()
foreach ($app in $apps) {
    $name = $app.Split('/')[-1]
    if (Test-Path "$scoopDir\apps\$name\current") {
        Write-Host "  $name already installed"
        continue
    }
    scoop install $app
    if ($LASTEXITCODE -ne 0) { $failed += $app }
}

if ($failed) { throw "Failed to install: $($failed -join ', ')" }
