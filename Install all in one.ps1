function Show-Error {
    param ([string]$message)
    Write-Host "Error: $message" -ForegroundColor Red
}

function Show-Status {
    param ([string]$message)
    Write-Host "Status: $message" -ForegroundColor Green
}

function Test-SpotifyInstallation {
    param ([string]$path)
    return Test-Path $path
}

function Test-SpicetifyInstallation {
    param ([string]$path)
    return Test-Path $path
}

function Test-ProcessRunning {
    param ([string]$name)
    $process = Get-Process -Name $name -ErrorAction SilentlyContinue
    return $null -ne $process
}

function Test-InstallerIntegrity {
    param ([string]$path)
    try {
        $fileInfo = Get-Item $path
        return $fileInfo.Length -gt 0
    } catch {
        return $false
    }
}

function Install-Spotify {
    $spotifyPath = "$env:APPDATA\Spotify"
    $installerPath = "$env:TEMP\SpotifyFullSetup.exe"
    $spotifyInstallerUrl = "http://download.spotify.com/SpotifyFullSetup.exe"

    try {
        if (-Not (Test-SpotifyInstallation $spotifyPath)) {
            if (-Not (Test-Path $installerPath) -or -Not (Test-InstallerIntegrity $installerPath)) {
                Show-Status "Downloading Spotify installer..."
                Invoke-WebRequest -Uri $spotifyInstallerUrl -OutFile $installerPath -ErrorAction Stop -TimeoutSec 300
            } else {
                Show-Status "Spotify installer found and is valid. Skipping download."
            }

            Show-Status "Starting Spotify installation..."
            Start-Process -FilePath $installerPath -ArgumentList "/silent" -NoNewWindow

            $attempt = 0
            $maxAttempts = 27
            do {
                Start-Sleep -Seconds 27
                $attempt++
                if ($attempt -ge $maxAttempts) {
                    Show-Error "Spotify failed to launch within the expected time."
                    return
                }
            } until (Test-ProcessRunning "Spotify")

            Stop-Process -Name "Spotify" -Force -ErrorAction SilentlyContinue
            Show-Status "Spotify process terminated."

            if (Test-SpotifyInstallation $spotifyPath) {
                Show-Status "Spotify installed successfully."
            } else {
                Show-Error "Spotify installation did not complete successfully."
            }
        } else {
            Show-Status "Spotify is already installed."
        }
    } catch {
        Show-Error "Failed to download or install Spotify. Please check your internet connection."
    }
}

function Install-Spicetify {
    $spicetifyPath = "$env:LOCALAPPDATA\spicetify"

    try {
        if (-Not (Test-SpicetifyInstallation $spicetifyPath)) {
            Show-Status "Downloading and installing Spicetify CLI..."
            Invoke-WebRequest -Uri https://raw.githubusercontent.com/spicetify/cli/main/install.ps1 -UseBasicParsing | Invoke-Expression
			Show-Status "Fixing known BUGS!!."
			spicetify config sidebar_config 0
			spicetify apply
            Show-Status "Spicetify CLI installed."
        } else {
            Show-Status "Spicetify CLI is already installed."
        }
    } catch {
        Show-Error "Failed to download or install Spicetify CLI."
    }
}

function Uninstall-Spotify {
    try {
        $spotifyPath = "$env:APPDATA\Spotify"
        if (Test-Path $spotifyPath) {
            Stop-Process -Name "Spotify" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $spotifyPath -Recurse -Force -ErrorAction Stop
            Show-Status "Spotify uninstalled successfully."
        } else {
            Show-Error "Spotify is not installed."
        }
    } catch {
        Show-Error "Failed to uninstall Spotify."
    }
}

function Uninstall-Spicetify {
    try {
        spicetify restore
        Remove-Item -Path "$env:APPDATA\spicetify" -Recurse -Force -ErrorAction Stop
        Remove-Item -Path "$env:LOCALAPPDATA\spicetify" -Recurse -Force -ErrorAction Stop
        Show-Status "Spicetify and its data uninstalled successfully."
    } catch {
        Show-Error "Failed to uninstall Spicetify."
    }
}

function Uninstall-Extension {
    param ([string]$extensionName)
    try {
        spicetify config extensions $extensionName-
        Show-Status "$extensionName extension uninstalled successfully."
    } catch {
        Show-Error "Failed to uninstall $extensionName extension."
    }
}

function Install-Extension-LoopyLoop {
    try {
        spicetify config extensions loopyLoop.js
        Show-Status "LoopyLoop extension configured."
    } catch {
        Show-Error "Failed to configure LoopyLoop extension."
    }
}

function Install-Extension-PopupLyrics {
    try {
        spicetify config extensions popupLyrics.js
        Show-Status "PopupLyrics extension configured."
    } catch {
        Show-Error "Failed to configure PopupLyrics extension."
    }
}

function Install-Extension-ShufflePlus {
    try {
        spicetify config extensions shuffle+.js
        Show-Status "ShufflePlus extension configured."
    } catch {
        Show-Error "Failed to configure ShufflePlus extension."
    }
}

function Install-Extension-lyrics-plus {
    try {
        spicetify config custom_apps lyrics-plus
        Show-Status "lyrics-plus extension configured."
    } catch {
        Show-Error "Failed to configure lyrics-plus extension."
    }
}

