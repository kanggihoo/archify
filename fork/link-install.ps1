# Installs this fork's archify/ and archify-pr/ folders as live skills by junction (Windows).
# A junction is a link, not a copy: edits in this checkout reach the agents at once, and the
# working tree (including a half-edited or switched branch) is what they read.
#
#   pwsh fork/link-install.ps1 status       show what each skill location is
#   pwsh fork/link-install.ps1 install      link both skills to this checkout
#   pwsh fork/link-install.ps1 uninstall    remove the links (nothing is installed afterwards)
#
# ~/.agents/skills/<name> links to this checkout. ~/.claude/skills/<name> links to
# ~/.agents/skills/<name>; an existing ~/.claude entry is left as it is.
# install refuses to replace a real folder (an `npx skills` install) unless -Force is given.
# After uninstall, restore the upstream skills with:  npx skills add tt-a1i/archify -g

param(
    [Parameter(Position = 0)][ValidateSet('status', 'install', 'uninstall')][string]$Action = 'status',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$repo  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$names = 'archify', 'archify-pr'

function Get-State([string]$path) {
    $item = Get-Item $path -Force -ErrorAction SilentlyContinue
    if (-not $item) { return 'missing' }
    if ($item.LinkType) { return "link:$($item.LinkType)->$($item.Target)" }
    return 'folder'
}

# A link is removed without touching its contents; Remove-Item -Recurse would not be safe on one.
function Remove-Link([string]$path) {
    (Get-Item $path -Force).Delete()
    if ((Get-State $path) -ne 'missing') { throw "could not remove $path" }
}

# Check every source and destination first, so a refusal leaves nothing half installed.
foreach ($name in $names) {
    $source = Join-Path $repo $name
    if (-not (Test-Path (Join-Path $source 'SKILL.md'))) { throw "no SKILL.md in $source" }
    $target = Join-Path $HOME ".agents\skills\$name"
    if ($Action -ne 'status' -and (Get-State $target) -eq 'folder' -and -not ($Action -eq 'install' -and $Force)) {
        throw "$target is a real folder, not a link. install -Force deletes it; uninstall never touches it."
    }
}

if ($Action -eq 'status') { Write-Host "checkout : $repo (branch $(git -C $repo branch --show-current))" }

foreach ($name in $names) {
    $source = Join-Path $repo $name
    $target = Join-Path $HOME ".agents\skills\$name"
    $claude = Join-Path $HOME ".claude\skills\$name"
    $state  = Get-State $target
    switch ($Action) {
        'status' {
            Write-Host "$target : $state"
            Write-Host "$claude : $(Get-State $claude)"
        }
        'install' {
            if ($state -like 'link:*') { Remove-Link $target }
            elseif ($state -eq 'folder') { Remove-Item $target -Recurse -Force }
            New-Item -ItemType Directory -Force (Split-Path $target), (Split-Path $claude) | Out-Null
            New-Item -ItemType Junction -Path $target -Target $source | Out-Null
            Write-Host "linked $target -> $source"
            if ((Get-State $claude) -eq 'missing') {
                New-Item -ItemType Junction -Path $claude -Target $target | Out-Null
                Write-Host "linked $claude -> $target"
            }
        }
        'uninstall' {
            # Remove the ~/.claude link only when it points at the ~/.agents location handled here.
            $item = Get-Item $claude -Force -ErrorAction SilentlyContinue
            if ($item -and $item.LinkType -and "$($item.Target)" -eq $target) { Remove-Link $claude; Write-Host "removed link $claude" }
            if ($state -like 'link:*') { Remove-Link $target; Write-Host "removed link $target" }
        }
    }
}
