#!/bin/zsh
set -e

source_dir=${0:A:h}
app_path=${1:-"${source_dir}/build/Pre-Tahoe UI.app"}
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
swiftc -O -swift-version 6 -D NO_PREVIEWS \
  -framework AppKit -framework SwiftUI -framework Combine \
  -framework CoreGraphics -framework IOKit -framework UserNotifications \
  "$source_dir"/volumeHUD/*.swift -o "$app_path/Contents/MacOS/volumeHUD"
cp "$source_dir/Resources/Info.plist" "$app_path/Contents/Info.plist"
cp "$source_dir/Resources/Assets.car" "$app_path/Contents/Resources/Assets.car"
cp "$source_dir/Resources/volumeHUD.icns" "$app_path/Contents/Resources/volumeHUD.icns"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier local.classicvolumehud' "$app_path/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName Pre-Tahoe UI' "$app_path/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleName Pre-Tahoe UI' "$app_path/Contents/Info.plist"
codesign --force --deep --sign - "$app_path"
codesign --verify --deep --strict "$app_path"
print "$app_path"
