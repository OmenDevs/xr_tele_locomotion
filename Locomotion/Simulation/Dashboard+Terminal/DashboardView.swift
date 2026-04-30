//
//  DashboardView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 26/03/26.
//

import SwiftUI
import Charts

struct DashboardView: View {
    var recording: RecordingViewModel
    var body: some View {
        VStack(spacing: 20) {
            Text("Telemetry Dashboard")
                .font(.title)

            TelemetryChart(
                title: "Velocity X",
                data: recording.telemetry,
                value: \.normalizedVelocityX,
                color: .red)

            TelemetryChart(
                title: "Velocity Y",
                data: recording.telemetry,
                value: \.normalizedVelocityY,
                color: .green)

            TelemetryChart(
                title: "Angular Velocity",
                data: recording.telemetry,
                value: \.normalizedAngularVelocity,
                color: .blue)
        }
        .padding()
    }
}

#Preview {
    DashboardView(recording: RecordingViewModel())
}

struct TelemetryChart: View {
    let title: String
    let data: [TelemetryEntry]
    let value: KeyPath<TelemetryEntry, Double>
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)

            Chart(data) { entry in
                LineMark(
                    x: .value("Sample", entry.timestamp),
                    y: .value(title, entry[keyPath: value])
                )
                .foregroundStyle(color)
            }
            .chartYScale(domain: -1...1)
            .chartXAxis(.hidden)
            .frame(height: 150)
        }
    }
}
