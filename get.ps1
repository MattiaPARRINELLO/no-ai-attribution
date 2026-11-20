# get.ps1 - one-line installer for no-ai-attribution on Windows.
#
#   irm https://raw.githubusercontent.com/MattiaPARRINELLO/no-ai-attribution/main/get.ps1 | iex
#
$ErrorActionPreference = "Stop"

$Repo = if ($env:NO_AI_ATTRIBUTION_REPO) {
    $env:NO_AI_ATTRIBUTION_REPO
} else {
    "https://github.com/MattiaPARRINELLO/no-ai-attribution"
}
$Ref = if ($env:NO_AI_ATTRIBUTION_REF) { $env:NO_AI_ATTRIBUTION_REF } else { "main" }

$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("no-ai-attribution-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Tmp | Out-Null

try {
    $Zip = Join-Path $Tmp "src.zip"
    Write-Host "Telechargement de $Repo ($Ref)..."
    Invoke-WebRequest -UseBasicParsing "$Repo/archive/refs/heads/$Ref.zip" -OutFile $Zip

    Expand-Archive -Path $Zip -DestinationPath $Tmp -Force

    $Src = Get-ChildItem $Tmp -Directory |
        Where-Object { $_.Name -like "no-ai-attribution-*" } |
        Select-Object -First 1
    if (-not $Src) {
        throw "unexpected archive layout"
    }

    & (Join-Path $Src.FullName "install.ps1")
}
finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
