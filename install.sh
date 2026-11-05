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
for attempt in {1..30}; do
    pgrep -f '^/Applications/Pre-Tahoe UI[.]app/Contents/MacOS/volumeHUD$' >/dev/null || break
    sleep 0.1
done

if [[ -w /Applications ]]; then
    ditto "$build_dir/$app_name" "$install_path"
else
    sudo ditto "$build_dir/$app_name" "$install_path"
fi

codesign --verify --deep --strict "$install_path"
if ! open "$install_path"; then
    sleep 1
    open "$install_path"
fi
print "Installed and opened $install_path"
print 'If macOS still shows its own indicator, open System Settings > Privacy & Security > Device Control and Data Access.'
print 'Remove any older Pre-Tahoe UI entry, then add /Applications/Pre-Tahoe UI.app and enable it.'
