# cline-theme-sync

Make Cline Desktop follow the KDE (Plasma) light/dark color scheme on Linux.

## Problem

Cline Desktop 0.0.49 (`/usr/bin/cline-app`, Tauri + WebKitGTK) has no
"follow system" appearance option. It reads its theme once from
`localStorage["cline-hub-theme"]` (`"light"` or `"dark"`) at startup, and
otherwise falls back to dark. Anything else — including a `"system"` string —
is ignored.

Observed with Cline Desktop 0.0.49 on KDE Plasma with Breeze:

| setup | system scheme | rendered UI |
| --- | --- | --- |
| no stored key | BreezeLight | dark (no system follow) |
| no stored key | BreezeDark | dark |
| stored `light` | BreezeDark | light |
| stored `dark` | BreezeLight | dark |

WebKit's `prefers-color-scheme` does follow the KDE scheme at webview start
(`matchMedia('(prefers-color-scheme: dark)').matches` is `true` on BreezeDark,
`false` on BreezeLight), but emits no change event when the scheme is switched
at runtime. The app also has no listener for it in this version; upstream
`main` adds `watchSystemHubTheme`, which is not in 0.0.49.

## What this does

`cline-theme-sync` derives the theme from `~/.config/kdeglobals`
(`[Colors:Window] BackgroundNormal` luminance) and writes it into Cline's
localStorage before launching the app:

```
~/.local/share/bot.cline.app/localstorage/tauri_localhost_0.localstorage
  table ItemTable, key cline-hub-theme, value UTF-16LE "light" | "dark"
```

`Cline.desktop` shadows `/usr/share/applications/Cline.desktop`, so starting
Cline from the launcher (or the dock, via `StartupWMClass`) runs the wrapper.
The filename must match the system entry exactly — KDE treats `Cline.desktop`
and `cline.desktop` as two separate launcher entries, so a lowercase name does
not shadow anything and the system entry still starts `cline-app` directly.

## Requirements

- Linux with KDE Plasma 6 and Cline Desktop installed as `/usr/bin/cline-app`
- Python 3.10 or newer, Bash, and SQLite support in Python

## Install

```sh
./install.sh
```

Installs:

- `~/.local/bin/cline-theme-sync` → symlink to this repo's script
- `~/.local/share/applications/Cline.desktop` → generated with an absolute `Exec=`

Then restart Cline once.

## Limits

- **Not live.** The app re-reads the theme only at startup, so switching the
  Plasma scheme mid-session needs a Cline restart. Every launch re-syncs.
- The in-app Light/Dark toggle no longer sticks: the wrapper overwrites the
  stored value on each launch.
- Launching `cline-app` directly from a terminal bypasses the wrapper.
- On a first-ever launch (no localStorage file yet) the app keeps its own
  default; the next launch is synced.

## Manual sync / debug

```sh
cline-theme-sync --sync-only    # write the theme, print it, do not launch
```

## Uninstall

```sh
rm -f ~/.local/bin/cline-theme-sync ~/.local/share/applications/Cline.desktop
kbuildsycoca6 --noincremental
```

## License

MIT. See [LICENSE](LICENSE).
