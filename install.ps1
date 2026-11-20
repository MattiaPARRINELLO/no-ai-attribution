# install.ps1 - install the no-ai-attribution Git hooks and helper on Windows.
$ErrorActionPreference = "Stop"

$SrcDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$HooksDir = Join-Path $env:USERPROFILE ".config\git\hooks"
$BinDir = Join-Path $env:USERPROFILE ".local\bin"
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"

function Say($Message) { Write-Host $Message }

function Install-File($Source, $Destination) {
    if (-not (Test-Path $Source)) {
        throw "missing source file: $Source"
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    if (Test-Path $Destination) {
        $same = (Get-FileHash $Source).Hash -eq (Get-FileHash $Destination).Hash
        if (-not $same) {
            Copy-Item $Destination "$Destination.bak-$Stamp"
            Say "backup: $Destination.bak-$Stamp"
        }
    }
    Copy-Item $Source $Destination -Force
    Say "installed: $Destination"
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is required, install Git for Windows first"
}

Install-File (Join-Path $SrcDir "hooks\commit-msg") (Join-Path $HooksDir "commit-msg")
Install-File (Join-Path $SrcDir "hooks\ai-agents.regex") (Join-Path $HooksDir "ai-agents.regex")
Install-File (Join-Path $SrcDir "bin\git-purge-ai-attribution") (Join-Path $BinDir "git-purge-ai-attribution")

# Git runs hooks through sh: use forward slashes in the path.
$HooksPath = $HooksDir -replace '\\', '/'
git config --global core.hooksPath $HooksPath
Say "git config: core.hooksPath=$HooksPath"

if (-not (Get-Command git-filter-repo -ErrorAction SilentlyContinue)) {
    Say ""
    Say "note: git-filter-repo was not found. It is only needed to rewrite existing history."
    Say "      Install it with: pip install --user git-filter-repo"
}

Say ""
Say "Done. New commits will have AI Co-Authored-By trailers removed."
Say "Test it:"
Say '  git commit --allow-empty -m "test" -m "Co-Authored-By: Claude <noreply@anthropic.com>"'
Say "  git log -1 --format=%B"
Say ""
Say "To purge an existing history, open Git Bash and run:"
Say '  bash ~/.local/bin/git-purge-ai-attribution --dry-run'
