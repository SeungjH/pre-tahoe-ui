# Pre-Tahoe UI

A small macOS utility that restores a centered volume and brightness indicator. It replaces the macOS Tahoe indicators when Accessibility access is granted.

## Features

- Classic volume, mute, and brightness artwork with a segmented level bar.
- Smooth brightness changes using macOS DisplayServices.
- A stationary indicator while switching desktops.
- Separate display duration controls for volume and brightness.
- Background operation without a menu bar icon. Open the app again to show settings or quit.

## Build and run

Requires macOS Tahoe or later and a Swift toolchain. On a Mac with Xcode Command Line Tools:

```sh
./build-local.sh
open "build/Pre-Tahoe UI.app"
```

The build script creates a locally signed app. Move it to `/Applications` if you want to keep it there. After launching, enable **Pre-Tahoe UI** in **System Settings → Privacy & Security → Accessibility** so it can handle the volume and brightness keys and suppress the system indicator. Open the app again to adjust settings. The built-in Quit button stops the background process.

The included `Resources/Assets.car` and `Resources/volumeHUD.icns` are compiled assets from the MIT-licensed upstream project. They let the command-line build work without Xcode's asset catalog compiler. The Xcode project is also included.

## Compatibility

The stationary overlay and smooth brightness adjustment use private macOS APIs. A future macOS update may require changes. Brightness control is intended for built-in displays. The app uses the bundle identifier `local.classicvolumehud` to retain settings and Accessibility access from earlier local builds.

## Credits and license

Pre-Tahoe UI is maintained by Brian Han and based on [volumeHUD by Danny Stewart](https://github.com/dannystewart/volumeHUD) version 3.3.4. The original and this modified source are distributed under the [MIT License](LICENSE). See [CUSTOM_FORK.md](CUSTOM_FORK.md) for the changes in this version.
