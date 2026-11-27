<#
.SYNOPSIS
    One /kevutest run on one client, from start to results, with the kit's game-input tools: nobody needs to type, and
    with -Vendor nobody needs to touch the game at all (docs/work/2026-11-27-kevutest-input).

.DESCRIPTION
    Deploy first (the kit's Deploy.ps1, -WhatIf first): this tool deploys nothing. The client must be running and in the
    world, with the character next to a vendor that sells more than one page. Then:
    1. The kit's marker addon is installed or updated in the client (Send-GameInput.ps1 -Install).
    2. /reload, so the deployed files and the marker load (-NoReload skips it, with a vendor window already open).
    3. /kevutest: it starts at once on an open vendor window, or when one opens. -Vendor x,y right-clicks the vendor on
       that spot of a Send-GameInput.ps1 -Capture; without it a person opens the vendor.
    4. Send-GameInput.ps1 -WaitForDone: it serves the clicks and hovers of the last steps (a currency in the token banner,
       the repair-all button, an item, the Buyback and Merchant tabs; clicks only in a client the kit started) and
       returns when the run reports done.
    5. /reload, so the results reach the saved variables, then Read-GameTests.ps1 -Last 1 and the kit's
       Read-GameErrors.ps1.

    Exits 0 only when a run started by this call reached the saved variables with no FAIL and something passed, 1
    otherwise. The kit's guard holds throughout: a client the kit started takes input after 15 s without input on the
    PC, any other after 5 minutes. A refusal that says when to try again is retried then, for up to 10 minutes.

.PARAMETER Client
    Retail (default), Classic (Mists), Anniversary, Era, Forever, or another -Client value of the kit's tools.

.PARAMETER Vendor
    The vendor's spot on a Send-GameInput.ps1 -Capture of this client, as x,y; right-clicked after /kevutest.

.PARAMETER NoReload
    No /reload before the run, so a vendor window that is open stays open.

.PARAMETER Timeout
    Seconds from /kevutest to done, opening the vendor included. Default 600.

.EXAMPLE
    & ".claude\tools\Run-GameTests.ps1"
    & ".claude\tools\Run-GameTests.ps1" -Client Classic -Vendor 935,495
    & ".claude\tools\Run-GameTests.ps1" -NoReload
#>
[CmdletBinding()]
param(
    [ValidateSet('Retail', 'Ptr', 'Xptr', 'Beta', 'Classic', 'ClassicPtr', 'Era', 'EraPtr', 'Anniversary', 'Forever')][string]$Client = 'Retail',
    [ValidatePattern('^\d+,\d+$')][string]$Vendor,
    [switch]$NoReload,
    [int]$Timeout = 600
)

$ErrorActionPreference = 'Stop'
# The kit is Krowi_ClaudeKit next to this repo's main checkout; a worktree resolves to the same folder
$common = git -C $PSScriptRoot rev-parse --path-format=absolute --git-common-dir 2>$null
if ($LASTEXITCODE -ne 0 -or -not $common) { throw "$PSScriptRoot is not inside a git checkout." }
$kitTools = Join-Path (Split-Path (Split-Path ($common.Trim() -replace '/', '\') -Parent) -Parent) 'Krowi_ClaudeKit\tools'
if (-not (Test-Path -LiteralPath (Join-Path $kitTools 'AddonContext.ps1'))) { throw "Krowi_ClaudeKit not found at $kitTools." }
. (Join-Path $kitTools 'AddonContext.ps1')   # Get-ClientFolder
$send = Join-Path $kitTools 'Send-GameInput.ps1'

# One kit call, its lines shown as they come; a refusal that says when to try again is retried then, for up to 10
# minutes. Returns the call's exit code; $script:lastAttempt holds when its last attempt began.
$lastAttempt = Get-Date
function Invoke-Kit([string]$What, [hashtable]$Arguments) {
    $retryUntil = (Get-Date).AddMinutes(10)
    while ($true) {
        $script:lastAttempt = Get-Date
        $out = @(& $send -Client $Client @Arguments 2>&1 | ForEach-Object { "$_" })
        $code = $LASTEXITCODE
        $out | ForEach-Object { Write-Host "  $_" }
        $last = if ($out) { $out[-1] } else { '' }
        if ($code -eq 0 -or $last -notmatch 'try again in (\d+) s') { return $code }
        if ((Get-Date) -gt $retryUntil) { Write-Host "  $What gave up: still refused after 10 minutes"; return $code }
        Start-Sleep -Seconds ([int]$Matches[1] + 2)
    }
}
function Stop-Run([string]$Reason) { "Run-GameTests: $Reason"; exit 1 }

# The saved variables Read-GameTests.ps1 reads: the newest Krowi_ExtendedVendorUI.lua of the client's accounts
$wtf = Join-Path (Get-ClientFolder $Client) 'WTF\Account'
function Get-SavedVariablesFile {
    if (-not (Test-Path -LiteralPath $wtf)) { return }
    Get-ChildItem -LiteralPath $wtf -Directory | ForEach-Object { Join-Path $_.FullName 'SavedVariables\Krowi_ExtendedVendorUI.lua' } |
        Where-Object { Test-Path -LiteralPath $_ } | Get-Item | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}
# $true once the game has written the saved variables at or after $Since and the file has stayed the same for a
# second; the kit can report the UI back while the reload has only begun
function Wait-SavedVariables([datetime]$Since, [int]$Seconds = 60) {
    $until = (Get-Date).AddSeconds($Seconds)
    $seen = $null
    while ($true) {
        $file = Get-SavedVariablesFile
        if ($file -and $file.LastWriteTime -ge $Since) {
            $now = "$($file.LastWriteTime.Ticks)|$($file.Length)"
            if ($now -eq $seen) { return $true }
            $seen = $now
        }
        if ((Get-Date) -gt $until) { return $false }
        Start-Sleep -Seconds 1
    }
}

"Run-GameTests: /kevutest on $Client"
$null = & $send -Client $Client -Install
$state = (& $send -Client $Client -State 2>&1 | Out-String)
if ($state -notmatch 'state: in the world') {
    $stateLine = ((($state -split "`r?`n") | Where-Object { $_ -match 'client:|state:' }) -join '; ').Trim()
    Stop-Run "the $Client client is not in the world ($stateLine): start it with Start-Game.ps1 -Wait and Send-GameInput.ps1 -EnterWorld first"
}

if (-not $NoReload) {
    '/reload, so the deployed files and the marker load'
    if ((Invoke-Kit '/reload' @{ Command = '/reload' }) -ne 0) { Stop-Run 'the first /reload failed' }
}

'/kevutest'
$runStart = Get-Date
if ((Invoke-Kit '/kevutest' @{ Command = '/kevutest' }) -ne 0) { Stop-Run 'could not type /kevutest' }
if ($Vendor) {
    "Opening the vendor at $Vendor"
    if ((Invoke-Kit 'the vendor click' @{ Click = $Vendor; Button = 'Right' }) -ne 0) { Stop-Run 'could not right-click the vendor' }
} else {
    'Waiting for a vendor window: open one, if none is open'
}

'Waiting for the run to be done'
$waited = Invoke-Kit 'waiting' @{ WaitForDone = $true; Timeout = $Timeout }

# Also after a timeout: a run that ended still reaches the saved variables
'/reload, so the results reach the saved variables'
if ((Invoke-Kit '/reload' @{ Command = '/reload' }) -ne 0) { Stop-Run 'the /reload after the run failed' }
if (-not (Wait-SavedVariables $lastAttempt)) { Stop-Run 'the saved variables were not written within 60 s of the /reload' }

$reader = Join-Path $PSScriptRoot 'Read-GameTests.ps1'
$listing = @(& $reader -Client $Client -Last 1 2>&1 | ForEach-Object { "$_" })
$listing
& (Join-Path $kitTools 'Read-GameErrors.ps1') -Client $Client

# The newest run in the summary ("10. 2026-11-27 19:38:07  12.1.5 (70961)  CanIMogIt: 120 passed, 1 failed, 8 skipped")
$summary = @($listing | Where-Object { $_ -match '^\s*\d+\. \d{4}-\d\d-\d\d \d\d:\d\d:\d\d ' })
if (-not $summary) { Stop-Run 'no run in the saved variables' }
$newest = $summary[-1]
if ($newest -notmatch '^\s*\d+\. (\d{4}-\d\d-\d\d \d\d:\d\d:\d\d) .*?(\d+) passed, (\d+) failed') { Stop-Run "could not read the run's summary: $newest" }
$time = [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
$passed, $failed = [int]$Matches[2], [int]$Matches[3]
if ($time -lt $runStart.AddSeconds(-1)) { Stop-Run "no run of this call reached the saved variables (the newest is from $time)$(if ($waited -ne 0) { '; the wait for done failed, see above' })" }
if ($waited -ne 0) { Stop-Run 'the run did not report done in time (see above)' }
if ($failed -gt 0 -or $passed -eq 0) { Stop-Run "the run failed $failed and passed $passed" }
"Run-GameTests: done, $passed passed, $failed failed"
exit 0
