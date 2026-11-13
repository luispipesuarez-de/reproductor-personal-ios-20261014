# Captura respuestas anonimas de YouTube Music (cliente WEB_REMIX, sin cookies) para usarlas como fixtures de pruebas.
# Uso: powershell -File scripts/capture-ytm-fixtures.ps1 [-Out <carpeta>] [-Artist "Juan Luis Guerra"] [-Country AR]
param(
  [string]$Out = "$PSScriptRoot\..\build\ytm-raw",
  [string]$Artist = "Juan Luis Guerra",
  [string]$Country = "AR",
  [string]$Language = "es"
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$ua = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15'
$version = '1.' + (Get-Date).AddDays(-3).ToString('yyyyMMdd') + '.01.00'
$script:visitor = $null

function Invoke-Ytm([string]$endpoint, [hashtable]$extra, [string]$file) {
  $body = @{ context = @{ client = @{ clientName = 'WEB_REMIX'; clientVersion = $version; hl = $Language; gl = $Country } } }
  foreach ($k in $extra.Keys) { $body[$k] = $extra[$k] }
  $headers = @{ Origin = 'https://music.youtube.com'; 'User-Agent' = $ua }
  if ($script:visitor) { $headers['X-Goog-Visitor-Id'] = $script:visitor }
  $json = $body | ConvertTo-Json -Depth 10 -Compress
  $r = Invoke-WebRequest -Uri "https://music.youtube.com/youtubei/v1/${endpoint}?prettyPrint=false" -Method POST `
       -Body ([Text.Encoding]::UTF8.GetBytes($json)) -ContentType 'application/json; charset=utf-8' -Headers $headers -UseBasicParsing
  $text = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
  [IO.File]::WriteAllText("$Out\$file", $text, (New-Object Text.UTF8Encoding $false))
  $obj = $text | ConvertFrom-Json
  if (-not $script:visitor) { $script:visitor = $obj.responseContext.visitorData }
  Start-Sleep -Milliseconds 800
  return $obj
}

# Busca recursivamente todos los objetos que tengan la propiedad indicada.
function Find-Prop($node, [string]$name, [System.Collections.ArrayList]$acc) {
  if ($null -eq $node) { return }
  if ($node -is [System.Collections.IEnumerable] -and $node -isnot [string]) { foreach ($i in $node) { Find-Prop $i $name $acc }; return }
  if ($node -is [pscustomobject]) {
    foreach ($p in $node.PSObject.Properties) {
      if ($p.Name -eq $name) { [void]$acc.Add($p.Value) }
      Find-Prop $p.Value $name $acc
    }
  }
}

$all = Invoke-Ytm 'search' @{ query = $Artist } 'ytm-search-all.json'
$chips = New-Object System.Collections.ArrayList; Find-Prop $all 'chipCloudChipRenderer' $chips
$chipParams = @{}
foreach ($c in $chips) { $t = $c.text.runs[0].text; $p = $c.navigationEndpoint.searchEndpoint.params; if ($t -and $p) { $chipParams[$t] = $p } }
"Chips: " + ($chipParams.Keys -join ', ')
$chipParams.GetEnumerator() | % { "$($_.Key) => $($_.Value)" } | Set-Content "$Out\chips.txt"

# ---- Resultados filtrados ----
$songs = Invoke-Ytm 'search' @{ query = $Artist; params = $chipParams['Canciones'] } 'ytm-search-songs.json'
$albums = Invoke-Ytm 'search' @{ query = $Artist; params = $chipParams['Álbumes'] } 'ytm-search-albums.json'
$artists = Invoke-Ytm 'search' @{ query = $Artist; params = $chipParams['Artistas'] } 'ytm-search-artists.json'

# ---- Artista ----
$browseIds = New-Object System.Collections.ArrayList; Find-Prop $artists 'browseId' $browseIds
$artistId = ($browseIds | Where-Object { $_ -like 'UC*' } | Select-Object -First 1)
"Artista: $artistId"
$artistPage = Invoke-Ytm 'browse' @{ browseId = $artistId } 'ytm-artist.json'

# Secciones con boton "Ver todo" (moreContentButton) -> browseId + params
$more = New-Object System.Collections.ArrayList; Find-Prop $artistPage 'musicCarouselShelfBasicHeaderRenderer' $more
$sections = @()
foreach ($h in $more) {
  $title = $h.title.runs[0].text
  $be = $h.moreContentButton.buttonRenderer.navigationEndpoint.browseEndpoint
  if ($be) { $sections += [pscustomobject]@{ Title = $title; BrowseId = $be.browseId; Params = $be.params } }
}
$sections | Format-Table -AutoSize | Out-String -Width 200 | Set-Content "$Out\sections.txt"
Get-Content "$Out\sections.txt"
$shelf = New-Object System.Collections.ArrayList; Find-Prop $artistPage 'musicShelfRenderer' $shelf
foreach ($s in $shelf) { $be = $s.title.runs[0].navigationEndpoint.browseEndpoint; if ($be) { "Canciones ver-todo: $($be.browseId)"; $songsAll = $be.browseId } }

$albumSection = $sections | Where-Object { $_.Title -match 'lbum' } | Select-Object -First 1
if ($albumSection) { [void](Invoke-Ytm 'browse' @{ browseId = $albumSection.BrowseId; params = $albumSection.Params } 'ytm-artist-albums.json') }
$singleSection = $sections | Where-Object { $_.Title -match 'encillo|ingle' } | Select-Object -First 1
if ($singleSection) { [void](Invoke-Ytm 'browse' @{ browseId = $singleSection.BrowseId; params = $singleSection.Params } 'ytm-artist-singles.json') }
if ($songsAll) {
  $sp = Invoke-Ytm 'browse' @{ browseId = $songsAll } 'ytm-artist-songs.json'
  $tok = New-Object System.Collections.ArrayList; Find-Prop $sp 'token' $tok
  if ($tok.Count -gt 0) { [void](Invoke-Ytm 'browse' @{ continuation = $tok[0] } 'ytm-artist-songs-continuation.json') }
}

# ---- Album ----
$albumIds = New-Object System.Collections.ArrayList; Find-Prop $albums 'browseId' $albumIds
$albumId = ($albumIds | Where-Object { $_ -like 'MPREb_*' } | Select-Object -First 1)
"Album: $albumId"
if ($albumId) { [void](Invoke-Ytm 'browse' @{ browseId = $albumId } 'ytm-album.json') }

# ---- Radio ----
$vids = New-Object System.Collections.ArrayList; Find-Prop $songs 'videoId' $vids
$videoId = $vids | Select-Object -First 1
"Video semilla: $videoId"
$radio = Invoke-Ytm 'next' @{ videoId = $videoId; playlistId = "RDAMVM$videoId"; isAudioOnly = $true } 'ytm-radio.json'
$rt = New-Object System.Collections.ArrayList; Find-Prop $radio 'continuation' $rt
$cont = $rt | Where-Object { $_ -is [string] } | Select-Object -First 1
"Continuacion radio: $cont"
if ($cont) { [void](Invoke-Ytm 'next' @{ continuation = $cont } 'ytm-radio-continuation.json') }
Get-ChildItem $Out | Select-Object Name, Length | Format-Table -AutoSize
