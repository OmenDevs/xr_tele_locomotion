//
//  JoystickView.swift
//  Locomotion
//
//  Migrated from Robot Pilot – cleaned for Locomotion.
//

import SwiftUI

/// A single dual-axis joystick. Outputs normalized x / y in -1…+1.
struct JoystickView: View {

    let label: String
    let sublabel: String
    let accentColor: Color

    @Binding var xAxis: Double
    @Binding var yAxis: Double

    private let baseRadius: CGFloat = 68
    private let thumbRadius: CGFloat = 22

    @State private var thumbOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 8) {
            labelHeader
            joystickBase
            sublabelFooter
        }
        .padding(14)
        .background(cardBackground)
    }

    // MARK: - Sub-views

    private var labelHeader: some View {
        Text(label)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(2)
            .foregroundStyle(accentColor.opacity(0.7))
            .textCase(.uppercase)
    }

    private var joystickBase: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(accentColor.opacity(0.25), lineWidth: 1)
                .frame(width: baseRadius * 2, height: baseRadius * 2)

            // Inner guide rings
            ForEach([0.33, 0.66], id: \.self) { frac in
                Circle()
                    .stroke(accentColor.opacity(0.1), lineWidth: 0.5)
                    .frame(width: baseRadius * 2 * frac,
                           height: baseRadius * 2 * frac)
            }

            // Background fill
            Circle()
                .fill(accentColor.opacity(isDragging ? 0.07 : 0.04))
                .frame(width: baseRadius * 2, height: baseRadius * 2)

            // Thumb
            thumb
        }
        .frame(width: baseRadius * 2, height: baseRadius * 2)
        .gesture(dragGesture)
    }

    private var thumb: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [accentColor.opacity(0.95),
                             accentColor.opacity(0.35)],
                    center: .center,
                    startRadius: 0,
                    endRadius: thumbRadius
                )
            )
            .frame(width: thumbRadius * 2, height: thumbRadius * 2)
            .overlay(Circle().stroke(accentColor.opacity(0.8), lineWidth: 1))
            .offset(thumbOffset)
            .shadow(color: accentColor.opacity(0.4),
                    radius: isDragging ? 10 : 4)
            .animation(.interactiveSpring(response: 0.2), value: thumbOffset)
    }


    private var sublabelFooter: some View {
        Text(sublabel)
            .font(.system(size: 9, weight: .regular, design: .monospaced))
            .foregroundStyle(accentColor.opacity(0.3))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(accentColor.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(accentColor.opacity(0.18), lineWidth: 0.5)
            )
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true
                var deltaX = value.translation.width
                var deltaY = value.translation.height
                let dist = sqrt(deltaX * deltaX + deltaY * deltaY)
                if dist > baseRadius {
                    deltaX = deltaX / dist * baseRadius
                    deltaY = deltaY / dist * baseRadius
                }
                thumbOffset = CGSize(width: deltaX, height: deltaY)
                xAxis =  Double(deltaX / baseRadius)
                yAxis = Double(-deltaY / baseRadius)   // up = positive
            }
            .onEnded { _ in
                isDragging = false
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    thumbOffset = .zero
                }
                xAxis = 0
                yAxis = 0
            }
    }
}
