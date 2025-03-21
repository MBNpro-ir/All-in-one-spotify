function Format-LanguageCode {
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [string]$LanguageCode
    )

    $supportLanguages = @(
        'bn', 'cs', 'de', 'el', 'en', 'es', 'fa', 'fi', 'fil', 'fr', 'hi', 'hu',
        'id', 'it', 'ja', 'ka', 'ko', 'lv', 'pl', 'pt', 'ro', 'ru', 'sk', 'sr',
        'sv', 'ta', 'tr', 'ua', 'vi', 'zh', 'zh-TW'
    )

    switch -Regex ($LanguageCode) {
        '^bn' { $returnCode = 'bn'; break }
        '^cs' { $returnCode = 'cs'; break }
        '^de' { $returnCode = 'de'; break }
        '^el' { $returnCode = 'el'; break }
        '^en' { $returnCode = 'en'; break }
        '^es' { $returnCode = 'es'; break }
        '^fa' { $returnCode = 'fa'; break }
        '^fi$' { $returnCode = 'fi'; break }
        '^fil' { $returnCode = 'fil'; break }
        '^fr' { $returnCode = 'fr'; break }
        '^hi' { $returnCode = 'hi'; break }
        '^hu' { $returnCode = 'hu'; break }
        '^id' { $returnCode = 'id'; break }
        '^it' { $returnCode = 'it'; break }
        '^ja' { $returnCode = 'ja'; break }
        '^ka' { $returnCode = 'ka'; break }
        '^ko' { $returnCode = 'ko'; break }
        '^lv' { $returnCode = 'lv'; break }
        '^pl' { $returnCode = 'pl'; break }
        '^pt' { $returnCode = 'pt'; break }
        '^ro' { $returnCode = 'ro'; break }
        '^(ru|py)' { $returnCode = 'ru'; break }
        '^sk' { $returnCode = 'sk'; break }
        '^sr' { $returnCode = 'sr'; break }
        '^sv' { $returnCode = 'sv'; break }
        '^ta' { $returnCode = 'ta'; break }
        '^tr' { $returnCode = 'tr'; break }
        '^ua' { $returnCode = 'ua'; break }
        '^vi' { $returnCode = 'vi'; break }
        '^(zh|zh-CN)$' { $returnCode = 'zh'; break }
        '^zh-TW' { $returnCode = 'zh-TW'; break }
        Default { $returnCode = $PSUICulture; $long_code = $true; break }
    }

    if ($long_code -and $returnCode -NotIn $supportLanguages) {
        $returnCode = $returnCode -split "-" | Select-Object -First 1
    }
    if ($returnCode -NotIn $supportLanguages) {
        $returnCode = 'en'
    }
    return $returnCode
}

function Get-Link {
    param (
        [Alias("e")]
        [string]$endlink
    )

    switch ($mirror) {
        $true { return "https://spotx-official.github.io/SpotX" + $endlink }
        default { return "https://raw.githubusercontent.com/SpotX-Official/SpotX/main" + $endlink }
    }
}

function CallLang($clg) {
    $ProgressPreference = 'SilentlyContinue'
    try {
        $response = (Invoke-WebRequest -Uri (Get-Link -e "/scripts/installer-lang/$clg.ps1") -UseBasicParsing).Content
        if ($mirror) { $response = [System.Text.Encoding]::UTF8.GetString($response) }
        Invoke-Expression $response
    }
    catch {
        Write-Host "Error loading $clg language"
        Pause
        Exit
    }
}

function Get-WebData {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [int]$MaxRetries = 3,
        [int]$RetrySeconds = 3,
        [string]$OutputPath
    )

    $params = @{
        Uri        = $Url
        TimeoutSec = 15
    }

    if ($OutputPath) {
        $params['OutFile'] = $OutputPath
    }

    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try {
            $response = Invoke-RestMethod @params
            return $response
        }
        catch {
            Write-Warning "Attempt $($i+1) of $MaxRetries failed: $_"
            if ($i -lt $MaxRetries - 1) {
                Start-Sleep -Seconds $RetrySeconds
            }
        }
    }

    Write-Host
    Write-Host "ERROR: " -ForegroundColor Red -NoNewline; Write-Host "Failed to retrieve data from $Url" -ForegroundColor White
    Write-Host
    return $null
}

function Format-String {
    param(
        [string] $template,
        [object[]] $arguments
    )
    $result = $template
    for ($i = 0; $i -lt $arguments.Length; $i++) {
        $placeholder = "{${i}}"
        $value = $arguments[$i]
        $result = $result -replace [regex]::Escape($placeholder), $value
    }
    return $result
}

function incorrectValue {
    Write-Host ($lang).Incorrect "" -ForegroundColor Red -NoNewline
    Write-Host ($lang).Incorrect2 "" -NoNewline
    Start-Sleep -Milliseconds 1000
    Write-Host "3" -NoNewline
    Start-Sleep -Milliseconds 1000
    Write-Host " 2" -NoNewline
    Start-Sleep -Milliseconds 1000
    Write-Host " 1"
    Start-Sleep -Milliseconds 1000
    Clear-Host
}

function Unlock-Folder {
    $blockFileUpdate = Join-Path $env:LOCALAPPDATA 'Spotify\Update'
    if (Test-Path $blockFileUpdate -PathType Container) {
        $folderUpdateAccess = Get-Acl $blockFileUpdate
        $hasDenyAccessRule = $false
        foreach ($accessRule in $folderUpdateAccess.Access) {
            if ($accessRule.AccessControlType -eq 'Deny') {
                $hasDenyAccessRule = $true
                $folderUpdateAccess.RemoveAccessRule($accessRule)
            }
        }
        if ($hasDenyAccessRule) {
            Set-Acl $blockFileUpdate $folderUpdateAccess
        }
    }
}

function Stop-Spotify {
    param (
        [int]$maxAttempts = 5
    )

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $allProcesses = Get-Process -ErrorAction SilentlyContinue

        $spotifyProcesses = $allProcesses | Where-Object { $_.ProcessName -like "*spotify*" }

        if ($spotifyProcesses) {
            foreach ($process in $spotifyProcesses) {
                try {
                    Stop-Process -Id $process.Id -Force
                }
                catch {
                }
            }
            Start-Sleep -Seconds 1
        }
        else {
            break
        }
    }

    if ($attempt -gt $maxAttempts) {
        Write-Host "The maximum number of attempts to terminate a process has been reached."
    }
}

function DesktopFolder {
    $ErrorActionPreference = 'SilentlyContinue'
    if (Test-Path "$env:USERPROFILE\Desktop") {
        $desktop_folder = "$env:USERPROFILE\Desktop"
    }

    $regedit_desktop_folder = Get-ItemProperty -Path "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\"
    $regedit_desktop = $regedit_desktop_folder.'{754AC886-DF64-4CBA-86B5-F7FBF4FBCEF5}'

    if (-not (Test-Path "$env:USERPROFILE\Desktop")) {
        $desktop_folder = $regedit_desktop
    }
    return $desktop_folder
}

function downloadSp() {
    $webClient = New-Object -TypeName System.Net.WebClient
    Import-Module BitsTransfer -ErrorAction SilentlyContinue
    $max_x86 = [Version]"1.2.53"
    $versionParts = $onlineFull -split '\.'
    $short = [Version]"$($versionParts[0]).$($versionParts[1]).$($versionParts[2])"
    $arch = if ($short -le $max_x86) { "win32-x86" } else { "win32-x86_64" }
    $web_Url = "https://download.scdn.co/upgrade/client/$arch/spotify_installer-$onlineFull.exe"
    $local_Url = "$PWD\SpotifySetup.exe"
    $web_name_file = "SpotifySetup.exe"
    try { if (curl.exe -V) { $curl_check = $true } }
    catch { $curl_check = $false }
    try {
        if ($curl_check) {
            $stcode = curl.exe -Is -w "%{http_code} \n" -o /dev/null -k $web_Url --retry 2 --ssl-no-revoke
            if ($stcode.trim() -ne "200") {
                Write-Host "Curl error code: $stcode"; throw
            }
            curl.exe -q -k $web_Url -o $local_Url --progress-bar --retry 3 --ssl-no-revoke
            return
        }
        if (-not $curl_check -and $null -ne (Get-Module -Name BitsTransfer -ListAvailable)) {
            $ProgressPreference = 'Continue'
            Start-BitsTransfer -Source  $web_Url -Destination $local_Url  -DisplayName ($lang).Download5 -Description "$online "
            return
        }
        if (-not $curl_check -and $null -eq (Get-Module -Name BitsTransfer -ListAvailable)) {
            $webClient.DownloadFile($web_Url, $local_Url)
            return
        }
    }
    catch {
        Write-Host
        Write-Host ($lang).Download $web_name_file -ForegroundColor RED
        $Error[0].Exception
        Write-Host
        Write-Host ($lang).Download2`n
        Start-Sleep -Milliseconds 5000
        try {
            if ($curl_check) {
                $stcode = curl.exe -Is -w "%{http_code} \n" -o /dev/null -k $web_Url --retry 2 --ssl-no-revoke
                if ($stcode.trim() -ne "200") {
                    Write-Host "Curl error code: $stcode"; throw
                }
                curl.exe -q -k $web_Url -o $local_Url --progress-bar --retry 3 --ssl-no-revoke
                return
            }
            if (-not $curl_check -and $null -ne (Get-Module -Name BitsTransfer -ListAvailable) -and -not $curl_check ) {
                Start-BitsTransfer -Source  $web_Url -Destination $local_Url  -DisplayName ($lang).Download5 -Description "$online "
                return
            }
            if (-not $curl_check -and $null -eq (Get-Module -Name BitsTransfer -ListAvailable) -and -not $curl_check ) {
                $webClient.DownloadFile($web_Url, $local_Url)
                return
            }
        }
        catch {
            Write-Host ($lang).Download3 -ForegroundColor RED
            $Error[0].Exception
            Write-Host
            Write-Host ($lang).Download4`n
            ($lang).StopScript
            $tempDirectory = $PWD
            Pop-Location
            Start-Sleep -Milliseconds 200
            Remove-Item -Recurse -LiteralPath $tempDirectory
            Pause
            Exit
        }
    }
}

