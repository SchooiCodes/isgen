# ISG — Info Stealer Generator

ISG is a Windows batch payload builder. Give it a Discord webhook URL and it bakes that URL into a bundled template, obfuscates the result, and writes out `SCleaner.bat` — a script that gathers data from a machine and sends it back to that webhook. It is intended for authorized red-team exercises, malware analysis and education.

> [!WARNING]
> **Educational / authorized-testing use only.**
> Running the generated payload against a system you do not own, or do not have explicit written permission to test, is illegal in most jurisdictions. You are responsible for how you use this tool. The author accepts no liability for misuse or damage.

## Quick start

```bat
generator.bat
```

Paste your Discord webhook URL when prompted. The finished payload is written to:

```
%USERPROFILE%\Downloads\SCleaner.bat
```

For scripted builds, pass the webhook as an argument to skip the prompt and the final pause:

```bat
generator.bat "https://discord.com/api/webhooks/..."
```

## What it collects

| Category | Details |
| --- | --- |
| Identity | `%USERNAME%`, `%COMPUTERNAME%`, local IP, public IP (`api.ipify.org`) |
| System | `ver`, `systeminfo`, `fastfetch`, Windows product key, `tasklist`, `netstat -an` |
| Filesystem | Directory listings of the working directory, `C:\Program Files`, Documents and Desktop |
| Network | `ipconfig`, all Wi-Fi profiles exported with `key=clear` (SSIDs + cleartext keys) |
| Screen | Desktop screenshot (PNG) |
| Credentials | Saved browser passwords (WebBrowserPassView), Discord tokens |
| Log | Timestamped `%TEMP%\SCleaner.log` documenting every stage |

Results are sent as separate webhook messages (connection summary, screenshot, `info.zip`, `passwords.zip`, log) to keep each one small.

## Requirements

- Windows 10 or 11 (`ver` must report 10 or newer).
- PowerShell 5.1+ and `certutil.exe` (used by the bundled `obfuscator.bat`).
- `curl.exe` (Windows 10 1803+) and a working internet connection.
- Administrative rights unlock the full feature set; the payload degrades gracefully without them.
- Being a `.bat` file means `cmd.exe` policy, AppLocker/WDAC rules and antivirus heuristics all apply.

The generator resolves `code_template.txt` and `obfuscator.bat` relative to its own directory, so keep those files next to `generator.bat`.

## Legal

This project is provided for education, malware analysis and authorized red-team exercises. Do not use it to access systems or data you do not own. Depending on your jurisdiction, possession or use of this tool may itself be an offence. The author accepts no liability for misuse or damage.
