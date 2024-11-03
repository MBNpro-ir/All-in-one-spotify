function Show-Error {
    param (
        [string]$message
    )
    Write-Host "Error: $message" -ForegroundColor Red
}

function Show-Status {
    param (
        [string]$message
    )
    Write-Host "Status: $message" -ForegroundColor Green
}

function Test-SpotifyInstallation {
    param (
        [string]$path
    )
    return Test-Path $path
}

function Test-SpicetifyInstallation {
    param (
        [string]$path
    )
    return Test-Path $path
}

function Test-ProcessRunning {
    param (
        [string]$name
    )
    $process = Get-Process -Name $name -ErrorAction SilentlyContinue
    return $null -ne $process
}

function Test-InstallerIntegrity {
    param (
        [string]$path
    )
    try {
        $fileInfo = Get-Item $path
        return $fileInfo.Length -gt 0
    } catch {
        return $false
    }
}

function Cleanup-Downloads {
    $installerPath = "$env:TEMP\SpotifyFullSetup.exe"
    $extensionsDir = "$env:APPDATA\spicetify\Extensions"
    $tempFiles = Get-ChildItem -Path "$env:TEMP" -File -Recurse

    if ($tempFiles.Count -gt 0) {
        Remove-Item $tempFiles -Force
        Show-Status "All temporary files cleaned up."
    } else {
        Show-Status "No temporary files to clean up."
    }

    if (Test-Path $installerPath) {
        Remove-Item $installerPath -Force
        Show-Status "Spotify installer cleaned up."
    }
    if (Test-Path $extensionsDir) {
        Remove-Item $extensionsDir\* -Force
        Show-Status "Extensions cleaned up."
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
            $maxAttempts = 15
            do {
                Start-Sleep -Seconds 5
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
            Show-Status "Spicetify CLI installed."
        } else {
            Show-Status "Spicetify CLI is already installed."
        }
    } catch {
        Show-Error "Failed to download or install Spicetify CLI."
    }
}
function Install-Extension {
    param (
        [string]$extensionUrl,
        [string]$extensionName
    )
    try {
        $extensionsDir = "$env:APPDATA\spicetify\Extensions"

        if (-Not (Test-Path $extensionsDir)) {
            New-Item -ItemType Directory -Path $extensionsDir -Force | Out-Null
        }

        Invoke-WebRequest -Uri $extensionUrl -OutFile "$extensionsDir\$extensionName" -ErrorAction Stop
        Show-Status "$extensionName configured."

        spicetify apply
        spicetify backup apply
        Show-Status "Spicetify configurations applied after installing $extensionName."
    } catch {
        Show-Error "Failed to download or configure $extensionName."
    }
}

function Apply-SpicetifyConfigs {
    if (Test-SpicetifyInstallation "$env:LOCALAPPDATA\spicetify") {
        spicetify apply
        spicetify backup apply
        Show-Status "Spicetify configurations applied."
    } else {
        Show-Error "Spicetify is not installed. Please install it first."
    }
}

function Execute-All {
    Install-Spotify
    Install-Spicetify
    Install-Extension -extensionUrl "https://raw.githubusercontent.com/Bergbok/Spicetify-Creations/refs/heads/dist/auto-skip-tracks-by-duration/auto-skip-tracks-by-duration.js" -extensionName "auto-skip-tracks-by-duration.js"
    Install-Extension -extensionUrl "https://codeload.github.com/Bergbok/Spicetify-Creations/zip/refs/heads/dist/history-in-sidebar" -extensionName "history-in-sidebar.zip"
    Apply-SpicetifyConfigs
    Show-Status "All installation and configuration steps completed."
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

function Remove-SpicetifyExtension {
    param (
        [string]$extensionName
    )
    try {
        spicetify config extensions $extensionName-
        Show-Status "Extension $extensionName removed from Spicetify."
    } catch {
        Show-Error "Failed to remove extension $extensionName."
    }
}

function Show-UninstallMenu {
    do {
        Write-Host "======= Uninstall Menu ======="
        Write-Host "1. Uninstall Spotify"
        Write-Host "2. Uninstall Spicetify"
        Write-Host "3. Remove auto-skip-tracks-by-duration Extension"
        Write-Host "4. Remove history-in-sidebar Extension"
        Write-Host "5. Return to Main Menu"
        Write-Host "============================="
        
        $choice = Read-Host "Select an option"

        switch ($choice) {
            "1" { Uninstall-Spotify }
            "2" { Uninstall-Spicetify }
            "3" { Remove-SpicetifyExtension -extensionName "auto-skip-tracks-by-duration.js" }
            "4" { Remove-SpicetifyExtension -extensionName "history-in-sidebar.zip" }
            "5" { return }
            default { Write-Host "Invalid selection, please try again." -ForegroundColor Yellow }
        }
    } while ($true)
}
function Show-Menu {
    do {
        Write-Host "========================="
        Write-Host "1. Install Spotify"
        Write-Host "2. Install Spicetify"
        Write-Host "3. Install auto-skip-tracks-by-duration Extension"
        Write-Host "4. Install history-in-sidebar Extension"
        Write-Host "5. Spicetify Apply Configs"
        Write-Host "6. Execute All Steps"
        Write-Host "7. Cleanup Downloads"
        Write-Host "8. Uninstall Menu"
        Write-Host "9. Exit"
        Write-Host "========================="
        
        $choice = Read-Host "Select an option"

        switch ($choice) {
            "1" { Install-Spotify }
            "2" { Install-Spicetify }
            "3" { Install-Extension -extensionUrl "https://raw.githubusercontent.com/Bergbok/Spicetify-Creations/refs/heads/dist/auto-skip-tracks-by-duration/auto-skip-tracks-by-duration.js" -extensionName "auto-skip-tracks-by-duration.js" }
            "4" { Install-Extension -extensionUrl "https://codeload.github.com/Bergbok/Spicetify-Creations/zip/refs/heads/dist/history-in-sidebar" -extensionName "history-in-sidebar.zip" }
            "5" { Apply-SpicetifyConfigs }
            "6" { Execute-All }
            "7" { Cleanup-Downloads }
            "8" { Show-UninstallMenu }
            "9" { exit }
            default { Write-Host "Invalid selection, please try again." -ForegroundColor Yellow }
        }
    } while ($true)
}

Show-Menu
