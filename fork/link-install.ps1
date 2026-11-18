# Installs this fork's archify/ folder as the live archify skill by junction (Windows).
# A junction is a link, not a copy: edits in this checkout reach the agents at once, and the
# working tree (including a half-edited or switched branch) is what they read.
#
#   pwsh fork/link-install.ps1 status       show what ~/.agents/skills/archify is
#   pwsh fork/link-install.ps1 install      replace it with a junction to this fork's archify/
#   pwsh fork/link-install.ps1 uninstall    remove the junction (nothing is installed afterwards)
#
# install refuses to replace a real folder (an `npx skills` install) unless -Force is given.
# After uninstall, restore the upstream skill with:  npx skills add tt-a1i/archify --skill archify -g
# ~/.claude/skills/archify is a link to ~/.agents/skills/archify and needs no change.

param(
    [Parameter(Position = 0)][ValidateSet('status', 'install', 'uninstall')][string]$Action = 'status',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$repo   = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$source = Join-Path $repo 'archify'
$target = Join-Path $HOME '.agents\skills\archify'

function Get-State {
    if (-not (Test-Path $target)) { return 'missing' }
    $item = Get-Item $target -Force
    if ($item.LinkType) { return "link:$($item.LinkType)->$($item.Target)" }
    return 'folder'
}

# A junction is removed without touching its contents; Remove-Item -Recurse would not be safe on one.
function Remove-Link {
    (Get-Item $target -Force).Delete()
    if (Test-Path $target) { throw "could not remove $target" }
}

if (-not (Test-Path (Join-Path $source 'SKILL.md'))) { throw "no SKILL.md in $source" }

switch ($Action) {
    'status' {
        $branch = (git -C $repo branch --show-current)
        Write-Host "target : $target"
        Write-Host "state  : $(Get-State)"
        Write-Host "source : $source (branch $branch)"
    }
    'install' {
        $state = Get-State
        if ($state -like 'link:*') { Remove-Link }
        elseif ($state -eq 'folder') {
            if (-not $Force) { throw "$target is a real folder. Re-run with -Force to delete it, or move it away first." }
            Remove-Item $target -Recurse -Force
        }
        New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
        New-Item -ItemType Junction -Path $target -Target $source | Out-Null
        Write-Host "linked $target -> $source (branch $(git -C $repo branch --show-current))"
    }
    'uninstall' {
        $state = Get-State
        if ($state -like 'link:*') { Remove-Link; Write-Host "removed link $target" }
        elseif ($state -eq 'missing') { Write-Host 'nothing installed' }
        else { throw "$target is a real folder, not a link; not touching it." }
    }
}
