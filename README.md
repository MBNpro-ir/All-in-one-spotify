![image](https://github.com/user-attachments/assets/93f86527-4f5b-47ea-bb09-d0b34e92de13)# Spotify - Spicetify Installer

This project is a PowerShell script for automatically installing Spotify and Spicetify along with some useful extensions.

![image](https://github.com/user-attachments/assets/fbfc98b3-ce17-4d66-a3e2-956dabd2a226)

## Features

- Automatic installation of Spotify
- Installation of Spicetify CLI
- Configuration of Spicetify extensions

## Requirements
- PowerShell 5.0 or higher
- Internet access to download the software

## How to Use

1. Download the `install_spotify.ps1` file.
2. Right-click the `install_spotify.ps1` file and select Run with PowerShell. (Be sure its NOT running as administrator.)
3. Select your desired options from the displayed menu.
4. download the `Spotify marketplace configs.json` file and import it to Marketplace Settings after you install Spicetify. This file includes premium features that can be only enable on premium account.

## How to Use On Windows 11?

In windows 11 there is an issue in PowerShell that occurs when script execution is restricted due to the system's execution policy. By default, Windows applies an execution policy that prevents untrusted scripts from running to protect system security. The error message typically looks like this:

```
File C:\path\to\script.ps1 cannot be loaded because running scripts is disabled on this system.
```

### Why does this happen?
This happens because of the **Execution Policy** settings in PowerShell. The execution policy determines what kinds of scripts can run and under what conditions. Common execution policy modes are:

1. **Restricted** (default): No scripts are allowed to run.
2. **AllSigned**: Only scripts with a valid digital signature can run.
3. **RemoteSigned**: Local scripts run without a signature, but scripts downloaded from the internet require a signature.
4. **Unrestricted**: All scripts are allowed to run, but you'll get a warning for those downloaded from the internet.
5. **Bypass**: No restrictions; everything can run.

### How to resolve the issue?
To change the execution policy, you can use the **Set-ExecutionPolicy** command. Follow these steps:

1. Open PowerShell **as Administrator**.
2. Run one of the following commands based on your needs:

   - USE THIS LINE !!!! - To allow all scripts (not secure, recommended only for testing or personal use):
     ```powershell
     Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
     ```

   - To allow safer scripts:
     ```powershell
     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
     ```

3. If prompted for confirmation, type `A` and If prompted for Install.all.in.one.ps1, type `R`.

### Check the current policy
To see the current **Execution Policy** settings, use this command:
```powershell
Get-ExecutionPolicy -List
```

## Spotify.marketplace.configs.json
1.![image](https://github.com/user-attachments/assets/9c39695e-692c-49b0-98a2-f5d5f8490e71)
2.![image](https://github.com/user-attachments/assets/f4a5a889-d4a6-4791-85ca-98614fc121eb)
3.![image](https://github.com/user-attachments/assets/264dff88-0521-4668-ab74-38d3df23e4be)
4.![image](https://github.com/user-attachments/assets/332589ad-ecd6-4940-9479-48de9e3481e9)
5.![image](https://github.com/user-attachments/assets/c1483ed3-2a28-4dee-8938-7236ffad2cbb)

### Security Tips
- Always use **RemoteSigned** or **AllSigned** policies unless you're in a testing environment.
- If you set the policy to **Unrestricted**, remember to revert it to a safer policy after completing your work.

## Problems :
If spotify shows a black screen, on the taskbar right click on spotify and on the Troubleshooting section click reload.(This is spicetify bug)

![image](https://github.com/user-attachments/assets/6c5ebff9-1d70-4ecc-a68c-277e72fa89bb)
