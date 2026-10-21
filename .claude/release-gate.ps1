<#
.SYNOPSIS
    Krowi_ExtendedVendorUI's own release check. The kit's release preflight (Krowi_ClaudeKit\skills\release\
    Check-ReleaseReady.ps1) dot-sources it after its TOC checks: the build that ships must have passed /kevutest on
    every client the TOC claims, after its last change (Krowi, 2026-10-21: the test framework is part of the release).

.DESCRIPTION
    Per client in `## Interface:` (Retail, Mists Classic, TBC Anniversary, Classic Era):

    - Its AddOns folder holds exactly this checkout: the kit's Deploy.ps1 -WhatIf has nothing to copy or delete.
    - Its saved variables hold a completed /kevutest run of this version (`## Version:`) that started after the newest
      change to a file that ships (the release zip's files: no dot or .md files, nothing under .claude, .vscode,
      _Packaging, docs, raw or wiki). Several skin setups (ElvUI, GW2_UI, EllesmereUI, none) are kept apart: the
      newest completed run of each setup since that change must have no failed check. A stopped run proves nothing.

    The game writes saved variables on /reload only, so /reload after the last run. A library update in preflight
    changes shipped files, so it needs a new run. Not something to bypass: deploy, open a vendor, /kevutest, /reload.

    Uses from the preflight: $repo, $addon, $toc, $tocVersion, $Lua, $KitRoot, Get-ClientFolder, Pass, Warn and
    Fail. Its own variables stay in a child scope.
#>
& {
    $invariant = [Globalization.CultureInfo]::InvariantCulture
    $interface = (Select-String -LiteralPath $toc.FullName -Pattern '^## Interface:\s*(.+)$').Matches[0].Groups[1].Value
    $clients = @(foreach ($n in $interface -split '[,\s]+' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }) {
        $major = [math]::Floor($n / 10000); $minor = [math]::Floor($n / 100) % 100
        if ($n -ge 100000) { 'Retail' }
        elseif ($major -eq 5) { 'Classic' }
        elseif ($major -eq 2) { 'Anniversary' }
        elseif ($major -eq 1 -and $minor -eq 15) { 'Era' }
        elseif ($major -eq 1 -and $minor -eq 60) { 'Forever' }
        else { Warn "Interface $n names no client installed here; /kevutest is not checked for it" }
    }) | Select-Object -Unique

    # The newest change to a file that ships
    $excluded = '.git', '.github', '.vscode', '.claude', '_Packaging', 'raw', 'wiki', 'docs'
    $shipped = @(Get-ChildItem -LiteralPath $repo -File | Where-Object { -not $_.Name.StartsWith('.') -and $_.Extension -ne '.md' })
    foreach ($d in Get-ChildItem -LiteralPath $repo -Directory | Where-Object { $excluded -notcontains $_.Name -and -not $_.Name.StartsWith('.') }) {
        $shipped += @(Get-ChildItem -LiteralPath $d.FullName -Recurse -File -Force | Where-Object {
                $parts = $_.FullName.Substring($repo.Length + 1).Split('\')
                $_.Extension -ne '.md' -and -not ($parts | Where-Object { $excluded -contains $_ -or $_.StartsWith('.') })
            })
    }
    $newest = $shipped | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $changed = $newest.LastWriteTime
    $changedName = $newest.FullName.Substring($repo.Length + 1)

    $reader = Join-Path $repo '.claude\tools\read-tests.lua'
    $deploy = Join-Path $KitRoot 'tools\Deploy.ps1'
    foreach ($client in $clients) {
        # The installed copy is this checkout
        try { $out = (& $deploy -Repo $repo -Client $client -WhatIf 2>&1 | ForEach-Object { "$_" }) -join "`n" }
        catch { Fail "${client}: could not compare its AddOns folder with this checkout: $_"; continue }
        $m = [regex]::Match($out, '(\d+) to copy, (\d+) to delete')
        if (-not $m.Success) { Fail "${client}: could not compare its AddOns folder with this checkout"; continue }
        $differ = [int]$m.Groups[1].Value + [int]$m.Groups[2].Value
        if ($differ) { Fail "${client} runs another build ($differ file(s) differ from this checkout): deploy there, /reload, open a vendor, /kevutest, /reload"; continue }

        # The runs in every account's saved variables
        $wtf = Join-Path (Get-ClientFolder $client) 'WTF\Account'
        $files = @(if (Test-Path -LiteralPath $wtf) {
                Get-ChildItem -LiteralPath $wtf -Directory | ForEach-Object { Join-Path $_.FullName "SavedVariables\$addon.lua" } | Where-Object { Test-Path -LiteralPath $_ }
            })
        $encoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
        try {
            $runs = @(foreach ($sv in $files) {
                    $current = $null
                    foreach ($record in @(& $Lua $reader $sv 2>$null)) {
                        $f = "$record" -split "`t"
                        if ($f[0] -eq 'RUN') { if ($current) { [pscustomobject]$current }; $current = @{} }
                        elseif ($f[0] -eq 'HEAD' -and $null -ne $current) { $current[$f[1]] = $f[2] }
                    }
                    if ($current) { [pscustomobject]$current }
                })
        }
        finally { [Console]::OutputEncoding = $encoding }

        $since = @($runs | Where-Object { $_.Version -eq $tocVersion -and $_.Time -and -not $_.Stopped } | ForEach-Object {
                $_ | Add-Member -NotePropertyName Started -NotePropertyValue ([datetime]::ParseExact($_.Time, 'yyyy-MM-dd HH:mm:ss', $invariant)) -PassThru
            } | Where-Object { $_.Started -gt $changed })
        if (-not $since) {
            Fail "${client}: no completed /kevutest run of $tocVersion since the last change to a shipped file ($changedName, $($changed.ToString('yyyy-MM-dd HH:mm'))): /reload, open a vendor, /kevutest, /reload"
            continue
        }
        $setups = $since | Group-Object { if ($_.Plugins) { $_.Plugins } else { 'no skin addon' } }
        $red = @(foreach ($s in $setups) {
                $last = $s.Group | Sort-Object Started -Descending | Select-Object -First 1
                if ([int]$last.Failed -gt 0) { "$($s.Name): $($last.Failed) failed at $($last.Time)" }
            })
        if ($red) { Fail "${client}: the newest /kevutest run failed for $($red -join '; '); fix it or run that setup again" }
        else { Pass "${client}: /kevutest green since the last change ($($setups.Name -join ', '); newest $(($since | Sort-Object Started -Descending | Select-Object -First 1).Time))" }
    }
}