function Remove-Json {
    param (
        [Parameter(Mandatory = $true)]
        [Alias("j")]
        [PSObject]$Json,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Alias("p")]
        [string[]]$Properties
    )

    foreach ($Property in $Properties) {
        $Json.psobject.properties.Remove($Property)
    }
}

function Move-Json {
    param (
        [Parameter(Mandatory = $true)]
        [Alias("t")]
        [PSObject]$to,

        [Parameter(Mandatory = $true)]
        [Alias("n")]
        [string[]]$name,

        [Parameter(Mandatory = $true)]
        [Alias("f")]
        [PSObject]$from
    )

    foreach ($propertyName in $name) {
        $from | Add-Member -MemberType NoteProperty -Name $propertyName -Value $to.$propertyName
        Remove-Json -j $to -p $propertyName
    }
}

function Helper($paramname) {
    switch ($paramname) {
        "HtmlLicMin" {
            $name = "patches.json.others."
            $n = "licenses.html"
            $contents = "htmlmin"
            $json = $webjson.others
        }
        "HtmlBlank" {
            $name = "patches.json.others."
            $n = "blank.html"
            $contents = "blank.html"
            $json = $webjson.others
        }
        "MinJs" {
            $contents = "minjs"
            $json = $webjson.others
        }
        "MinJson" {
            $contents = "minjson"
            $json = $webjson.others
        }
        "FixCss" {
            $name = "patches.json.others."
            $n = "xpui.css"
            $json = $webjson.others
        }
        "Cssmin" {
            $contents = "cssmin"
            $json = $webjson.others
        }
        "DisableSentry" {
            $name = "patches.json.others."
            $n = $fileName
            $contents = "disablesentry"
            $json = $webjson.others
        }
        "Discriptions" {
            $svg_tg = $webjson.others.discriptions.svgtg
            $svg_git = $webjson.others.discriptions.svggit
            $svg_faq = $webjson.others.discriptions.svgfaq
            $replace = $webjson.others.discriptions.replace
            $replacedText = $replace -f $svg_git, $svg_tg, $svg_faq
            $webjson.others.discriptions.replace = '$1"' + $replacedText + '"})'
            $name = "patches.json.others."
            $n = "xpui-desktop-modals.js"
            $contents = "discriptions"
            $json = $webjson.others
        }
        "OffadsonFullscreen" {
            $name = "patches.json.free."
            $n = "xpui.js"
            $contents = $webjson.free.psobject.properties.name
            $json = $webjson.free
        }
        "ForcedExp" {
            $offline_patch = $offline -replace '(\d+\.\d+\.\d+)(.\d+)', '$1'
            $Enable = $webjson.others.EnableExp
            $Disable = $webjson.others.DisableExp
            $Custom = $webjson.others.CustomExp

            Move-Json -n 'HomeCarousels' -t $Enable -f $Disable
            Move-Json -n 'PeekNpv' -t $Enable -f $Disable
            Move-Json -n 'TogglePlaylistColumns' -t $Enable -f $Disable
            if ($podcast_off) { Move-Json -n 'HomePin' -t $Enable -f $Disable }
            if ([version]$offline -eq [version]'1.2.37.701' -or [version]$offline -eq [version]'1.2.38.720') {
                Move-Json -n 'DevicePickerSidePanel' -t $Enable -f $Disable
            }
            if ([version]$offline -ge [version]'1.2.41.434' -and $lyrics_block) { Move-Json -n 'Lyrics' -t $Enable -f $Disable }
            if ([version]$offline -eq [version]'1.2.30.1135') { Move-Json -n 'QueueOnRightPanel' -t $Enable -f $Disable }
            if ([version]$offline -le [version]'1.2.50.335') {
                if (-not $plus) { Move-Json -n "Plus", "AlignedCurationSavedIn" -t $Enable -f $Disable }
            }

            if (-not $topsearchbar) {
                Move-Json -n "GlobalNavBar" -t $Enable -f $Disable
                $Custom.GlobalNavBar.value = "control"
                if ([version]$offline -le [version]"1.2.45.454") {
                    Move-Json -n "RecentSearchesDropdown" -t $Enable -f $Disable }
                }
            if ([version]$offline -le [version]'1.2.50.335') {
                if (-not $funnyprogressbar) { Move-Json -n 'HeBringsNpb' -t $Enable -f $Disable }
            }
            if (-not $canvasHome) { Move-Json -n "canvasHome", "canvasHomeAudioPreviews" -t $Enable -f $Disable }

            if ($homesub_off) {
                Move-Json -n "HomeSubfeeds" -t $Enable -f $Disable
            }

            if (-not $new_theme -and [version]$offline -le [version]"1.2.13.661") {
                Move-Json -n 'RightSidebar', 'LeftSidebar' -t $Enable -f $Disable
                Remove-Json -j $Custom -p "NavAlt", 'NavAlt2'
                Remove-Json -j $Enable -p 'RightSidebarLyrics', 'RightSidebarCredits', 'RightSidebar', 'LeftSidebar', 'RightSidebarColors'
            }
            else {
                if ($rightsidebar_off -and [version]$offline -lt [version]"1.2.24.756") {
                    Move-Json -n 'RightSidebar' -t $Enable -from $Disable
                }
                else {
                    if (-not $rightsidebarcolor) { Remove-Json -j $Enable -p 'RightSidebarColors' }
                    if ($old_lyrics) { Remove-Json -j $Enable -p 'RightSidebarLyrics' }
                }
            }
            if (-not $premium) { Remove-Json -j $Enable -p 'RemoteDownloads' }

            if ($exp_spotify) {
                $objects = @(
                    @{
                        Object           = $webjson.others.CustomExp.psobject.properties
                        PropertiesToKeep = @('LyricsUpsell')
                    },
                    @{
                        Object           = $webjson.others.EnableExp.psobject.properties
                        PropertiesToKeep = @('BrowseViaPathfinder', 'HomeViaGraphQLV2')
                    }
                )

                foreach ($obj in $objects) {
                    $propertiesToRemove = $obj.Object.Name | Where-Object { $_ -notin $obj.PropertiesToKeep }
                    $propertiesToRemove | ForEach-Object {
                        $obj.Object.Remove($_)
                    }
                }
            }

            $Exp = ($Enable, $Disable, $Custom)

            foreach ($item in $Exp) {
                $itemProperties = $item | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

                foreach ($key in $itemProperties) {
                    $vers = $item.$key.version

                    if (-not ($vers.to -eq "" -or [version]$vers.to -ge [version]$offline_patch -and [version]$vers.fr -le [version]$offline_patch)) {
                        if ($item.PSObject.Properties.Name -contains $key) {
                            $item.PSObject.Properties.Remove($key)
                        }
                    }
                }
            }

            $Enable = $webjson.others.EnableExp
            $Disable = $webjson.others.DisableExp
            $Custom = $webjson.others.CustomExp

            $enableNames = foreach ($item in $Enable.PSObject.Properties.Name) {
                $webjson.others.EnableExp.$item.name
            }

            $disableNames = foreach ($item in $Disable.PSObject.Properties.Name) {
                $webjson.others.DisableExp.$item.name
            }

            $customNames = foreach ($item in $Custom.PSObject.Properties.Name) {
                $custname = $webjson.others.CustomExp.$item.name
                $custvalue = $webjson.others.CustomExp.$item.value
                $objectString = "{name:'$custname',value:'$custvalue'}"
                $objectString
            }

            if ([string]::IsNullOrEmpty($customNames)) { $customTextVariable = '[]' }
            else { $customTextVariable = "[" + ($customNames -join ',') + "]" }
            if ([string]::IsNullOrEmpty($enableNames)) { $enableTextVariable = '[]' }
            else { $enableTextVariable = "['" + ($enableNames -join "','") + "']" }
            if ([string]::IsNullOrEmpty($disableNames)) { $disableTextVariable = '[]' }
            else { $disableTextVariable = "['" + ($disableNames -join "','") + "']" }

            $replacements = @(
                @("enable:[]", "enable:$enableTextVariable"),
                @("disable:[]", "disable:$disableTextVariable"),
                @("custom:[]", "custom:$customTextVariable")
            )

            foreach ($replacement in $replacements) {
                $webjson.others.ForcedExp.replace = $webjson.others.ForcedExp.replace.Replace($replacement[0], $replacement[1])
            }

            $name = "patches.json.others."
            $n = "xpui.js"
            $contents = "ForcedExp"
            $json = $webjson.others
        }
        "RuTranslate" {
            $n = "ru.json"
            $contents = $webjsonru.psobject.properties.name
            $json = $webjsonru
        }
        "Binary" {
            $binary = $webjson.others.binary

            if ($not_block_update) { Remove-Json -j $binary -p 'block_update' }
            if ($premium) { Remove-Json -j $binary -p 'block_slots_2', 'block_slots_3' }

            $name = "patches.json.others.binary."
            $n = "Spotify.exe"
            $contents = $webjson.others.binary.psobject.properties.name
            $json = $webjson.others.binary
        }
        "Collaborators" {
            $name = "patches.json.others."
            $n = "xpui-routes-playlist.js"
            $contents = "collaboration"
            $json = $webjson.others
        }
        "Dev" {
            $name = "patches.json.others."
            $n = "xpui-routes-desktop-settings.js"
            $contents = "dev-tools"
            $json = $webjson.others
        }
        "VariousofXpui-js" {
            $VarJs = $webjson.VariousJs

            if ($premium) { Remove-Json -j $VarJs -p 'mock', 'upgradeButton', 'upgradeMenu' }

            if ($topsearchbar -or ([version]$offline -ne [version]"1.2.45.451" -and [version]$offline -ne [version]"1.2.45.454")) {
                Remove-Json -j $VarJs -p "fixTitlebarHeight"
            }

            if (-not $lyrics_block) { Remove-Json -j $VarJs -p "lyrics-block" }
            else {
                Remove-Json -j $VarJs -p "lyrics-old-on"
            }

            if (-not $devtools) { Remove-Json -j $VarJs -p "dev-tools" }
            else {
                if ([version]$offline -ge [version]"1.2.35.663") {
                    $newDevTools = $webjson.VariousJs.'dev-tools'.PSObject.Copy()
                    $newDevTools.match = $newDevTools.match[0], $newDevTools.match[2]
                    $newDevTools.replace = $newDevTools.replace[0], $newDevTools.replace[2]
                    $newDevTools.version.fr = '1.2.35'
                    $webjson.others | Add-Member -Name 'dev-tools' -Value $newDevTools -MemberType NoteProperty
                    $webjson.VariousJs.'dev-tools'.match = $webjson.VariousJs.'dev-tools'.match[1]
                    $webjson.VariousJs.'dev-tools'.replace = $webjson.VariousJs.'dev-tools'.replace[1]
                }
            }

            if ($urlform_goofy -and $idbox_goofy) {
                $webjson.VariousJs.goofyhistory.replace = $webjson.VariousJs.goofyhistory.replace -f "`"$urlform_goofy`"", "`"$idbox_goofy`""
            }
            else { Remove-Json -j $VarJs -p "goofyhistory" }

            if (-not $ru) { Remove-Json -j $VarJs -p "offrujs" }

            if (-not $premium -or ($cache_limit)) {
                if (-not $premium) {
                    $adds += $webjson.VariousJs.product_state.add
                }

                if ($cache_limit) {
                    if ($cache_limit -lt 500) { $cache_limit = 500 }
                    if ($cache_limit -gt 20000) { $cache_limit = 20000 }
                    $adds2 = $webjson.VariousJs.product_state.add2
                    if (-not ([string]::IsNullOrEmpty($adds))) { $adds2 = ',' + $adds2 }
                    $adds += $adds2 -f $cache_limit
                }
                $repl = $webjson.VariousJs.product_state.replace
                $webjson.VariousJs.product_state.replace = $repl -f "{pairs:{$adds}}"
            }
            else { Remove-Json -j $VarJs -p 'product_state' }

            if ($podcast_off -or $adsections_off) {
                $type = switch ($true) {
                    { $podcast_off -and $adsections_off } { "all" }
                    { $podcast_off -and -not $adsections_off } { "podcast" }
                    { -not $podcast_off -and $adsections_off } { "section" }
                }
                $webjson.VariousJs.block_section.replace = $webjson.VariousJs.block_section.replace -f $type
                $global:type = $type
            }
            else {
                Remove-Json -j $VarJs -p 'block_section'
            }

            $name = "patches.json.VariousJs."
            $n = "xpui.js"
            $contents = $webjson.VariousJs.psobject.properties.name
            $json = $webjson.VariousJs
        }
    }
    $paramdata = $xpui
    $novariable = "Didn't find variable "
    $offline_patch = $offline -replace '(\d+\.\d+\.\d+)(.\d+)', '$1'

    $contents | ForEach-Object {
        if ($json.$PSItem.version.to) { $to = [version]$json.$PSItem.version.to -ge [version]$offline_patch } else { $to = $true }
        if ($json.$PSItem.version.fr) { $fr = [version]$json.$PSItem.version.fr -le [version]$offline_patch } else { $fr = $false }

        $checkVer = $fr -and $to; $translate = $paramname -eq "RuTranslate"

        if ($checkVer -or $translate) {
            if ($json.$PSItem.match.Count -gt 1) {
                $count = $json.$PSItem.match.Count - 1
                $numbers = 0

                while ($numbers -le $count) {

                    if ($paramdata -match $json.$PSItem.match[$numbers]) {
                        $paramdata = $paramdata -replace $json.$PSItem.match[$numbers], $json.$PSItem.replace[$numbers]
                    }
                    else {
                        $notlog = "MinJs", "MinJson", "Cssmin"
                        if ($paramname -notin $notlog) {

                            Write-Host $novariable -ForegroundColor red -NoNewline
                            Write-Host "$name$PSItem $numbers"'in'$n
                        }
                    }
                    $numbers++
                }
            }
            if ($json.$PSItem.match.Count -eq 1) {
                if ($paramdata -match $json.$PSItem.match) {
                    $paramdata = $paramdata -replace $json.$PSItem.match, $json.$PSItem.replace
                }
                else {
                    if (-not $translate -or $err_ru) {
                        Write-Host $novariable -ForegroundColor red -NoNewline
                        Write-Host "$name$PSItem"'in'$n
                    }
                }
            }
        }
    }
    $paramdata
}

