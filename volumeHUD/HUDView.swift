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
            if hudType == .brightness {
                brightnessIcon
                    .offset(x: 15, y: 15)
            } else if let icon = NSImage(contentsOfFile: "/System/Library/CoreServices/OSDUIHelper.app/Contents/Resources/Volume.pdf") {
                ZStack(alignment: .topLeading) {
                    Image(nsImage: icon)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(iconColor)
                        .frame(width: 170, height: 170)
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: silent ? 73 : [0, 100, 117, 170][iconStage])
                        }
                    if silent {
                        Canvas { context, _ in
                            var slash = Path()
                            slash.move(to: CGPoint(x: 29, y: 50))
                            slash.addLine(to: CGPoint(x: 91, y: 90))
                            context.stroke(slash, with: .color(iconColor), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        }
                        .frame(width: 170, height: 170)
                    }
                }
                .frame(width: 170, height: 170)
                .offset(x: 15 + volumeCenterOffset, y: 15)
            } else {
                Image(systemName: silent ? "speaker.slash.fill" : "speaker.wave.\(iconStage).fill")
                    .font(.system(size: 80))
                    .foregroundStyle(iconColor)
                    .frame(width: 170, height: 170)
                    .offset(x: 15 + volumeCenterOffset, y: 15)
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

    private var silent: Bool { isMuted || value <= 0.001 }

    // The system PDF has a fixed 170-point canvas. Center the visible speaker + waves,
    // whose bounds shrink from x=35...135 to x=35...97 as waves disappear.
    private var volumeCenterOffset: CGFloat {
        silent ? 25 : [0, 19, 9.5, 0][iconStage]
    }

    private var iconStage: Int {
        if value <= 1.0 / 3.0 { return 1 }
        if value <= 2.0 / 3.0 { return 2 }
        return 3
    }

    private var brightnessIcon: some View {
        Canvas { context, _ in
            let center = CGPoint(x: 84.5, y: 71.5)
            let ring = Path(ellipseIn: CGRect(x: 63.5, y: 50.5, width: 42, height: 42))
            context.stroke(ring, with: .color(iconColor), lineWidth: 6)

            let rayEnd: CGFloat = [0, 39, 49, 53][iconStage]
            for index in 0 ..< 8 {
                let angle = Double(index) * .pi / 4
                let direction = CGPoint(x: cos(angle), y: sin(angle))
                var ray = Path()
                ray.move(to: CGPoint(x: center.x + direction.x * 36, y: center.y + direction.y * 36))
                ray.addLine(to: CGPoint(x: center.x + direction.x * rayEnd, y: center.y + direction.y * rayEnd))
                context.stroke(ray, with: .color(iconColor), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            }
        }
        .frame(width: 170, height: 170)
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
