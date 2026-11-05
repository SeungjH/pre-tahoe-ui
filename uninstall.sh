#!/bin/zsh
set -euo pipefail

install_path='/Applications/Pre-Tahoe UI.app'
plist_path="$install_path/Contents/Info.plist"
executable_path="$install_path/Contents/MacOS/volumeHUD"

if [[ ! -e "$install_path" ]]; then
    print 'Pre-Tahoe UI is not installed in /Applications.'
    exit 0
fi

if [[ -L "$install_path" || ! -d "$install_path" ]]; then
    print -u2 "Refusing to remove an unexpected path: $install_path"
    exit 1
fi

bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist_path" 2>/dev/null || true)
executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist_path" 2>/dev/null || true)
uninstall_supported=$(/usr/libexec/PlistBuddy -c 'Print :PreTahoeUIUninstallSupported' "$plist_path" 2>/dev/null || true)
if [[ "$bundle_id" != 'local.classicvolumehud' || "$executable" != 'volumeHUD' ]]; then
    print -u2 "Refusing to remove an app that is not Pre-Tahoe UI: $install_path"
    exit 1
fi
if [[ "$uninstall_supported" != true ]]; then
    print -u2 'This installed copy predates automatic login-item removal. Run ./install.sh to update it, then rerun ./uninstall.sh.'
    exit 1
fi

pkill -f '^/Applications/Pre-Tahoe UI[.]app/Contents/MacOS/volumeHUD$' 2>/dev/null || true
for attempt in {1..30}; do
    pgrep -f '^/Applications/Pre-Tahoe UI[.]app/Contents/MacOS/volumeHUD$' >/dev/null || break
    sleep 0.1
done
if pgrep -f '^/Applications/Pre-Tahoe UI[.]app/Contents/MacOS/volumeHUD$' >/dev/null; then
    print -u2 'Pre-Tahoe UI is still running. Quit it and try again.'
    exit 1
fi

"$executable_path" --unregister-login-item

if [[ -w /Applications ]]; then
    rm -rf "$install_path"
else
    sudo rm -rf "$install_path"
fi

print 'Removed Pre-Tahoe UI and its login item.'
print 'You can also remove its old permission entry in System Settings > Privacy & Security > Device Control and Data Access.'