function extract ($counts, $method, $name, $helper, $add, $patch) {
    switch ($counts) {
        "one" {
            if ($method -eq "zip") {
                Add-Type -Assembly 'System.IO.Compression.FileSystem'
                $xpui_spa_patch = Join-Path (Join-Path $env:APPDATA 'Spotify\Apps') 'xpui.spa'
                $zip = [System.IO.Compression.ZipFile]::Open($xpui_spa_patch, 'update')
                $file = $zip.GetEntry($name)
                $reader = New-Object System.IO.StreamReader($file.Open())
            }
            if ($method -eq "nonezip") {
                $file = Get-Item $env:APPDATA\Spotify\Apps\xpui\$name
                $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $file
            }
            $xpui = $reader.ReadToEnd()
            $reader.Close()
            if ($helper) { $xpui = Helper -paramname $helper }
            if ($method -eq "zip") { $writer = New-Object System.IO.StreamWriter($file.Open()) }
            if ($method -eq "nonezip") { $writer = New-Object System.IO.StreamWriter -ArgumentList $file }
            $writer.BaseStream.SetLength(0)
            $writer.Write($xpui)
            if ($add) { $add | ForEach-Object { $writer.Write([System.Environment]::NewLine + $PSItem) } }
            $writer.Close()
            if ($method -eq "zip") { $zip.Dispose() }
        }
        "more" {
            Add-Type -Assembly 'System.IO.Compression.FileSystem'
            $xpui_spa_patch = Join-Path (Join-Path $env:APPDATA 'Spotify\Apps') 'xpui.spa'
            $zip = [System.IO.Compression.ZipFile]::Open($xpui_spa_patch, 'update')
            $zip.Entries | Where-Object { $_.FullName -like $name -and $_.FullName.Split('/') -notcontains 'spotx-helper' } | ForEach-Object {
                $reader = New-Object System.IO.StreamReader($_.Open())
                $xpui = $reader.ReadToEnd()
                $reader.Close()
                $xpui = Helper -paramname $helper
                $writer = New-Object System.IO.StreamWriter($_.Open())
                $writer.BaseStream.SetLength(0)
                $writer.Write($xpui)
                $writer.Close()
            }
            $zip.Dispose()
        }
        "exe" {
            $ANSI = [Text.Encoding]::GetEncoding(1251)
            $xpui = [IO.File]::ReadAllText($spotifyExecutable, $ANSI)
            $xpui = Helper -paramname $helper
            [IO.File]::WriteAllText($spotifyExecutable, $xpui, $ANSI)
        }
    }
}

