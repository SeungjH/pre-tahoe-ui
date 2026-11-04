# Pre-Tahoe UI

Based on Danny Stewart's volumeHUD 3.3.4 (MIT license).

Changes:

- Dark blurred 200 × 200 HUD using the system's original Volume, Mute, and Brightness PDF icons.
- The volume icon shows one, two, or three waves and stays centered as its width changes. At zero or mute, the waves vanish and a slash crosses the speaker. The brightness icon grows its rays across three levels. Content updates without replacing the HUD window.
- HUD centered horizontally, 140 points above the bottom of the selected screen.
- Immediate appearance, 0.7 seconds at full opacity after the last key input, then a 0.22 second ease-out fade.
- The icon-free settings window has separate display-time sliders for volume and brightness indicators. Reopen the app to adjust them; changes apply on the next key input.
- The app icon depicts a sequoia forest in cobalt blue and warm orange tones, based on the supplied color reference.
- The volume display option now makes clear that it selects the display containing the pointer.
- A continuous dark meter track with narrow separators between white segments.
- Places the HUD in a separate SkyLight application space so it stays fixed during desktop switching; falls back to the standard overlay if the private API is unavailable.
- Runs as an accessory app without a menu bar icon. Reopen the app to access settings and Quit.
- Brightness polling runs twice per second; intercepted brightness keys update the HUD immediately.
- Brightness keys use the system's smooth DisplayServices brightness ramp; the classic HUD shows the target step immediately.
- Removed the obsolete position toggle and upstream release notification.
- Separate bundle ID: `local.classicvolumehud`.

Run `./install.sh` to build, install to `/Applications`, and launch the app.
Alternatively, build with Xcode using `volumeHUD.xcodeproj`, or run
`./build-local.sh "build/Pre-Tahoe UI.app"`. The command-line build includes
the upstream app's compiled MIT-licensed icon and sound assets because Command
Line Tools do not include `actool`.

Quit the upstream volumeHUD before launching this fork. The apps intentionally
refuse to run together. Grant this fork Accessibility access in System Settings
to intercept the volume keys and hide the system HUD. The fork's bundle ID is
separate, so it cannot inherit the original app's permission.
The SkyLight API is private and may need adjustment after a macOS update.
