# Lists the game's global strings (GlobalStrings.db2, enUS) whose tag or text contains one of the -Terms, from
# wow.tools.local, so a session can see which Blizzard strings a tooltip line may come from (#126).
#   .\.claude\tools\Find-GlobalString.ps1 -Terms 'Already known'
#   .\.claude\tools\Find-GlobalString.ps1 -Terms 'Already known' -Client Classic
# -CaseSensitive keeps only rows whose text holds a term with exactly that case. The build comes from the kit's
# Get-WowBuilds.ps1. Pre-requisite: wow.tools.local is running (Krowi_AchievementFilter's
# .claude\skills\add-zone-data\_start_server.ps1 starts it).
param(
    [Parameter(Mandatory)] [string[]] $Terms,
    [ValidateSet('Retail', 'Classic')] [string] $Client = 'Retail',
    [switch] $CaseSensitive
)
. "E:\World of Warcraft Addon Development\Krowi_ClaudeKit\tools\Get-WowBuilds.ps1"
$baseUrl = 'http://localhost:5000'
$build = (Get-WowBuilds -BaseUrl $baseUrl)[$Client]
Write-Host "GlobalStrings, $Client $build"
foreach ($term in $Terms) {
    $body = 'draw=1&start=0&length=200&search[value]=' + [uri]::EscapeDataString($term)
    $resp = Invoke-WebRequest "$baseUrl/dbc/data/globalstrings/?build=$build" -Method POST -Body $body `
        -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing
    $json = $resp.Content | ConvertFrom-Json
    Write-Host "== '$term': $($json.recordsFiltered) row(s)"
    if ($json.recordsFiltered -gt $json.data.Count) {
        Write-Warning "only the first $($json.data.Count) rows are shown; narrow the term"
    }
    foreach ($row in $json.data) {
        # Columns: ID, BaseTag, TagText_lang, Flags
        $cells = @($row | ForEach-Object { [System.Net.WebUtility]::HtmlDecode([string]$_) })
        if ($CaseSensitive -and -not ($cells.Count -gt 2 -and $cells[2].Contains($term))) {
            continue
        }
        Write-Host ($cells -join ' | ')
    }
}