function injection {
    param(
        [Alias("p")]
        [string]$ArchivePath,

        [Alias("f")]
        [string]$FolderInArchive,

        [Alias("n")]
        [string[]]$FileNames,

        [Alias("c")]
        [string[]]$FileContents,

        [Alias("i")]
        [string[]]$FilesToInject
    )

    $folderPathInArchive = "$($FolderInArchive)/"

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::Open($ArchivePath, 'Update')

    try {
        for ($i = 0; $i -lt $FileNames.Length; $i++) {
            $fileName = $FileNames[$i]
            $fileContent = $FileContents[$i]

            $entry = $archive.GetEntry($folderPathInArchive + $fileName)
            if ($null -eq $entry) {
                $stream = $archive.CreateEntry($folderPathInArchive + $fileName).Open()
            }
            else {
                $stream = $entry.Open()
            }

            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($fileContent)

            $writer.Dispose()
            $stream.Dispose()
        }

        $indexEntry = $archive.Entries | Where-Object { $_.FullName -eq "index.html" }
        if ($null -ne $indexEntry) {
            $indexStream = $indexEntry.Open()
            $reader = [System.IO.StreamReader]::new($indexStream)
            $indexContent = $reader.ReadToEnd()
            $reader.Dispose()
            $indexStream.Dispose()

            $headTagIndex = $indexContent.IndexOf("</head>")
            $scriptTagIndex = $indexContent.IndexOf("<script")

            if ($headTagIndex -ge 0 -or $scriptTagIndex -ge 0) {
                $filesToInject = if ($FilesToInject) { $FilesToInject } else { $FileNames }

                foreach ($fileName in $filesToInject) {
                    if ($fileName.EndsWith(".js")) {
                        $modifiedIndexContent = $indexContent.Insert($scriptTagIndex, "<script defer=`"defer`" src=`"/$FolderInArchive/$fileName`"></script>")
                        $indexContent = $modifiedIndexContent
                    }
                    elseif ($fileName.EndsWith(".css")) {
                        $modifiedIndexContent = $indexContent.Insert($headTagIndex, "<link href=`"/$FolderInArchive/$fileName`" rel=`"stylesheet`">")
                        $indexContent = $modifiedIndexContent
                    }
                }

                $indexEntry.Delete()
                $newIndexEntry = $archive.CreateEntry("index.html").Open()
                $indexWriter = [System.IO.StreamWriter]::new($newIndexEntry)
                $indexWriter.Write($indexContent)
                $indexWriter.Dispose()
                $newIndexEntry.Dispose()

            }
            else {
                Write-Warning "<script or </head> tag was not found in the index.html file in the archive."
            }
        }
        else {
            Write-Warning "index.html not found in xpui.spa"
        }
    }
    finally {
        if ($null -ne $archive) {
            $archive.Dispose()
        }
    }
}

function Restore-SpotX {
    Write-Host "Restoring Spotify to original state (Uninstalling SpotX)..." -ForegroundColor Yellow
    try {
        $xpui_spa_patch = Join-Path (Join-Path $env:APPDATA 'Spotify\Apps') 'xpui.spa'
        $bak_spa = Join-Path (Join-Path $env:APPDATA 'Spotify\Apps') 'xpui.bak'
        $spotify_exe_bak_patch = Join-Path $env:APPDATA 'Spotify\Spotify.bak'
        $spotifyExecutable = Join-Path $env:APPDATA 'Spotify\Spotify.exe'

        if (Test-Path -Path $bak_spa) {
            Write-Host "Restoring xpui.spa..." -ForegroundColor Cyan
            if (Test-Path -Path $xpui_spa_patch) { Remove-Item $xpui_spa_patch -Recurse -Force }
            Rename-Item $bak_spa $xpui_spa_patch
        } else {
            Write-Warning "Backup xpui.spa (xpui.bak) not found. SpotX xpui.spa restore skipped."
        }

        if (Test-Path -Path $spotify_exe_bak_patch) {
            Write-Host "Restoring Spotify.exe..." -ForegroundColor Cyan
            if (Test-Path -Path $spotifyExecutable) { Remove-Item $spotifyExecutable -Recurse -Force }
            Rename-Item $spotify_exe_bak_patch $spotifyExecutable
        } else {
            Write-Warning "Backup Spotify.exe (Spotify.bak) not found. SpotX Spotify.exe restore skipped."
        }
        Write-Host "SpotX restore completed." -ForegroundColor Green

    }
    catch {
        Write-Error "Error occurred during SpotX restore: $_"
    }
    pause
    Clear-Host
}

function Uninstall-SpotX-Fn {
    Write-Host "Uninstalling SpotX..." -ForegroundColor Yellow
    Write-Host "Restoring Spotify to original state..." -ForegroundColor Cyan
    try {
        Restore-SpotX
        Write-Host "SpotX uninstallation completed." -ForegroundColor Green
    }
    catch {
        Write-Error "Error occurred during SpotX uninstallation: $_"
    }
    pause
    Clear-Host
}

function Write-Success {
    [CmdletBinding()]
    param ()
    process {
        Write-Host -Object ' > OK' -ForegroundColor 'Green'
    }
}

function Write-Unsuccess {
    [CmdletBinding()]
    param ()
    process {
        Write-Host -Object ' > ERROR' -ForegroundColor 'Red'
    }
}

function Test-Admin {
    [CmdletBinding()]
    param ()
    begin {
        Write-Host -Object "Checking if the script is not being run as administrator..." -NoNewline
    }
    process {
        $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        -not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}

function Test-PowerShellVersion {
    [CmdletBinding()]
    param ()
    begin {
        $PSMinVersion = [version]'5.1'
    }
    process {
        Write-Host -Object 'Checking if your PowerShell version is compatible...' -NoNewline
        $PSVersionTable.PSVersion -ge $PSMinVersion
    }
}

function Move-OldSpicetifyFolder {
    [CmdletBinding()]
    param ()
    process {
        $spicetifyOldFolderPath = "$HOME\spicetify-cli"
        $spicetifyFolderPath = "$env:LOCALAPPDATA\spicetify"
        if (Test-Path -Path $spicetifyOldFolderPath) {
            Write-Host -Object 'Moving the old spicetify folder...' -NoNewline
            Copy-Item -Path "$spicetifyOldFolderPath\*" -Destination $spicetifyFolderPath -Recurse -Force
            Remove-Item -Path $spicetifyOldFolderPath -Recurse -Force
            Write-Success
        }
    }
}

function Get-Spicetify {
    [CmdletBinding()]
    param (
        [string]$version
    )
    begin {
        if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {
            $architecture = 'x64'
        }
        elseif ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
            $architecture = 'arm64'
        }
        else {
            $architecture = 'x32'
        }
        if ($version) {
            if ($version -match '^\d+\.\d+\.\d+$') {
                $targetVersion = $version
            }
            else {
                Write-Warning -Message "You have specified an invalid spicetify version: $($version) `nThe version must be in the following format: 1.2.3"
                Pause
                exit
            }
        }
        else {
            Write-Host -Object 'Fetching the latest spicetify version...' -NoNewline
            $latestRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/spicetify/cli/releases/latest'
            $targetVersion = $latestRelease.tag_name -replace 'v', ''
            Write-Success
        }
        $archivePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "spicetify.zip")
    }
    process {
        Write-Host -Object "Downloading spicetify v$targetVersion..." -NoNewline
        $Parameters = @{
            Uri            = "https://github.com/spicetify/cli/releases/download/v$targetVersion/spicetify-$targetVersion-windows-$architecture.zip"
            UseBasicParsing = $true
            OutFile        = $archivePath
        }
        Invoke-WebRequest @Parameters
        Write-Success
    }
    end {
        $archivePath
    }
}

function Add-SpicetifyToPath {
    [CmdletBinding()]
    param ()
    begin {
        Write-Host -Object 'Making spicetify available in the PATH...' -NoNewline
        $user = [EnvironmentVariableTarget]::User
        $path = [Environment]::GetEnvironmentVariable('PATH', $user)
    }
    process {
        $spicetifyOldFolderPath = "$HOME\spicetify-cli"
        $spicetifyFolderPath = "$env:LOCALAPPDATA\spicetify"
        $path = $path -replace "$([regex]::Escape($spicetifyOldFolderPath))\\*;*", ''
        if ($path -notlike "*$spicetifyFolderPath*") {
            $path = "$path;$spicetifyFolderPath"
        }
    }
    end {
        [Environment]::SetEnvironmentVariable('PATH', $path, $user)
        $env:PATH = $path
        Write-Success
    }
}

function Install-Spicetify-CLI {
    [CmdletBinding()]
    param ()
    begin {
        Write-Host -Object 'Installing Spicetify CLI...'
    }
    process {
        $spicetifyFolderPath = "$env:LOCALAPPDATA\spicetify"
        $archivePath = Get-Spicetify
        Write-Host -Object 'Extracting spicetify...' -NoNewline
        Expand-Archive -Path $archivePath -DestinationPath $spicetifyFolderPath -Force
        Write-Success
        Add-SpicetifyToPath
    }
    end {
        Remove-Item -Path $archivePath -Force -ErrorAction 'SilentlyContinue'
        Write-Host -Object 'Spicetify CLI was successfully installed!' -ForegroundColor 'Green'
    }
}

function Install-Spicetify-Marketplace {
    [CmdletBinding()]
    param ()
    begin {
        Write-Host -Object 'Starting the Spicetify Marketplace installation script..'
    }
    process {
        $Parameters = @{
            Uri             = 'https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.ps1'
            UseBasicParsing = $true
        }
        Invoke-WebRequest @Parameters | Invoke-Expression
    }
    end {
        Write-Host -Object 'Spicetify Marketplace installation script completed.' -ForegroundColor 'Green'
    }
}

function Remove-Spicetify {
    Write-Host "Uninstalling Spicetify..." -ForegroundColor Yellow
    try {
        spicetify restore --bypass-admin v
        Remove-Item -Path "$env:LOCALAPPDATA\spicetify" -Recurse -Force -ErrorAction SilentlyContinue
        [Environment]::SetEnvironmentVariable('PATH', ($env:PATH -replace ";$([regex]::Escape("$env:LOCALAPPDATA\spicetify"))"), [EnvironmentVariableTarget]::User)
        Write-Host "Spicetify uninstalled successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Error occurred during Spicetify uninstallation: $_"
    }
    pause
    Clear-Host
}

function Invoke-SpicetifyApply {
    try {
        spicetify apply --bypass-admin
		spicetify backup apply --bypass-admin
        Show-Status "Spicetify apply configured."
    } catch {
        Show-Error "Failed to configure spicetify apply."
    }
    pause
    Clear-Host
}

function Invoke-SpicetifyUpdate {
    try {
		spicetify update --bypass-admin
        spicetify restore backup apply --bypass-admin
		spicetify backup apply --bypass-admin
		spicetify apply --bypass-admin
        Show-Status "Spicetify update configured."
    } catch {
        Show-Error "Failed to configure spicetify update."
    }
    pause
    Clear-Host
}

function Invoke-SpicetifyRestore {
    try {
        spicetify restore --bypass-admin
        Show-Status "Spicetify restore configured."
    } catch {
        Show-Error "Failed to configure spicetify restore."
    }
    pause
    Clear-Host
}

function Install-Extension-LoopyLoop {
    try {
        spicetify config extensions loopyLoop.js --bypass-admin
        Show-Status "LoopyLoop extension configured."
    } catch {
        Show-Error "Failed to configure LoopyLoop extension."
    }
    pause
    Clear-Host
}

function Install-Extension-PopupLyrics {
    try {
        spicetify config extensions popupLyrics.js --bypass-admin
        Show-Status "PopupLyrics extension configured."
    } catch {
        Show-Error "Failed to configure PopupLyrics extension."
    }
    pause
    Clear-Host
}

function Install-Extension-ShufflePlus {
    try {
        spicetify config extensions shuffle+.js --bypass-admin
        Show-Status "ShufflePlus extension configured."
    } catch {
        Show-Error "Failed to configure ShufflePlus extension."
    }
    pause
    Clear-Host
}

function Install-Extension-lyrics-plus {
    try {
        spicetify config custom_apps lyrics-plus --bypass-admin
        Show-Status "lyrics-plus extension configured."
    } catch {
        Show-Error "Failed to configure lyrics-plus extension."
    }
    pause
    Clear-Host
}

function Install-Extension-new-releases {
    try {
        spicetify config custom_apps new-releases --bypass-admin
        Show-Status "new-releases extension configured."
    } catch {
        Show-Error "Failed to configure new-releases extension."
    }
    pause
    Clear-Host
}

function Install-Extension-HistoryInSidebar {
    try {
        $tempZip = "$env:TEMP\history-in-sidebar.zip"
        $customAppsPath = "$env:APPDATA\spicetify\CustomApps\history-in-sidebar"

        Show-Status "Downloading HistoryInSidebar extension..."
        Invoke-WebRequest -Uri "https://github.com/Bergbok/Spicetify-Creations/archive/refs/heads/dist/history-in-sidebar.zip" -OutFile $tempZip -ErrorAction Stop

        Show-Status "Extracting HistoryInSidebar extension..."
        Expand-Archive -Path $tempZip -DestinationPath $env:TEMP -Force

        $extractedPath = Join-Path -Path $env:TEMP -ChildPath "Spicetify-Creations-dist-history-in-sidebar"
        Rename-Item -Path $extractedPath -NewName "history-in-sidebar"

        Show-Status "Moving HistoryInSidebar to Spicetify CustomApps..."
        Move-Item -Path "$env:TEMP\history-in-sidebar" -Destination $customAppsPath -Force

        spicetify config custom_apps history-in-sidebar --bypass-admin
        Show-Status "HistoryInSidebar extension configured."
    } catch {
        Show-Error "Failed to download or configure HistoryInSidebar extension."
    }
    pause
    Clear-Host
}

function Install-AllExtensions {
    Show-Status "Installing all extensions..."

    Install-Extension-LoopyLoop
    Install-Extension-PopupLyrics
    Install-Extension-ShufflePlus
    Install-Extension-lyrics-plus
    Install-Extension-new-releases
    Install-Extension-HistoryInSidebar

    spicetify apply --bypass-admin
    Show-Status "All extensions installed and configurations applied."
    pause
    Clear-Host
}

function Show-InstallSpotifyMenu_Install {
    Write-Host "Option 1 selected: Install Spotify..." -ForegroundColor Yellow
    Write-Host "Please wait, installing Spotify..." -ForegroundColor Cyan

    try {
        $spotifyInstalled = (Test-Path -LiteralPath $spotifyExecutable)
        if ($spotifyInstalled) {
            Write-Host "Spotify is already installed. Skipping installation." -ForegroundColor Yellow
        } else {
            Write-Host "Downloading Spotify..." -ForegroundColor Cyan
            Push-Location -LiteralPath ([System.IO.Path]::GetTempPath())
            New-Item -Type Directory -Name "Spotify_Temp-$(Get-Date -UFormat '%Y-%m-%d_%H-%M-%S')" | Convert-Path | Set-Location
            downloadSp
            Write-Host ""
            Write-Host "Installing Spotify..." -ForegroundColor Cyan
            Start-Process -FilePath explorer.exe -ArgumentList "$PWD\SpotifySetup.exe" -Wait
            Pop-Location
            Write-Host "Spotify installation completed." -ForegroundColor Green
        }

    }
    catch {
        Write-Error "Error occurred during Spotify installation: $_"
    }
    pause
    Clear-Host
}

function Show-InstallSpotifyMenu_Uninstall {
    Write-Host "Option 2 selected: Uninstall Spotify..." -ForegroundColor Yellow
    Write-Host "Please wait, uninstalling Spotify..." -ForegroundColor Cyan
    try {
        if (Test-Path -LiteralPath $spotifyExecutable) {
            Write-Host "Uninstalling Spotify..." -ForegroundColor Cyan
            Start-Process -FilePath "$spotifyExecutable" -ArgumentList "/uninstall" -Wait
            Write-Host "Spotify uninstallation completed." -ForegroundColor Green
        } else {
            Write-Host "Spotify is not installed." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Error "Error occurred during Spotify uninstallation: $_"
    }
    pause
    Clear-Host
}

function Show-InstallSpotifyMenu {
    Clear-Host
    while ($true) {
        Write-Host "========= Install Spotify Menu =========" -ForegroundColor Cyan
        Write-Host "1. Spotify" -ForegroundColor White
        Write-Host "2. Uninstall Spotify" -ForegroundColor White
        Write-Host "3. Back to Main Menu" -ForegroundColor White
        Write-Host "=====================================" -ForegroundColor Cyan

        $spotifyOption = Read-Host "Select an option"

        switch ($spotifyOption) {
            "1" {
                Show-InstallSpotifyMenu_Install
            }
            "2" {
                Show-InstallSpotifyMenu_Uninstall
            }
            "3" {
                Write-Host "Back to Main Menu..." -ForegroundColor Green
                Clear-Host
                return
            }
            default {
                Write-Host "Invalid option. Please select a number from the menu." -ForegroundColor Red
                pause
                Clear-Host
            }
        }
    }
}

function Show-InstallSpicetifyMenu_Install {
    Clear-Host
    Write-Host "Option 1 selected: Install Spicetify CLI and Marketplace..." -ForegroundColor Yellow
    Write-Host "Please wait, installing Spicetify CLI and Marketplace..." -ForegroundColor Cyan
    Write-Host "If you see a warning about running as administrator, please try running this script from a regular PowerShell window (not 'Run as administrator')." -ForegroundColor Yellow
    try {
        $ErrorActionPreference = 'Stop'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        if (-not (Test-PowerShellVersion)) {
            Write-Unsuccess
            Write-Warning -Message 'PowerShell 5.1 or higher is required to run this script'
            Write-Warning -Message "You are running PowerShell $($PSVersionTable.PSVersion)"
            Write-Host -Object 'PowerShell 5.1 install guide:'
            Write-Host -Object 'https://learn.microsoft.com/skypeforbusiness/set-up-your-computer-for-windows-powershell/download-and-install-windows-powershell-5-1'
            Write-Host -Object 'PowerShell 7 install guide:'
            Write-Host -Object 'https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows'
            Pause
            exit
        }
        else {
            Write-Success
        }
        if (-not (Test-Admin)) {
            Write-Unsuccess
            Write-Warning -Message "The script was run as administrator. This can result in problems with the installation process or unexpected behavior. Do not continue if you do not know what you are doing."
            $Host.UI.RawUI.Flushinputbuffer()
            $choices = @(
                (New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Abort installation.'),
                (New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'Resume installation.')
            )
            $choice = $Host.UI.PromptForChoice('', 'Do you want to abort the installation process?', $choices, 0)
            if ($choice -eq 0) {
                Write-Host -Object 'spicetify installation aborted' -ForegroundColor 'Yellow'
                Pause
                exit
            }
        } else {
            Write-Success
        }

        Move-OldSpicetifyFolder
        Install-Spicetify-CLI
        Write-Host -Object "`nRun" -NoNewline
        Write-Host -Object ' spicetify -h ' -NoNewline -ForegroundColor 'Cyan'
        Write-Host -Object 'to get started'

        $Host.UI.RawUI.Flushinputbuffer()
        $choices = @(
            (New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Install Spicetify Marketplace."),
            (New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not install Spicetify Marketplace.")
        )
        $choice = $Host.UI.PromptForChoice('', "`nDo you also want to install Spicetify Marketplace? It will become available within the Spotify Marketplace, where you can easily install themes and extensions.", $choices, 0)
        if ($choice -eq 1) {
            Write-Host -Object 'spicetify Marketplace installation aborted' -ForegroundColor 'Yellow'
        }
        else {
            Install-Spicetify-Marketplace
        }

        Write-Host "Spicetify CLI and Marketplace installation completed." -ForegroundColor Green
    }
    catch {
        Write-Error "Error occurred during Spicetify CLI and Marketplace installation: $_"
    }
    pause
    Clear-Host
}

function Show-InstallSpicetifyMenu {
    Clear-Host
    while ($true) {
        Write-Host "========= Install Spicetify Menu =========" -ForegroundColor Cyan
        Write-Host "1. Install Spicetify" -ForegroundColor White
        Write-Host "2. Uninstall Spicetify" -ForegroundColor White
        Write-Host "3. Spicetify Fix not working" -ForegroundColor White
        Write-Host "4. Spicetify Update" -ForegroundColor White
        Write-Host "5. Spicetify Restore (Disable Spicetify)" -ForegroundColor White
        Write-Host "6. Spicetify Extensions Menu" -ForegroundColor White
        Write-Host "7. Back to Main Menu" -ForegroundColor White
        Write-Host "=====================================" -ForegroundColor Cyan

        $spicetifyOption = Read-Host "Select an option"

        switch ($spicetifyOption) {
            "1" {
                Show-InstallSpicetifyMenu_Install
            }
            "2" {
                Remove-Spicetify
            }
            "3" {
                Write-Host "Option 3 selected: Spicetify Fix not working..." -ForegroundColor Yellow
                Invoke-SpicetifyApply
            }
            "4" {
                Write-Host "Option 4 selected: Spicetify Update..." -ForegroundColor Yellow
                Invoke-SpicetifyUpdate
            }
            "5" {
                Write-Host "Option 5 selected: Spicetify Restore (Disable Spicetify)..." -ForegroundColor Yellow
                Invoke-SpicetifyRestore
            }
            "6" {
                Show-SpicetifyExtensionsMenu
            }
            "7" {
                Write-Host "Back to Main Menu..." -ForegroundColor Green
                Clear-Host
                return
            }
            default {
                Write-Host "Invalid option. Please select a number from the menu." -ForegroundColor Red
                pause
                Clear-Host
            }
        }
    }
}

function Show-SpicetifyExtensionsMenu {
    Clear-Host
    while ($true) {
        Write-Host "========= Spicetify Extensions Menu =========" -ForegroundColor Cyan
        Write-Host "1. Install LoopyLoop Extension" -ForegroundColor White
        Write-Host "2. Install PopupLyrics Extension" -ForegroundColor White
        Write-Host "3. Install ShufflePlus Extension" -ForegroundColor White
        Write-Host "4. Install lyrics-plus Extension" -ForegroundColor White
        Write-Host "5. Install new-releases Extension" -ForegroundColor White
        Write-Host "6. Install HistoryInSidebar Extension" -ForegroundColor White
        Write-Host "7. Install All Extensions" -ForegroundColor White
        Write-Host "8. Back to Install Spicetify Menu" -ForegroundColor White
        Write-Host "==========================================" -ForegroundColor Cyan

        $extensionsOption = Read-Host "Select an option"

        switch ($extensionsOption) {
            "1" {
                Install-Extension-LoopyLoop
            }
            "2" {
                Install-Extension-PopupLyrics
            }
            "3" {
                Install-Extension-ShufflePlus
            }
            "4" {
                Install-Extension-lyrics-plus
            }
            "5" {
                Install-Extension-new-releases
            }
            "6" {
                Install-Extension-HistoryInSidebar
            }
            "7" {
                Install-AllExtensions
            }
            "8" {
                Write-Host "Back to Install Spicetify Menu..." -ForegroundColor Green
                Clear-Host
                return
            }
            default {
                Write-Host "Invalid option. Please select a number from the menu." -ForegroundColor Red
                pause
                Clear-Host
            }
        }
    }
}

function Show-InstallSpotXMenu_Install {
    Write-Host "Option 1 selected: Install SpotX..." -ForegroundColor Yellow
    Write-Host "Please wait, installing SpotX..." -ForegroundColor Cyan

    try {
        Stop-Spotify

        if ($win10 -or $win11 -or $win8_1 -or $win8 -or $win12) {
            if (Get-AppxPackage -Name SpotifyAB.SpotifyMusic) {
                Write-Host ($lang).MsSpoti`n
                if (-not ($confirm_uninstall_ms_spoti)) {
                    do {
                        $ch = Read-Host -Prompt ($lang).MsSpoti2
                        Write-Host
                        if (-not ($ch -eq 'n' -or $ch -eq 'y')) { incorrectValue }
                    }
                    while ($ch -notmatch '^y$|^n$')
                }
                if ($confirm_uninstall_ms_spoti) { $ch = 'y' }
                if ($ch -eq 'y') {
                    $ProgressPreference = 'SilentlyContinue'
                    if ($confirm_uninstall_ms_spoti) { Write-Host ($lang).MsSpoti3`n }
                    if (-not ($confirm_uninstall_ms_spoti)) { Write-Host ($lang).MsSpoti4`n }
                    Get-AppxPackage -Name SpotifyAB.SpotifyMusic | Remove-AppxPackage
                }
                if ($ch -eq 'n') { Read-Host ($lang).StopScript; Pause; Exit }
            }
        }

        $hostsFilePath = Join-Path $Env:windir 'System32\Drivers\Etc\hosts'
        $hostsBackupFilePath = Join-Path $Env:windir 'System32\Drivers\Etc\hosts.bak'

        if (Test-Path -Path $hostsFilePath) {
            $hosts = [System.IO.File]::ReadAllLines($hostsFilePath)
            $regex = "^(?!#|\|)((?:.*?(?:download|upgrade)\.scdn\.co|.*?spotify).*)"

            if ($hosts -match $regex) {
                Write-Host ($lang).HostInfo`n
                Write-Host ($lang).HostBak`n

                Copy-Item -Path $hostsFilePath -Destination $hostsBackupFilePath -ErrorAction SilentlyContinue

                if ($?) {
                    Write-Host ($lang).HostDel
                    try {
                        $hosts = $hosts | Where-Object { $_ -notmatch $regex }
                        [System.IO.File]::WriteAllLines($hostsFilePath, $hosts)
                    }
                    catch {
                        Write-Host ($lang).HostError`n -ForegroundColor Red
                        $copyError = $Error[0]
                        Write-Host "Error: $($copyError.Exception.Message)`n" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host ($lang).HostError`n -ForegroundColor Red
                    $copyError = $Error[0]
                    Write-Host "Error: $($copyError.Exception.Message)`n" -ForegroundColor Red
                }
            }
        }

        Push-Location -LiteralPath ([System.IO.Path]::GetTempPath())
        New-Item -Type Directory -Name "SpotX_Temp-$(Get-Date -UFormat '%Y-%m-%d_%H-%M-%S')" | Convert-Path | Set-Location

        if ($premium) { Write-Host ($lang).Prem`n }

        $spotifyInstalled = (Test-Path -LiteralPath $spotifyExecutable)

        if ($spotifyInstalled) {
            $offline = (Get-Item $spotifyExecutable).VersionInfo.FileVersion
            $arr1 = $online -split '\.' | ForEach-Object { [int]$_ }
            $arr2 = $offline -split '\.' | ForEach-Object { [int]$_ }

            for ($i = 0; $i -lt $arr1.Length; $i++) {
                if ($arr1[$i] -gt $arr2[$i]) { $oldversion = $true; break }
                elseif ($arr1[$i] -lt $arr2[$i]) { $testversion = $true; break }
            }

            if ($oldversion) {
                if ($confirm_spoti_recomended_over -or $confirm_spoti_recomended_uninstall) { Write-Host ($lang).OldV`n }
                if (-not ($confirm_spoti_recomended_over) -and -not ($confirm_spoti_recomended_uninstall)) {
                    do {
                        Write-Host (($lang).OldV2 -f $offline, $online)
                        $ch = Read-Host -Prompt ($lang).OldV3
                        Write-Host
                        if (-not ($ch -eq 'n' -or $ch -eq 'y')) { incorrectValue }
                    }
                    while ($ch -notmatch '^y$|^n$')
                }
                if ($confirm_spoti_recomended_over -or $confirm_spoti_recomended_uninstall) { $ch = 'y'; Write-Host ($lang).AutoUpd`n }
                if ($ch -eq 'y') {
                    if (-not ($confirm_spoti_recomended_over) -and -not ($confirm_spoti_recomended_uninstall)) {
                        do {
                            $ch = Read-Host -Prompt (($lang).DelOrOver -f $offline)
                            Write-Host
                            if (-not ($ch -eq 'n' -or $ch -eq 'y')) { incorrectValue }
                        }
                        while ($ch -notmatch '^y$|^n$')
                    }
                    if ($confirm_spoti_recomended_uninstall) { $ch = 'y' }
                    if ($confirm_spoti_recomended_over) { $ch = 'n' }
                    if ($ch -eq 'y') {
                        Write-Host ($lang).DelOld`n
                        $null = Unlock-Folder
                        cmd /c $spotifyExecutable /UNINSTALL /SILENT
                        Wait-Process -name SpotifyUninstall
                        Start-Sleep -Milliseconds 200
                        if (Test-Path $spotifyDirectory) { Remove-Item -Recurse -Force -LiteralPath $spotifyDirectory }
                        if (Test-Path $spotifyDirectory2) { Remove-Item -Recurse -Force -LiteralPath $spotifyDirectory2 }
                        if (Test-Path $spotifyUninstall ) { Remove-Item -Recurse -Force -LiteralPath $spotifyUninstall }
                    }
                    if ($ch -eq 'n') { $ch = $null }
                }
            }

            if ($testversion) {
                try {
                    $country = [System.Globalization.RegionInfo]::CurrentRegion.EnglishName
                    $txt = [IO.File]::ReadAllText($spotifyExecutable)
                    $versionRegex = "(?<![\w\-])(\d+)\.(\d+)\.(\d+)\.(\d+)(\.g[0-9a-f]{8})(?![\w\-])"
                    $versionMatches = [regex]::Matches($txt, $versionRegex)
                    $ver = $versionMatches[0].Value

                    $Parameters = @{
                        Uri    = 'https://docs.google.com/forms/d/e/1FAIpQLSegGsAgilgQ8Y36uw-N7zFF6Lh40cXNfyl1ecHPpZcpD8kdHg/formResponse'
                        Method = 'POST'
                        Body   = @{
                            'entry.620327948'  = $ver
                            'entry.1951747592' = $country
                            'entry.1402903593' = $win_os
                            'entry.860691305'  = $psv
                            'entry.2067427976' = $online + " < " + $offline
                        }
                    }
                    $null = Invoke-WebRequest -useb @Parameters
                }
                catch { Write-Host 'Unable to submit new version of Spotify' ; Write-Host "error description: "$Error[0]; Write-Host }

                if ($confirm_spoti_recomended_over -or $confirm_spoti_recomended_uninstall) { Write-Host ($lang).NewV`n }
                if (-not ($confirm_spoti_recomended_over) -and -not ($confirm_spoti_recomended_uninstall)) {
                    do {
                        Write-Host (($lang).NewV2 -f $offline, $online)
                        $ch = Read-Host -Prompt (($lang).NewV3 -f $offline)
                        Write-Host
                        if (-not ($ch -eq 'n' -or $ch -eq 'y')) { incorrectValue }
                    }
                    while ($ch -notmatch '^y$|^n$')
                }
                if ($confirm_spoti_recomended_over -or $confirm_spoti_recomended_uninstall) { $ch = 'n' }
                if ($ch -eq 'y') { }
                if ($ch -eq 'n') {
                    if (-not ($confirm_spoti_recomended_over) -and -not ($confirm_spoti_recomended_uninstall)) {
                        do {
                            $ch = Read-Host -Prompt (($lang).Recom -f $online)
                            Write-Host
                            if (-not ($ch -eq 'n' -or $ch -eq 'y')) { incorrectValue }
                        }
                        while ($ch -notmatch '^y$|^n$')
                    }
                    if ($confirm_spoti_recomended_over -or $confirm_spoti_recomended_uninstall) { $ch = 'y'; Write-Host ($lang).AutoUpd`n }
                    if ($ch -eq 'y') {
                        if (-not ($confirm_spoti_recomended_over) -and -not ($confirm_spoti_recomended_uninstall)) {
                            do {
                                $ch = Read-Host -Prompt (($lang).DelOrOver -f $offline)
                                Write-Host
                                if (-not ($ch -eq 'n' -or $ch -eq 'y')) { incorrectValue }
                            }
                            while ($ch -notmatch '^y$|^n$')
                        }
                        if ($confirm_spoti_recomended_uninstall) { $ch = 'y' }
                        if ($confirm_spoti_recomended_over) { $ch = 'n' }
                        if ($ch -eq 'y') {
                            Write-Host ($lang).DelNew`n
                            $null = Unlock-Folder
                            cmd /c $spotifyExecutable /UNINSTALL /SILENT
                            Wait-Process -name SpotifyUninstall
                            Start-Sleep -Milliseconds 200
                            if (Test-Path $spotifyDirectory) { Remove-Item -Recurse -Force -LiteralPath $spotifyDirectory }
                            if (Test-Path $spotifyDirectory2) { Remove-Item -Recurse -Force -LiteralPath $spotifyDirectory2 }
                            if (Test-Path $spotifyUninstall ) { Remove-Item -Recurse -Force -LiteralPath $spotifyUninstall }
                        }
                        if ($ch -eq 'n') { $ch = $null }
                    }

                    if ($ch -eq 'n') {
                        Write-Host ($lang).StopScript
                        $tempDirectory = $PWD
                        Pop-Location
                        Start-Sleep -Milliseconds 200
                        Remove-Item -Recurse -LiteralPath $tempDirectory
                        Pause
                        Exit
                    }
                }
            }
        }

        if (-not $spotifyInstalled -or $upgrade_client) {
            Write-Host ($lang).DownSpoti "" -NoNewline
            Write-Host  $online -ForegroundColor Green
            Write-Host ($lang).DownSpoti2`n

            $ErrorActionPreference = 'SilentlyContinue'
            Stop-Spotify
            Start-Sleep -Milliseconds 600
            $null = Unlock-Folder
            Start-Sleep -Milliseconds 200
            Get-ChildItem $spotifyDirectory -Exclude 'Users', 'prefs' | Remove-Item -Recurse -Force
            Start-Sleep -Milliseconds 200

            downloadSp
            Write-Host

            Start-Sleep -Milliseconds 200

            Start-Process -FilePath explorer.exe -ArgumentList "$PWD\SpotifySetup.exe" -Wait
            while (-not (Get-Process | Where-Object { $_.ProcessName -eq 'SpotifySetup' })) {
                Start-Sleep -Milliseconds 500
            }
            Wait-Process -name SpotifySetup
            Stop-Spotify

            $offline = (Get-Item $spotifyExecutable).VersionInfo.FileVersion
            $offline_bak = (Get-Item $exe_bak).VersionInfo.FileVersion
        }

        if ($no_shortcut) {
            $ErrorActionPreference = 'SilentlyContinue'
            $desktop_folder = DesktopFolder
            Start-Sleep -Milliseconds 1000
            Remove-Item "$desktop_folder\Spotify.lnk" -Recurse -Force
        }

        $ch = $null

        if ($langCode -eq 'ru' -and [version]$offline -ge [version]"1.1.92.644") {
            $webjsonru = Get-WebData -Url (Get-Link -e "/patches/Augmented%20translation/ru.json")
            if ($null -ne $webjsonru) { $ru = $true }
        }

        if ($podcasts_off) { Write-Host ($lang).PodcatsOff`n ; $ch = 'y' }
        if ($podcasts_on) { Write-Host ($lang).PodcastsOn`n ; $ch = 'n' }
        if (-not ($podcasts_off) -and -not ($podcasts_on)) {
            do {
                $ch = Read-Host -Prompt ($lang).PodcatsSelect
                Write-Host
                if (-not ($ch -eq 'n' -or $ch -eq 'y')) { incorrectValue }
            }
            while ($ch -notmatch '^y$|^n$')
        }
        if ($ch -eq 'y') { $podcast_off = $true }

        $ch = $null

        if ($downgrading) { $upd = "`n" + [string]($lang).DowngradeNote }
        else { $upd = "" }

        if ($block_update_on) { Write-Host ($lang).UpdBlock`n ; $ch = 'y' }
        if ($block_update_off) { Write-Host ($lang).UpdUnblock`n ; $ch = 'n' }
        if (-not ($block_update_on) -and -not ($block_update_off)) {
            do {
                $text_upd = [string]($lang).UpdSelect + $upd
                $ch = Read-Host -Prompt $text_upd
                Write-Host
                if (-not ($ch -eq 'n' -or $ch -eq 'y')) { incorrectValue }
            }
            while ($ch -notmatch '^y$|^n$')
        }
        if ($ch -eq 'y') { $not_block_update = $false }

        if (-not $new_theme -and [version]$offline -ge [version]"1.2.14.1141") {
            Write-Warning "This version does not support the old theme, use version 1.2.13.661 or below"
            Write-Host
        }

        if ($ch -eq 'n') {
            $not_block_update = $true
            $ErrorActionPreference = 'SilentlyContinue'
            if ((Test-Path -LiteralPath $exe_bak) -and $offline -eq $offline_bak) {
                Remove-Item $spotifyExecutable -Recurse -Force
                Rename-Item $exe_bak $spotifyExecutable
            }
        }

        $ch = $null

        $webjson = Get-WebData -Url (Get-Link -e "/patches/patches.json") -RetrySeconds 5

        if ($null -eq $webjson) {
            Write-Host; Write-Host "Failed to get patches.json" -ForegroundColor Red; Write-Host ($lang).StopScript
            $tempDirectory = $PWD; Pop-Location; Start-Sleep -Milliseconds 200; Remove-Item -Recurse -LiteralPath $tempDirectory
            Pause; exit
        }

        Write-Host ($lang).ModSpoti`n

        $tempDirectory = $PWD; Pop-Location; Start-Sleep -Milliseconds 200; Remove-Item -Recurse -LiteralPath $tempDirectory

        $xpui_spa_patch = Join-Path (Join-Path $env:APPDATA 'Spotify\Apps') 'xpui.spa'
        $xpui_js_patch = Join-Path (Join-Path (Join-Path $env:APPDATA 'Spotify\Apps') 'xpui') 'xpui.js'
        $test_spa = Test-Path -Path $xpui_spa_patch
        $test_js = Test-Path -Path $xpui_js_patch
        $spotify_exe_bak_patch = Join-Path $env:APPDATA 'Spotify\Spotify.bak'

        if ($test_spa -and $test_js) {
            Write-Host ($lang).Error -ForegroundColor Red; Write-Host ($lang).FileLocBroken; Write-Host ($lang).StopScript; pause; exit
        }

        if ($test_js) {
            do {
                $ch = Read-Host -Prompt ($lang).Spicetify
                Write-Host
                if (-not ($ch -eq 'n' -or $ch -eq 'y')) { incorrectValue }
            }
            while ($ch -notmatch '^y$|^n$')

            if ($ch -eq 'y') { Start-Process "https://telegra.ph/SpotX-FAQ-09-19#Can-I-use-SpotX-and-Spicetify-together?" }

            Write-Host ($lang).StopScript; Pause; exit
        }

        if (-not $test_js -and -not $test_spa) {
            Write-Host "xpui.spa not found, reinstall Spotify"; Write-Host ($lang).StopScript; Pause; exit
        }

        If ($test_spa) {
            $bak_spa = Join-Path (Join-Path $env:APPDATA 'Spotify\Apps') 'xpui.bak'
            $test_bak_spa = Test-Path -Path $bak_spa

            Add-Type -Assembly 'System.IO.Compression.FileSystem'
            $zip = [System.IO.Compression.ZipFile]::Open($xpui_spa_patch, 'update')
            $entry = $zip.GetEntry('xpui.js')
            $reader = New-Object System.IO.StreamReader($entry.Open())
            $patched_by_spotx = $reader.ReadToEnd()
            $reader.Close()

            If ($patched_by_spotx -match 'patched by spotx') {
                $zip.Dispose()

                if ($test_bak_spa) {
                    Remove-Item $xpui_spa_patch -Recurse -Force
                    Rename-Item $bak_spa $xpui_spa_patch

                    $spotify_exe_bak_patch = Join-Path $env:APPDATA 'Spotify\Spotify.bak'
                    $test_spotify_exe_bak = Test-Path -Path $spotify_exe_bak_patch
                    if ($test_spotify_exe_bak) {
                        Remove-Item $spotifyExecutable -Recurse -Force
                        Rename-Item $spotify_exe_bak_patch $spotifyExecutable
                    }
                }
                else { Write-Host ($lang).NoRestore`n; Pause; exit }
                $spotify_exe_bak_patch = Join-Path $env:APPDATA 'Spotify\Spotify.bak'
                $test_spotify_exe_bak = Test-Path -Path $spotify_exe_bak_patch
                if ($test_spotify_exe_bak) {
                    Remove-Item $spotifyExecutable -Recurse -Force
                    Rename-Item $spotify_exe_bak_patch $spotifyExecutable
                }
            }
            $zip.Dispose()
            Copy-Item $xpui_spa_patch $env:APPDATA\Spotify\Apps\xpui.bak

            if ($ru) {
                $null = [Reflection.Assembly]::LoadWithPartialName('System.IO.Compression')
                $stream = New-Object IO.FileStream($xpui_spa_patch, [IO.FileMode]::Open)
                $mode = [IO.Compression.ZipArchiveMode]::Update
                $zip_xpui = New-Object IO.Compression.ZipArchive($stream, $mode)

                ($zip_xpui.Entries | Where-Object { $_.FullName -match "i18n" -and $_.FullName -inotmatch "(ru|en.json|longest)" }) | ForEach-Object { $_.Delete() }

                $zip_xpui.Dispose()
                $stream.Close()
                $stream.Dispose()
            }

            if (-not $premium) {
                extract -counts 'one' -method 'zip' -name 'xpui.js' -helper 'OffadsonFullscreen'
            }

            extract -counts 'one' -method 'zip' -name 'xpui.js' -helper 'ForcedExp' -add $webjson.others.byspotx.add

            if ($podcast_off -or $adsections_off) {
                $section = Get-WebData -Url (Get-Link -e "/js-helper/sectionBlock.js")
                if ($null -ne $section) { injection -p $xpui_spa_patch -f "spotx-helper" -n "sectionBlock.js" -c $section }
                else { $podcast_off, $adsections_off = $false }
            }

            if ($urlform_goofy -and $idbox_goofy) {
                $goofy = Get-WebData -Url (Get-Link -e "/js-helper/goofyHistory.js")
                if ($null -ne $goofy) { injection -p $xpui_spa_patch -f "spotx-helper" -n "goofyHistory.js" -c $goofy }
            }

            if ($lyrics_stat) {
                $rulesContent = Get-WebData -Url (Get-Link -e "/css-helper/lyrics-color/rules.css")
                $colorsContent = Get-WebData -Url (Get-Link -e "/css-helper/lyrics-color/colors.css")

                $colorsContent = $colorsContent -replace '{{past}}', "$($webjson.others.themelyrics.theme.$lyrics_stat.pasttext)"
                $colorsContent = $colorsContent -replace '{{current}}', "$($webjson.others.themelyrics.theme.$lyrics_stat.current)"
                $colorsContent = $colorsContent -replace '{{next}}', "$($webjson.others.themelyrics.theme.$lyrics_stat.next)"
                $colorsContent = $colorsContent -replace '{{hover}}', "$($webjson.others.themelyrics.theme.$lyrics_stat.hover)"
                $colorsContent = $colorsContent -replace '{{background}}', "$($webjson.others.themelyrics.theme.$lyrics_stat.background)"
                $colorsContent = $colorsContent -replace '{{musixmatch}}', "$($webjson.others.themelyrics.theme.$lyrics_stat.maxmatch)"

                injection -p $xpui_spa_patch -f "spotx-helper/lyrics-color" -n @("rules.css", "colors.css") -c @($rulesContent, $colorsContent) -i "rules.css"
            }
            extract -counts 'one' -method 'zip' -name 'xpui.js' -helper 'VariousofXpui-js'

            if ($devtools -and [version]$offline -ge [version]"1.2.35.663") {
                extract -counts 'one' -method 'zip' -name 'xpui-routes-desktop-settings.js' -helper 'Dev'
            }

            if (-not $hide_col_icon_off -and -not $exp_spotify) {
                extract -counts 'one' -method 'zip' -name 'xpui-routes-playlist.js' -helper 'Collaborators'
            }

            extract -counts 'one' -method 'zip' -name 'xpui-desktop-modals.js' -helper 'Discriptions'

            if ( [version]$offline -le [version]"1.2.56.502" ) { $fileName = 'vendor~xpui.js' }
            else { $fileName = 'xpui.js' }

            extract -counts 'one' -method 'zip' -name $fileName -helper 'DisableSentry'

            extract -counts 'more' -name '*.js' -helper 'MinJs'

            if (-not $premium) {
                if ([version]$offline -ge [version]"1.2.30.1135") { $css += $webjson.others.downloadquality.add }
                $css += $webjson.others.downloadicon.add
                $css += $webjson.others.submenudownload.add
                if ([version]$offline -le [version]"1.2.29.605") { $css += $webjson.others.veryhighstream.add }
            }
            if ($global:type -eq "all" -or $global:type -eq "podcast") {
                $css += $webjson.others.block_subfeeds.add
            }

            if ($null -ne $css ) { extract -counts 'one' -method 'zip' -name 'xpui.css' -add $css }

            extract -counts 'one' -method 'zip' -name 'xpui.css' -helper "FixCss"

            extract -counts 'more' -name '*.css' -helper 'Cssmin'

            extract -counts 'one' -method 'zip' -name 'licenses.html' -helper 'HtmlLicMin'
            extract -counts 'one' -method 'zip' -name 'blank.html' -helper 'HtmlBlank'

            if ($ru) {
                extract -counts 'more' -name '*ru.json' -helper 'RuTranslate'
            }
            extract -counts 'more' -name '*.json' -helper 'MinJson'
        }

        if ($ru) {
            $patch_lang = "$spotifyDirectory\locales"
            Remove-Item $patch_lang -Exclude *en*, *ru* -Recurse
        }

        $ErrorActionPreference = 'SilentlyContinue'

        if (-not $no_shortcut) {
            $desktop_folder = DesktopFolder

            If (-not (Test-Path $desktop_folder\Spotify.lnk)) {
                $source = Join-Path $env:APPDATA 'Spotify\Spotify.exe'
                $target = "$desktop_folder\Spotify.lnk"
                $WorkingDir = "$env:APPDATA\Spotify"
                $WshShell = New-Object -comObject WScript.Shell
                $Shortcut = $WshShell.CreateShortcut($target)
                $Shortcut.WorkingDirectory = $WorkingDir
                $Shortcut.TargetPath = $source
                $Shortcut.Save()
            }
        }

        If (-not (Test-Path $start_menu)) {
            $source = Join-Path $env:APPDATA 'Spotify\Spotify.exe'
            $target = $start_menu
            $WorkingDir = "$env:APPDATA\Spotify"
            $WshShell = New-Object -comObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($target)
            $Shortcut.WorkingDirectory = $WorkingDir
            $Shortcut.TargetPath = $source
            $Shortcut.Save()
        }

        $ANSI = [Text.Encoding]::GetEncoding(1251)
        $old = [IO.File]::ReadAllText($spotifyExecutable, $ANSI)

        $regex1 = -not ($old -match $webjson.others.binary.block_update.add)
        $regex2 = -not ($old -match $webjson.others.binary.block_slots.add)
        $regex3 = -not ($old -match $webjson.others.binary.block_slots_2.add)
        $regex4 = -not ($old -match $webjson.others.binary.block_slots_3.add)
        $regex5 = -not ($old -match $webjson.others.binary.block_gabo.add)

        if ($regex1 -and $regex2 -and $regex3 -and $regex4 -and $regex5) {
            if (Test-Path -LiteralPath $exe_bak) {
                Remove-Item $exe_bak -Recurse -Force
                Start-Sleep -Milliseconds 150
            }
            Copy-Item $spotifyExecutable $exe_bak
        }

        extract -counts 'exe' -helper 'Binary'

        if ([version]$offline -ge [version]"1.1.87.612" -and [version]$offline -le [version]"1.2.5.1006") {
            $login_spa = Join-Path (Join-Path $env:APPDATA 'Spotify\Apps') 'login.spa'
            Get-WebData -Url (Get-Link -e "/res/login.spa") -OutputPath $login_spa
        }

        if ($DisableStartup) {
            $prefsPath = "$env:APPDATA\Spotify\prefs"
            $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            $keyName = "Spotify"

            if (Get-ItemProperty -Path $keyPath -Name $keyName -ErrorAction SilentlyContinue) {
                Remove-ItemProperty -Path $keyPath -Name $keyName -Force
            }

            if (-not (Test-Path $prefsPath)) {
                $content = @"
app.autostart-configured=true
app.autostart-mode="off"
"@
                [System.IO.File]::WriteAllLines($prefsPath, $content, [System.Text.UTF8Encoding]::new($false))
            }
            else {
                $content = [System.IO.File]::ReadAllText($prefsPath)
                if (-not $content.EndsWith("`n")) {
                    $content += "`n"
                }
                $content += 'app.autostart-mode="off"'
                [System.IO.File]::WriteAllText($prefsPath, $content, [System.Text.UTF8Encoding]::new($false))
            }
        }
        Write-Host ($lang).InstallComplete`n -ForegroundColor Green
    }
    catch {
        Write-Error "Error occurred during SpotX installation: $_"
    }
    pause
    Clear-Host
}

function Show-InstallSpotXMenu_Uninstall {
    Write-Host "Option 2 selected: Uninstall SpotX..." -ForegroundColor Yellow
    Write-Host "Restoring Spotify to original state..." -ForegroundColor Cyan
    try {
        Restore-SpotX
        Write-Host "SpotX uninstallation completed." -ForegroundColor Green
    }
    catch {
        Write-Error "Error occurred during SpotX uninstallation: $_"
    }
    pause
    Clear-Host
}

function Show-InstallSpotXMenu {
    Clear-Host
    while ($true) {
        Write-Host "========= Install SpotX Menu =========" -ForegroundColor Cyan
        Write-Host "1. Install SpotX" -ForegroundColor White
        Write-Host "2. Uninstall SpotX" -ForegroundColor White
        Write-Host "3. Back to Main Menu" -ForegroundColor White
        Write-Host "=====================================" -ForegroundColor Cyan

        $spotXOption = Read-Host "Select an option"

        switch ($spotXOption) {
            "1" {
                Show-InstallSpotXMenu_Install
            }
            "2" {
                Uninstall-SpotX-Fn
            }
            "3" {
                Write-Host "Back to Main Menu..." -ForegroundColor Green
                Clear-Host
                return
            }
            default {
                Write-Host "Invalid option. Please select a number from the menu." -ForegroundColor Red
                pause
                Clear-Host
            }
        }
    }
}

function Show-MainMenu {
    Clear-Host

    while ($true) {
        Write-Host "================= Main Menu =================" -ForegroundColor Cyan
        Write-Host "1. Spotify" -ForegroundColor White
        Write-Host "2. Spicetify" -ForegroundColor White
        Write-Host "3. SpotX" -ForegroundColor White
        Write-Host "4. Exit the Code" -ForegroundColor White
        Write-Host "==========================================" -ForegroundColor Cyan

        $option = Read-Host "Select an option"

        switch ($option) {
            "1" {
                Show-InstallSpotifyMenu
            }

            "2" {
                Show-InstallSpicetifyMenu
            }
            "3" {
                Show-InstallSpotXMenu
            }
            "4" {
                Write-Host "Exiting script..." -ForegroundColor Green
                exit
            }
            default {
                Write-Host "Invalid option. Please select a number from the menu." -ForegroundColor Red
                pause
                Clear-Host
            }
        }
    }
}

$PSDefaultParameterValues['Stop-Process:ErrorAction'] = [System.Management.Automation.ActionPreference]::SilentlyContinue

$spotifyDirectory = Join-Path $env:APPDATA 'Spotify'
$spotifyDirectory2 = Join-Path $env:LOCALAPPDATA 'Spotify'
$spotifyExecutable = Join-Path $spotifyDirectory 'Spotify.exe'
$exe_bak = Join-Path $spotifyDirectory 'Spotify.bak'
$spotifyUninstall = Join-Path ([System.IO.Path]::GetTempPath()) 'SpotifyUninstall.exe'
$start_menu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Spotify.lnk'

$upgrade_client = $false
$mirror = $false
$onlineFull = "1.2.57.463.g4f748c64-3096"
$online = ($onlineFull -split ".g")[0]
$langCode = 'en'
$lang = CallLang -clg 'en'

$os = Get-CimInstance -ClassName "Win32_OperatingSystem" -ErrorAction SilentlyContinue
if ($os) {
    $osCaption = $os.Caption
}
else {
    $osCaption = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
}
$pattern = "\bWindows (7|8(\.1)?|10|11|12)\b"
$reg = [regex]::Matches($osCaption, $pattern)
$win_os = $reg.Value

$win12 = $win_os -match "\windows 12\b"
$win11 = $win_os -match "\windows 11\b"
$win10 = $win_os -match "\windows 10\b"
$win8_1 = $win_os -match "\windows 8.1\b"
$win8 = $win_os -match "\windows 8\b"

$devtools = $false
$podcasts_off = $true
$adsections_off = $true
$podcasts_on = $false
$block_update_on = $true
$block_update_off = $false
$cache_limit = $null
$confirm_uninstall_ms_spoti = $false
$confirm_spoti_recomended_over = $false
$confirm_spoti_recomended_uninstall = $false
$premium = $false
$DisableStartup = $false
$exp_spotify = $false
$topsearchbar = $false
$homesub_off = $false
$hide_col_icon_off = $false
$rightsidebar_off = $false
$plus = $false
$canvasHome = $false
$funnyprogressbar = $false
$new_theme = $false
$rightsidebarcolor = $false
$old_lyrics = $false
$lyrics_block = $true
$no_shortcut = $false
$lyrics_stat = $null
$urlform_goofy = $null
$idbox_goofy = $null
$err_ru = $false
$not_block_update = -not ($block_update_on)
$podcast_off = $podcasts_off

$webjson = $null
$webjsonru = $null
$offline = ""
$offline_bak = ""
$downgrading = $false
$ru = $false
$css = $null
$global:type = ""

Show-MainMenu