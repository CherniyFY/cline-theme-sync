#!/usr/bin/env bash
# Install the wrapper and the desktop entry that shadows the system Cline entry.
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
bin_dir="$HOME/.local/bin"
app_dir="$HOME/.local/share/applications"
target="$bin_dir/cline-theme-sync"

mkdir -p "$bin_dir" "$app_dir"
ln -sfn "$repo/cline-theme-sync" "$target"
# Must match the system entry's filename exactly (/usr/share/applications/Cline.desktop);
# KDE keeps "Cline.desktop" and "cline.desktop" as two separate entries.
python3 - "$repo/cline.desktop" "$target" "$app_dir/Cline.desktop" <<'PY'
import sys
from pathlib import Path

template, target, desktop = sys.argv[1:]
if any(char in target for char in "=%") or any(ord(char) < 32 for char in target):
    raise SystemExit("desktop launcher path cannot contain '=', '%', or control characters")
# Desktop Exec quoting is decoded after the desktop file's string escapes.
# Double each quoting backslash for the outer string layer.
argument = '"' + "".join("\\" + char if char in '\\"`$' else char
                         for char in target) + '"'
value = argument.replace("\\", "\\\\")
Path(desktop).write_text(Path(template).read_text().replace("@EXEC@", value))
PY
rm -f "$app_dir/cline.desktop"

# KDE caches desktop entries; refresh so the launcher picks up the override.
kbuildsycoca6 --noincremental >/dev/null 2>&1 || true

echo "installed: $target"
echo "installed: $app_dir/Cline.desktop"
