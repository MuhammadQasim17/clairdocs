<#
.SYNOPSIS
    Builds the ClairDocs Enterprise Windows MSIX desktop installer.

.DESCRIPTION
    Resolves dependencies, runs static analysis (and optional tests), and
    invokes `flutter pub run msix:create` using the `msix_config` block in
    pubspec.yaml.

.EXAMPLE
    .\scripts\build_msix.ps1

.EXAMPLE
    .\scripts\build_msix.ps1 -CertificatePath .\certs\clairdocs.pfx -CertificatePassword $env:MSIX_CERT_PASSWORD
#>
[CmdletBinding()]
param(
    [switch]$SkipChecks,
    [switch]$SkipTests,
    [switch]$Store,
    [switch]$NoInstallCert,
    [string]$CertificatePath = '',
    [string]$CertificatePassword = '',
    [string]$OutputPath = '',
    [string]$OutputName = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $repoRoot

try {
    Write-Host '==> ClairDocs Windows MSIX Packaging' -ForegroundColor Cyan
    Write-Host "Workspace: $repoRoot"

    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw 'Flutter CLI not found on PATH. Install Flutter and ensure `flutter` is available.'
    }

    if (-not (Test-Path (Join-Path $repoRoot 'assets\logo.png'))) {
        throw 'Missing assets\logo.png required by msix_config.logo_path.'
    }

    Write-Host '==> Step 1/3: Resolving Flutter packages...' -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "flutter pub get failed with exit code $LASTEXITCODE."
    }

    if (-not $SkipChecks) {
        Write-Host '==> Step 2/3: Running static analysis...' -ForegroundColor Cyan
        flutter analyze
        if ($LASTEXITCODE -ne 0) {
            throw "flutter analyze failed with exit code $LASTEXITCODE."
        }

        if (-not $SkipTests) {
            Write-Host '==> Running test suite before packaging...' -ForegroundColor Cyan
            flutter test
            if ($LASTEXITCODE -ne 0) {
                throw "flutter test failed with exit code $LASTEXITCODE."
            }
        }
    }

    $msixArgs = @('pub', 'run', 'msix:create')

    if ($Store) {
        $msixArgs += '--store'
    }
    if ($NoInstallCert) {
        $msixArgs += @('--install-certificate', 'false')
    }
    if (-not [string]::IsNullOrWhiteSpace($CertificatePath)) {
        $msixArgs += @('--certificate-path', $CertificatePath)
    }
    if (-not [string]::IsNullOrWhiteSpace($CertificatePassword)) {
        $msixArgs += @('--certificate-password', $CertificatePassword)
    }
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $msixArgs += @('--output-path', $OutputPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($OutputName)) {
        $msixArgs += @('--output-name', $OutputName)
    }

    Write-Host "==> Step 3/3: Creating MSIX installer (flutter $($msixArgs -join ' '))..." -ForegroundColor Cyan
    & flutter @msixArgs
    if ($LASTEXITCODE -ne 0) {
        throw "MSIX packaging failed with exit code $LASTEXITCODE."
    }

    $searchRoot = if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath
    } else {
        Join-Path $repoRoot 'build\windows'
    }

    if (Test-Path $searchRoot) {
        $packages = Get-ChildItem -Path $searchRoot -Filter '*.msix' -Recurse -ErrorAction SilentlyContinue
        if ($packages) {
            Write-Host '==> Generated MSIX installer(s):' -ForegroundColor Green
            foreach ($pkg in $packages) {
                Write-Host "    $($pkg.FullName)"
            }
        }
    }
}
finally {
    Pop-Location
}
