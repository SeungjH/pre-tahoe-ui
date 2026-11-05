//
//  AboutView.swift
//  Based on volumeHUD by Danny Stewart (MIT License)
//

import SwiftUI

struct AboutView: View {
    @Environment(\.loginItemManager) private var loginItemManager
    @AppStorage("volumeHUDFollowsMouse") private var volumeHUDFollowsMouse = true
    @AppStorage("hudHoldSeconds") private var volumeHoldSeconds = 0.7
    @AppStorage("barSegmentOpacity") private var barSegmentOpacity = 0.72
    @AppStorage("barBackgroundOpacity") private var barBackgroundOpacity = 0.86
    #if !SANDBOX
        @AppStorage("brightnessEnabled") private var brightnessEnabled = false
        @AppStorage("brightnessHUDHoldSeconds") private var brightnessHoldSeconds = 0.7
    #endif

    let onQuit: () -> Void
    weak var appDelegate: AppDelegate?

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Pre-Tahoe UI"
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text(appName)
                    .font(.system(size: 22, weight: .semibold))
                Text("Volume and brightness indicators")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("General")

                if let loginItemManager {
                    LoginItemSetting(loginItemManager: loginItemManager)
                }

                #if !SANDBOX
                    HStack {
                        Text("Brightness indicator")
                        Spacer()
                        Toggle("Brightness indicator", isOn: $brightnessEnabled)
                            .labelsHidden()
                    }
                    .onChange(of: brightnessEnabled) { _, enabled in
                        if enabled {
                            appDelegate?.startBrightnessMonitoringIfEnabled()
                        } else {
                            appDelegate?.brightnessMonitor?.stopMonitoring()
                        }
                    }
                #endif

                HStack {
                    Text("Volume indicator on pointer's display")
                    Spacer()
                    Toggle("Volume indicator on pointer's display", isOn: $volumeHUDFollowsMouse)
                        .labelsHidden()
                        .help("Off: show on the primary display")
                }
            }
            .font(.system(size: 13))
            .toggleStyle(.switch)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Display time")
                Text("Time before the indicator fades")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                DurationSetting(title: "Volume", duration: $volumeHoldSeconds)
                #if !SANDBOX
                    DurationSetting(title: "Brightness", duration: $brightnessHoldSeconds)
                #endif
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Level bar opacity")
                OpacitySetting(title: "Small bars", opacity: $barSegmentOpacity)
                OpacitySetting(title: "Black background", opacity: $barBackgroundOpacity)
            }

            Spacer(minLength: 0)

            HStack {
                Text("Brian Han  ·  Version \(version)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Quit", action: onQuit)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 560, height: 550)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(.secondary)
    }
}

private struct DurationSetting: View {
    let title: String
    @Binding var duration: Double

    var body: some View {
        HStack(spacing: 14) {
            Text(title)
                .frame(width: 78, alignment: .leading)
            Slider(value: Binding(
                get: { duration },
                set: { duration = ($0 * 10).rounded() / 10 },
            ), in: 0.2 ... 2.0)
                .accessibilityLabel("\(title) indicator display time")
            Text(duration.formatted(.number.precision(.fractionLength(1))) + " s")
                .monospacedDigit()
                .frame(width: 42, alignment: .trailing)
        }
        .font(.system(size: 12))
    }
}

private struct OpacitySetting: View {
    let title: String
    @Binding var opacity: Double

    var body: some View {
        HStack(spacing: 14) {
            Text(title)
                .frame(width: 110, alignment: .leading)
            Slider(value: Binding(
                get: { opacity },
                set: { opacity = ($0 * 100).rounded() / 100 },
            ), in: 0 ... 1)
                .accessibilityLabel("\(title) opacity")
            Text("\(Int((opacity * 100).rounded()))%")
                .monospacedDigit()
                .frame(width: 42, alignment: .trailing)
        }
        .font(.system(size: 12))
    }
}

private struct LoginItemSetting: View {
    @ObservedObject var loginItemManager: LoginItemManager

    var body: some View {
        HStack {
            Text("Open at login")
            Spacer()
            Toggle("Open at login", isOn: Binding(
                get: { loginItemManager.isEnabled },
                set: { loginItemManager.setEnabled($0) },
            ))
            .labelsHidden()
        }
    }
}

#if !NO_PREVIEWS
    #Preview {
        AboutView(onQuit: {}, appDelegate: nil)
            .environment(\.loginItemManager, LoginItemManager())
    }
#endif
