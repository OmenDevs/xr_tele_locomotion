//
//  RecordingViewModel.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 26/03/26.
//

import Foundation

@Observable
class RecordingViewModel {
    var telemetry: [TelemetryEntry] = []

    private var timeSinceLastRecord: TimeInterval = 0
    private let recordInterval: TimeInterval = 0.2
    private let maxEntries = 100

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    func addTelemetryEntry(
        deltaTime: TimeInterval,
        normalizedVelocityX: Double,
        normalizedVelocityY: Double,
        normalizedAngularVelocity: Double) {
            timeSinceLastRecord += deltaTime
            guard timeSinceLastRecord >= recordInterval else { return }
            timeSinceLastRecord = 0

            let timestamp = dateFormatter.string(from: Date())
            let entry = TelemetryEntry(
                timestamp: timestamp,
                normalizedVelocityX: normalizedVelocityX,
                normalizedVelocityY: normalizedVelocityY,
                normalizedAngularVelocity: normalizedAngularVelocity)

            telemetry.append(entry)

            if telemetry.count > maxEntries {
                telemetry.removeFirst(telemetry.count - maxEntries)
            }
        }
}

struct TelemetryEntry: Identifiable {
    let id = UUID()
    let timestamp: String
    let normalizedVelocityX: Double
    let normalizedVelocityY: Double
    let normalizedAngularVelocity: Double
}
