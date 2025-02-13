This project is a PowerShell script for automatically installing and managing Spotify, Spicetify, and SpotX, along with useful Spicetify extensions.

![image](https://github.com/user-attachments/assets/94ae2e8d-f789-43bf-8067-85ac1184322e)

## Version 2.0.0 - What's New?

Version 2.0.0 brings significant enhancements and a major new feature: **SpotX Integration!**  This update offers a more organized and user-friendly experience for managing your Spotify setup.

Here's a summary of the key improvements:

*   **SpotX Integration:**  Install and manage SpotX directly from the script menu. Enjoy ad-blocking and enhanced Spotify features with ease.
*   **Modular Menu Structure:**  A redesigned main menu and submenus for Spotify, Spicetify, and SpotX provide a clearer and more intuitive navigation experience.
*   **Dedicated Spicetify Functions:**  New menu options for `Spicetify Apply`, `Spicetify Restore`, and `Spicetify Update` streamline Spicetify management.
*   **Spicetify Extensions Menu:**  A dedicated menu to easily install popular Spicetify extensions like LoopyLoop, PopupLyrics, and more.
*   **Improved Code Organization:** The script is now more modular and easier to maintain, ensuring better stability and future updates.
*   **General Enhancements:**  Various code improvements and bug fixes for a smoother installation and management process.

## Features

- **Spotify Management:**
    - Automatic installation of Spotify.
    - Uninstallation of Spotify.
- **Spicetify CLI Management:**
    - Installation of Spicetify CLI and Marketplace.
    - Uninstallation of Spicetify.
    - Spicetify "Fix not working" option (Apply configuration).
    - Spicetify Update.
    - Spicetify Restore (Disable Spicetify).
    - Spicetify Extensions Menu for easy extension installation.
- **SpotX Integration:**
    - Installation of SpotX for ad-blocking and client enhancements.
    - Uninstallation of SpotX (Restore Spotify to original state).
- **Spicetify Extensions:**
    - Easy installation of popular Spicetify extensions: LoopyLoop, PopupLyrics, ShufflePlus, lyrics-plus, new-releases, HistoryInSidebar, and option to Install All Extensions.

## Requirements

- PowerShell 5.1 or higher
- Internet access to download the software
- Spotify Desktop application (for Spicetify and SpotX features)

## How to Use

1. Download the `Install.all.in.one.ps1` file from the [Releases](https://github.com/MBNpro-ir/All-in-one-spotify/releases) page.
(OR you can download Install.all.in.one.bat double click and install it)
2. Right-click the `Install.all.in.one.ps1` file and select **Run with PowerShell**. (Be sure it's **NOT** running as administrator unless prompted).
3. A Main Menu will appear in the PowerShell window. Select your desired options by entering the corresponding number and pressing Enter.
4. Follow the on-screen prompts to install Spotify, Spicetify, SpotX, or manage Spicetify extensions.
5. For Spicetify Marketplace themes and configurations, you can explore online resources and import them to Marketplace Settings after installing Spicetify.

## Main Menu Options:

*   **1. Spotify:**  Opens the "Install Spotify Menu" allowing you to Install or Uninstall Spotify.
*   **2. Spicetify:** Opens the "Install Spicetify Menu" for installing, uninstalling, fixing, updating, restoring Spicetify, and managing Spicetify Extensions.
*   **3. SpotX:** Opens the "Install SpotX Menu" to Install or Uninstall SpotX.
*   **4. Exit the Code:** Closes the script.

## How to Use On Windows 11 (PowerShell Execution Policy)

In Windows 11, you might encounter an issue in PowerShell where script execution is restricted due to the system's execution policy. By default, Windows applies an execution policy that prevents untrusted scripts from running to protect system security. The error message typically looks like this:

File C:\path\to\script.ps1 cannot be loaded because running scripts is disabled on this system.

### Why does this happen?

This happens because of the **Execution Policy** settings in PowerShell. The execution policy determines what kinds of scripts can run and under what conditions. Common execution policy modes are:

1.  **Restricted** (default): No scripts are allowed to run.
2.  **AllSigned**: Only scripts with a valid digital signature can run.
3.  **RemoteSigned**: Local scripts run without a signature, but scripts downloaded from the internet require a signature.
4.  **Unrestricted**: All scripts are allowed to run, but you'll get a warning for those downloaded from the internet.
5.  **Bypass**: No restrictions; everything can run.

### How to resolve the issue?

To change the execution policy, you can use the **Set-ExecutionPolicy** command. Follow these steps:

1.  Open PowerShell **as Administrator**.
2.  Run one of the following commands based on your needs:

    -   **USE THIS LINE !!!!** - To allow all scripts (less secure, recommended only for testing or personal use):
        ```powershell
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
        ```

    -   To allow safer scripts (recommended for general use):
        ```powershell
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
        ```

3.  If prompted for confirmation, type `A` and press Enter.

### Check the current policy

To see the current **Execution Policy** settings, use this command in PowerShell:

```powershell
Get-ExecutionPolicy -List
```

### Spotify Marketplace Configurations

While this script does not directly include Spotify.marketplace.configs.json, you can enhance your Spicetify Marketplace experience by importing configuration files. Here are general steps and example images (the Spotify.marketplace.configs.json file itself needs to be sourced from Spicetify community resources):

![alt text](https://github.com/user-attachments/assets/9c39695e-692c-49b0-98a2-f5d5f8490e71)

![alt text](https://github.com/user-attachments/assets/f4a5a889-d4a6-4791-85ca-98614fc121eb)

![alt text](https://github.com/user-attachments/assets/264dff88-0521-4668-ab74-38d3df23e4be)

![alt text](https://github.com/user-attachments/assets/332589ad-ecd6-4940-9479-48de9e3481e9)

![alt text](https://github.com/user-attachments/assets/c1483ed3-2a28-4dee-8938-7236ffad2cbb)

(Note: You will need to find and download a Spotify.marketplace.configs.json file separately from Spicetify community forums or theme/extension repositories if you wish to use pre-made configurations.)

### Security Tips

Always use RemoteSigned or AllSigned policies for general security unless you are intentionally testing or running scripts from trusted sources.

If you temporarily set the policy to Unrestricted, remember to revert it back to a safer policy like RemoteSigned after you have finished using the script.
