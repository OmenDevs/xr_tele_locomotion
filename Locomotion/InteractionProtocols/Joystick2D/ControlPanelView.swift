//
//  ControlPanelView.swift
//  Locomotion
//
//  Created by Bekhruzjon Hakmirzaev on 26/03/26.
//

import SwiftUI

/// Joystick control panel: two sticks + three velocity readouts.
/// Only handles — producing velocityX, velocityY, angularVelocity.
struct ControlPanelView: View {

    @Environment(InputViewModel.self) private var input
    var client: RobotWebRTCClient?

    @State private var sendTimer: Timer?

    private let blue  = Color(red: 0.35, green: 0.78, blue: 1.00)
    private let green = Color(red: 0.20, green: 0.90, blue: 0.55)

    var body: some View {
        @Bindable var input = input

        VStack(spacing: 14) {
            hudBar

            // MARK: - Joystick row
            HStack(spacing: 16) {
                JoystickView(
                    label: "Left Stick",
                    sublabel: "lin. velocity  x / y",
                    accentColor: .white,
                    xAxis: $input.velocityX,
                    yAxis: $input.velocityY
                )
                Spacer()
                JoystickView(
                    label: "Right Stick",
                    sublabel: "angular  ω",
                    accentColor: .white,
                    xAxis: $input.angularVelocity,
                    yAxis: .constant(0)
                )
            }
            .padding(14)

            metricsRow
        }
        .padding(20)
        .glassBackgroundEffect()
        .onChange(of: input.velocityX) { onJoystickChanged() }
        .onChange(of: input.velocityY) { onJoystickChanged() }
        .onChange(of: input.angularVelocity) { onJoystickChanged() }
    }

    // MARK: - HUD bar

    private var hudBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "gamecontroller.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 13))
                Text("LOCOMOTION")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.white)
            }
            Spacer()
            resetButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var resetButton: some View {
        Button {
            input.reset()
        } label: {
            Text("RESET")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.white, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Metrics

    private var metricsRow: some View {
        HStack(spacing: 8) {
            MetricCardView(
                label: "vel x",
                value: String(format: "%+.2f", input.velocityX),
                unit: "m/s",
                color: .white
            )
            MetricCardView(
                label: "vel y",
                value: String(format: "%+.2f", input.velocityY),
                unit: "m/s",
                color: .white
            )
            MetricCardView(
                label: "ang ω",
                value: String(format: "%+.3f", input.angularVelocity),
                unit: "rad/s",
                color: .white
            )
        }
    }

    // MARK: - Helpers

    private func panelBackground(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(color.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.18), lineWidth: 0.5)
            )
    }

    /// Called when any joystick value changes.
    /// Sends 5 commands in 1 second while held; sends one final zero on release.
    private func onJoystickChanged() {
        let isActive = input.velocityX != 0
            || input.velocityY != 0
            || input.angularVelocity != 0

        if isActive {
            guard sendTimer == nil else { return }
            sendVelocity()
            sendTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                Task { @MainActor in
                    sendVelocity()
                }
            }
        } else {
            sendTimer?.invalidate()
            sendTimer = nil
            sendVelocity()
        }
    }

    private func sendVelocity() {
        client?.sendVelocity(
            velocityX: input.velocityX,
            velocityY: input.velocityY,
            omega: input.angularVelocity
        )
    }
}

// MARK: - Metric Card

struct MetricCardView: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(color.opacity(0.5))
                .textCase(.uppercase)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundStyle(color.opacity(0.95))
                    .monospacedDigit()
                Text(unit)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(color.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.18), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    ControlPanelView(client: nil)
        .environment(InputViewModel())
        .frame(width: 720, height: 400)
}
