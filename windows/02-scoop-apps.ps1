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
    # Scoop writes install.json as the very last install step, so its absence
    # means a previous install was interrupted. `current` alone isn't enough:
    # it's linked before shims and post_install run.
    if (Test-Path "$scoopDir\apps\$name\current\install.json") {
        Write-Host "  $name already installed"
        continue
    }
    if (Test-Path "$scoopDir\apps\$name") {
        # Scoop refuses to install over a failed install; clear it first (persisted data is kept).
        Write-Host "  $name has an incomplete install, removing it first"
        scoop uninstall $name
    }
    scoop install $app
    if ($LASTEXITCODE -ne 0) { $failed += $app }
}

if ($failed) { throw "Failed to install: $($failed -join ', ')" }
