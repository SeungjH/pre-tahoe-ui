//
//  HUDView.swift
//  by Danny Stewart (2025)
//  MIT License
//  https://github.com/dannystewart/volumeHUD
//

import AppKit
import SwiftUI

// MARK: - HUDType

enum HUDType {
    case volume
    case brightness
}

// MARK: - HUDView

struct HUDView: View {
    let hudType: HUDType
    let value: Float
    let isMuted: Bool

    private let hudSize: CGFloat = 200
    private let iconColor = Color.white.opacity(0.72)

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let icon = NSImage(contentsOfFile: "/System/Library/CoreServices/OSDUIHelper.app/Contents/Resources/\(iconName).pdf") {
                Image(nsImage: icon)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(iconColor)
                    .frame(width: 170, height: 170)
                    .offset(x: 15, y: 15)
            } else {
                Image(systemName: hudType == .brightness ? "sun.max" : (iconName == "Mute" ? "speaker.slash.fill" : "speaker.wave.3.fill"))
                    .font(.system(size: 80))
                    .foregroundStyle(iconColor)
                    .frame(width: 170, height: 170)
                    .offset(x: 15, y: 15)
            }
            HStack(spacing: 1) {
                ForEach(0 ..< 16, id: \.self) { index in
                    barView(for: index)
                }
            }
            .frame(width: 160, height: 8, alignment: .leading)
            .background(.black.opacity(0.86))
            .offset(x: 20, y: 171)
        }
        .frame(width: hudSize, height: hudSize, alignment: .topLeading)
        .background {
            HUDMaterial()
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).fill(.black.opacity(0.18)))
        }
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    private var iconName: String {
        switch hudType {
        case .volume: isMuted || value <= 0.001 ? "Mute" : "Volume"
        case .brightness: "Brightness"
        }
    }

    @ViewBuilder
    private func barView(for index: Int) -> some View {
        let barWidth: CGFloat = 9
        let barHeight: CGFloat = 6.5

        if hudType == .volume, isMuted || value <= 0.001 {
            // Show all bars dimmed when muted
            Color.clear.frame(width: barWidth, height: barHeight)
        } else {
            // Each of the 16 bars represents 1/16th of the total range. Support 1/64th increments
            // by filling each bar horizontally in quarters.
            let barStart = Float(index) / 16.0
            let barEnd = Float(index + 1) / 16.0

            if value >= barEnd {
                // Fully filled bar
                Rectangle()
                    .fill(.white.opacity(0.72))
                    .frame(width: barWidth, height: barHeight)
            } else if value > barStart {
                // Partially filled bar - calculate fill percentage
                let positionInBar = (value - barStart) / (barEnd - barStart)

                // Quantize to 1/4 steps (0.25, 0.5, 0.75)
                let quarterStep = round(positionInBar * 4.0) / 4.0
                let fillWidth = barWidth * CGFloat(quarterStep)

                // Show partial fill with overlay
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.white.opacity(0.72))
                        .frame(width: fillWidth, height: barHeight)
                }
                .frame(width: barWidth, height: barHeight)
            } else {
                // Empty bar
                Color.clear.frame(width: barWidth, height: barHeight)
            }
        }
    }
}

private struct HUDMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.appearance = NSAppearance(named: .vibrantDark)
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

#if !NO_PREVIEWS
#Preview("Volume") {
    ZStack {
        Color.black.frame(width: 360, height: 380).ignoresSafeArea()
        HUDView(hudType: .volume, value: 0.7, isMuted: false)
    }
}

#Preview("Mute") {
    ZStack {
        Color.black.frame(width: 360, height: 380).ignoresSafeArea()
        HUDView(hudType: .volume, value: 0.0, isMuted: true)
    }
}

#Preview("Brightness") {
    ZStack {
        Color.black.frame(width: 360, height: 380).ignoresSafeArea()
        HUDView(hudType: .brightness, value: 0.5, isMuted: false)
    }
}
#endif
