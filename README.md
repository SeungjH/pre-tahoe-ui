# Pre-Tahoe UI

<p align="center"><img src="volumeHUD.icon/Assets/volumeHUD.png" alt="Pre-Tahoe UI sequoia forest app icon" width="160"></p>

A small macOS utility that restores a centered volume and brightness indicator. It replaces the macOS Tahoe indicators when Accessibility access is granted.

## Features

- Classic volume and brightness indicators: three volume waves at any nonzero level, a crossed speaker at zero, and three sun-ray lengths for brightness, above a segmented bar.
- Smooth brightness changes using macOS DisplayServices.
- A stationary indicator while switching desktops.
- Separate display duration controls for volume and brightness.
- Background operation without a menu bar icon. Open the app again to show settings or quit.

## Install

Requires macOS Tahoe or later and Xcode Command Line Tools (`xcode-select --install`). Copy and paste this into Terminal:

```sh
git clone https://github.com/SeungjH/pre-tahoe-ui.git && cd pre-tahoe-ui && ./install.sh
```

Clone URL: `https://github.com/SeungjH/pre-tahoe-ui.git`

The installer builds the app locally, copies it to `/Applications/Pre-Tahoe UI.app`, and opens it. If an older copy is installed there, it is updated. If macOS prompts for permission, enable **Pre-Tahoe UI** in **System Settings → Privacy & Security → Device Control and Data Access** so it can handle the volume and brightness keys and suppress the system indicator. Open the app again to adjust settings. The built-in Quit button stops the background process.

To build without installing, run `./build-local.sh`; the app is placed in `build/Pre-Tahoe UI.app`.

The included `Resources/Assets.car` contains MIT-licensed upstream sound and icon assets, while `Resources/volumeHUD.icns` is this fork's app icon. These let the command-line build work without Xcode's asset catalog compiler. The Xcode project is also included.

## If both indicators appear

An app update can invalidate macOS's permission for a locally signed build. In **System Settings → Privacy & Security → Device Control and Data Access**, remove the old **Pre-Tahoe UI** entry, add `/Applications/Pre-Tahoe UI.app` again, then quit and reopen the app.

## Compatibility

The stationary overlay and smooth brightness adjustment use private macOS APIs. A future macOS update may require changes. Brightness control is intended for built-in displays. The app uses the bundle identifier `local.classicvolumehud` to retain settings and Accessibility access from earlier local builds.

## Credits and license

Pre-Tahoe UI is maintained by Brian Han and based on [volumeHUD by Danny Stewart](https://github.com/dannystewart/volumeHUD) version 3.3.4. The original and this modified source are distributed under the [MIT License](LICENSE). See [CUSTOM_FORK.md](CUSTOM_FORK.md) for the changes in this version.