function Install-Extension-new-releases {
    try {
        spicetify config custom_apps new-releases
        Show-Status "new-releases extension configured."
    } catch {
        Show-Error "Failed to configure new-releases extension."
    }
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

        spicetify config custom_apps history-in-sidebar
        Show-Status "HistoryInSidebar extension configured."
    } catch {
        Show-Error "Failed to download or configure HistoryInSidebar extension."
    }
}

function Install-AllExtensions {
    Show-Status "Installing all extensions..."

    Install-Extension-LoopyLoop
    Install-Extension-PopupLyrics
    Install-Extension-ShufflePlus
    Install-Extension-lyrics-plus
    Install-Extension-new-releases
    Install-Extension-HistoryInSidebar

    spicetify apply
    Show-Status "All extensions installed and configurations applied."
}

function Spicetify-Apply {
    try {
        spicetify apply
		spicetify backup apply
        Show-Status "spicetify apply configured."
    } catch {
        Show-Error "Failed to configure spicetify apply."
    }
}

function Spicetify-Restore {
    try {
        spicetify restore
        Show-Status "spicetify restore configured."
    } catch {
        Show-Error "Failed to configure spicetify restore."
    }
}

function Spicetify-Update {
    try {
        spicetify restore backup apply
        Show-Status "spicetify update configured."
    } catch {
        Show-Error "Failed to configure spicetify update."
    }
}

function Show-ExtensionsMenu {
    do {
        Write-Host "======= Extensions Menu ======="
        Write-Host "1. Install LoopyLoop Extension"
        Write-Host "2. Install PopupLyrics Extension"
        Write-Host "3. Install ShufflePlus Extension"
        Write-Host "4. Install lyrics-plus Extension"
        Write-Host "5. Install new-releases Extension"
        Write-Host "6. Install HistoryInSidebar Extension"
        Write-Host "7. Install All Extensions"
        Write-Host "8. Return to Main Menu"
        Write-Host "================================"
        
        $choice = Read-Host "Select an option"

        switch ($choice) {
            "1" { Install-Extension-LoopyLoop }
            "2" { Install-Extension-PopupLyrics }
            "3" { Install-Extension-ShufflePlus }
            "4" { Install-Extension-lyrics-plus }
            "5" { Install-Extension-new-releases }
            "6" { Install-Extension-HistoryInSidebar }
            "7" { Install-AllExtensions }
            "8" { return }
            default { Write-Host "Invalid selection, please try again." -ForegroundColor Yellow }
        }
    } while ($true)
}

function Show-UninstallMenu {
    do {
        Write-Host "======= Uninstall Menu ======="
        Write-Host "1. Uninstall Spotify"
        Write-Host "2. Uninstall Spicetify"
        Write-Host "3. Uninstall Extension"
        Write-Host "4. Return to Main Menu"
        Write-Host "=============================="
        
        $choice = Read-Host "Select an option"

        switch ($choice) {
            "1" { Uninstall-Spotify }
            "2" { Uninstall-Spicetify }
            "3" {
                Write-Host "Select the extension to uninstall:"
                Write-Host "1. LoopyLoop"
                Write-Host "2. PopupLyrics"       
                Write-Host "3. ShufflePlus"
                Write-Host "4. lyrics-plus"
                Write-Host "5. new-releases"
                Write-Host "6. HistoryInSidebar"
                Write-Host "7. Return to Uninstall Menu"

                $extChoice = Read-Host "Select an extension to uninstall"
                switch ($extChoice) {
                    "1" { Uninstall-Extension "loopyLoop.js" }
                    "2" { Uninstall-Extension "popupLyrics.js" }
                    "3" { Uninstall-Extension "shuffle+.js" }
                    "4" { Uninstall-Extension "lyrics-plus" }
                    "5" { Uninstall-Extension "new-releases" }
                    "6" { Uninstall-Extension "history-in-sidebar" }
                    "7" { continue }
                    default { Write-Host "Invalid selection, please try again." -ForegroundColor Yellow }
                }
            }
            "4" { return }
            default { Write-Host "Invalid selection, please try again." -ForegroundColor Yellow }
        }
    } while ($true)
}

function Show-MainMenu {
    do {
        Write-Host "======= Main Menu ======="
        Write-Host "1. Install Spotify"
        Write-Host "2. Install Spicetify CLI"
        Write-Host "3. Extensions Menu"
        Write-Host "4. Spicetify Apply ( Apply after installing extentions )"
        Write-Host "5. Spicetify Restore ( disable Spicetify )"
        Write-Host "6. Spicetify Update ( after spotify updates )"		
        Write-Host "7. Uninstall Menu"
        Write-Host "8. Exit"
        Write-Host "========================="

        $choice = Read-Host "Select an option"

        switch ($choice) {
            "1" { Install-Spotify }
            "2" { Install-Spicetify }
            "3" { Show-ExtensionsMenu }
            "4" { Spicetify-Apply }
            "5" { Spicetify-Restore }
            "6" { Spicetify-Update }			
            "7" { Show-UninstallMenu }
            "8" { exit }
            default { Write-Host "Invalid selection, please try again." -ForegroundColor Yellow }
        }
    } while ($true)
}

# Start the main menu
Show-MainMenu
