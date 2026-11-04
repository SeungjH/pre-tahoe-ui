#!/bin/zsh
set -euo pipefail

source_dir=${0:A:h}
app_name='Pre-Tahoe UI.app'
install_path="/Applications/$app_name"
build_dir=$(mktemp -d "${TMPDIR:-/tmp/}pre-tahoe-ui.XXXXXXXX")
trap 'rm -rf "$build_dir"' EXIT

"$source_dir/build-local.sh" "$build_dir/$app_name"

# Stop only this app before replacing it. Other volumeHUD installations are untouched.
pkill -f '^/Applications/Pre-Tahoe UI[.]app/Contents/MacOS/volumeHUD$' 2>/dev/null || true

if [[ -w /Applications ]]; then
    ditto "$build_dir/$app_name" "$install_path"
else
    sudo ditto "$build_dir/$app_name" "$install_path"
fi

codesign --verify --deep --strict "$install_path"
open "$install_path"
print "Installed and opened $install_path"
print 'Enable Pre-Tahoe UI in System Settings > Privacy & Security > Accessibility if prompted.'
