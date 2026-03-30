//
//  LogView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 26/03/26.
//

import SwiftUI

struct LogView: View {
    var recording: RecordingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Telemetry Log")
                .font(.title)

            HStack {
                Text("Time")
                    .frame(width: 100, alignment: .leading)
                Text("X")
                    .frame(width: 80, alignment: .trailing)
                Text("Y")
                    .frame(width: 80, alignment: .trailing)
                Text("W")
                    .frame(width: 80, alignment: .trailing)
            }
            .font(.headline)
            .padding(.horizontal)

            ScrollViewReader { proxy in
                List(recording.telemetry) { entry in
                    HStack {
                        Text(entry.timestamp)
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 100, alignment: .leading)
                        Text(String(format: "%.3f", entry.normalizedVelocityX))
                            .frame(width: 80, alignment: .trailing)
                        Text(String(format: "%.3f", entry.normalizedVelocityY))
                            .frame(width: 80, alignment: .trailing)
                        Text(String(format: "%.3f", entry.normalizedAngularVelocity))
                            .frame(width: 80, alignment: .trailing)
                    }
                    .font(.system(.caption, design: .monospaced))
                    .id(entry.id)
                }
                .onChange(of: recording.telemetry.count) {
                    if let last = recording.telemetry.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    LogView(recording: RecordingViewModel())
}
