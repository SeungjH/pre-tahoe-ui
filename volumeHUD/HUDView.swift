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
    @AppStorage("barSegmentOpacity") private var barSegmentOpacity = 0.72
    @AppStorage("barBackgroundOpacity") private var barBackgroundOpacity = 0.86

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
                    if silent {
                        Canvas { context, _ in
                            context.stroke(muteSlash, with: .color(.black), style: StrokeStyle(lineWidth: 11, lineCap: .round))
                        }
                        .frame(width: 170, height: 170)
                        .blendMode(.destinationOut)
                        Canvas { context, _ in
                            context.stroke(muteSlash, with: .color(iconColor), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        }
                        .frame(width: 170, height: 170)
                    }
                }
                .frame(width: 170, height: 170)
                .compositingGroup()
                .offset(x: 15, y: 15)
            } else {
                Image(systemName: "speaker.wave.3.fill")
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
            .padding(1)
            .background(.black.opacity(barBackgroundOpacity))
            .offset(x: 19.5, y: 171)
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

    private var muteSlash: Path {
        var path = Path()
        path.move(to: CGPoint(x: 27, y: 38))
        path.addLine(to: CGPoint(x: 142, y: 111))
        return path
    }

    private var brightnessStage: Int {
        min(3, max(0, Int(value * 4)))
    }

    private var brightnessIcon: some View {
        Canvas { context, _ in
            let center = CGPoint(x: 84.5, y: 71.5)
            let ring = Path(ellipseIn: CGRect(x: 63.5, y: 50.5, width: 42, height: 42))
            context.stroke(ring, with: .color(iconColor), lineWidth: 6)

            let rayEnd = CGFloat(39 + brightnessStage * 5)
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
        let barHeight: CGFloat = 6

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
                    .fill(.white.opacity(barSegmentOpacity))
                    .frame(width: barWidth, height: barHeight)
            } else if value > barStart {
                // Partially filled bar - calculate fill percentage
                let positionInBar = (value - barStart) / (barEnd - barStart)

                // Quantize to 1/4 steps (0.25, 0.5, 0.75)
                let quarterStep = round(positionInBar * 4.0) / 4.0
                let fillWidth = (barWidth * CGFloat(quarterStep) * 2).rounded() / 2

                // Show partial fill with overlay
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.white.opacity(barSegmentOpacity))
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
