<#
.SYNOPSIS
    Prints the /kevutest runs with the screenshot of each step, so a build is checked on a client from one in-game
    pass: the kit's Deploy.ps1 -> /reload -> open a vendor -> /kevutest -> /reload -> Read-GameTests.ps1.

.DESCRIPTION
    Finds the most recently written Krowi_ExtendedVendorUI.lua under the client's WTF\Account\*\SavedVariables, reads
    the runs in KrowiEVU_Debug.Tests.Runs (the last 10, oldest first; Tests\Tests.lua writes them) with the kit's
    Lua 5.1, and prints every step's checks
    (PASS, FAIL, SKIP, INFO) with the path of the screenshot the routine took for that step, matched by the time in the
    screenshot's file name (WoWScrnShot_MMDDYY_HHMMSS). Open those paths with the Read tool; the banner above the vendor
    window names the step in each screenshot too. A summary line per run comes last.

    The game writes saved variables on /reload and logout only, so a run that just finished is not in the file until
    the next /reload. The header shows when the file was last written. Screenshots are written at once.

.PARAMETER Client
    Retail (default), Classic (Mists), Anniversary, Era, or another -Client value of the kit's tools.

.PARAMETER Account
    Account folder name (e.g. 133658957#1) instead of the most recently written file.

.PARAMETER Last
    Only the newest N runs in full; the summary still lists every kept run. Default 0, all of them.

.EXAMPLE
    & ".claude\tools\Read-GameTests.ps1"
    & ".claude\tools\Read-GameTests.ps1" -Client Era -Last 1
#>
[CmdletBinding()]
param(
    [ValidateSet('Retail', 'Ptr', 'Xptr', 'Beta', 'Classic', 'ClassicPtr', 'Era', 'EraPtr', 'Anniversary', 'Forever')][string]$Client = 'Retail',
    [string]$Account,
    [ValidateRange(0, [int]::MaxValue)][int]$Last = 0
)

$ErrorActionPreference = 'Stop'
# The kit is Krowi_ClaudeKit next to this repo's main checkout; a worktree resolves to the same folder
$common = git -C $PSScriptRoot rev-parse --path-format=absolute --git-common-dir 2>$null
if ($LASTEXITCODE -ne 0 -or -not $common) { throw "$PSScriptRoot is not inside a git checkout." }
$kitTools = Join-Path (Split-Path (Split-Path ($common.Trim() -replace '/', '\') -Parent) -Parent) 'Krowi_ClaudeKit\tools'
if (-not (Test-Path -LiteralPath (Join-Path $kitTools 'AddonContext.ps1'))) { throw "Krowi_ClaudeKit not found at $kitTools." }
. (Join-Path $kitTools 'AddonContext.ps1')   # Get-ClientFolder, $Lua

$clientDir = Get-ClientFolder $Client
$wtf = Join-Path $clientDir 'WTF\Account'
if (-not (Test-Path -LiteralPath $wtf)) { throw "No WTF\Account folder for $Client at $wtf" }
$file = if ($Account) {
    Get-Item -LiteralPath (Join-Path $wtf "$Account\SavedVariables\Krowi_ExtendedVendorUI.lua")
} else {
    Get-ChildItem -LiteralPath $wtf -Directory | ForEach-Object { Join-Path $_.FullName 'SavedVariables\Krowi_ExtendedVendorUI.lua' } |
        Where-Object { Test-Path -LiteralPath $_ } | Get-Item | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}
if (-not $file) { throw "No Krowi_ExtendedVendorUI.lua under $wtf; has the client been reloaded since the addon was installed?" }

$age = (Get-Date) - $file.LastWriteTime
"Saved variables: $($file.FullName)"
"  last written $($file.LastWriteTime) ($([int]$age.TotalMinutes) min ago; the game writes it on /reload or logout only)"
""

$records = @(& $Lua (Join-Path $PSScriptRoot 'read-tests.lua') $file.FullName)
if ($LASTEXITCODE -ne 0) { throw "Could not read $($file.FullName)" }
if ($records.Count -eq 1 -and $records[0] -eq 'NONE') {
    "No /kevutest run in this file yet."
    return
}

# Screenshots by the time in their name
$invariant = [Globalization.CultureInfo]::InvariantCulture
$shots = @()
$shotDir = Join-Path $clientDir 'Screenshots'
if (Test-Path -LiteralPath $shotDir) {
    $shots = @(Get-ChildItem -LiteralPath $shotDir -File -Filter 'WoWScrnShot_*' | ForEach-Object {
        if ($_.BaseName -match '^WoWScrnShot_(\d{6})_(\d{6})$') {
            [pscustomobject]@{ Time = [datetime]::ParseExact($Matches[1] + $Matches[2], 'MMddyyHHmmss', $invariant); Path = $_.FullName }
        }
    })
}

$runCount = @($records | Where-Object { $_ -like "RUN`t*" }).Count
$firstShown = if ($Last -gt 0) { [Math]::Max(1, $runCount - $Last + 1) } else { 1 }
$summary = [Collections.Generic.List[object]]::new()
$runStart = $null
$run = 0
foreach ($record in $records) {
    $fields = $record -split "`t"
    if ($fields[0] -eq 'RUN') {
        $run = [int]$fields[1]
        $summary.Add([ordered]@{ Run = $run })
        if ($run -ge $firstShown) { ''; "===== Run $run of $runCount" }
        continue
    }
    if ($fields[0] -eq 'HEAD' -and $summary.Count -gt 0) { $summary[$summary.Count - 1][$fields[1]] = $fields[2] }
    if ($run -lt $firstShown) { continue }
    switch ($fields[0]) {
        'HEAD' {
            if ($fields[1] -eq 'Time') { $runStart = [datetime]::ParseExact($fields[2], 'yyyy-MM-dd HH:mm:ss', $invariant) }
            '{0,-9} {1}' -f ($fields[1] + ':'), $fields[2]
            # The routine only records screenshotQuality: setting a CVar from addon code taints Blizzard's CVAR_UPDATE handlers
            if ($fields[1] -eq 'Quality' -and [int]$fields[2] -lt 8) {
                '          screenshots below quality 8 lose small text when read scaled down; Krowi can type /console screenshotQuality 10 once in game'
            }
        }
        'STEP' {
            ''
            '{0}. {1}: {2}' -f $fields[1], $fields[2], $fields[3]
            if ($fields[4] -and $runStart) {
                $stepTime = [datetime]::ParseExact($runStart.ToString('yyyy-MM-dd', $invariant) + ' ' + $fields[4], 'yyyy-MM-dd HH:mm:ss', $invariant)
                if ($stepTime -lt $runStart.AddMinutes(-1)) { $stepTime = $stepTime.AddDays(1) }   # past midnight
                $shot = $shots | Where-Object { ($_.Time - $stepTime).TotalSeconds -ge -1 -and ($_.Time - $stepTime).TotalSeconds -le 3 } |
                    Sort-Object Time | Select-Object -First 1
                $taken = if ($fields[5] -eq 'failed') { ' (the game reported the screenshot failed)' } else { '' }
                '   screenshot at {0}: {1}{2}' -f $fields[4], $(if ($shot) { $shot.Path } else { 'none found' }), $taken
            }
        }
        'LINE' { '   ' + $fields[1] }
    }
}

''
'===== Summary, oldest first'
foreach ($entry in $summary) {
    $plugins = if ($entry['Plugins']) { $entry['Plugins'] } else { 'no plugin addon' }
    $stopped = if ($entry['Stopped']) { ", stopped: $($entry['Stopped'])" } else { '' }
    '{0,2}. {1}  {2}  {3}: {4} passed, {5} failed, {6} skipped{7}' -f $entry['Run'], $entry['Time'], $entry['Client'], $plugins,
        $entry['Passed'], $entry['Failed'], $entry['Skipped'], $stopped
}