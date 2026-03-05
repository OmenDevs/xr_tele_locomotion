//
//  CameraSwitchView.swift
//  Locomotion
//
//  Created by Can Dindar on 04/03/26.
//

import SwiftUI

/// This view is for changing the streams of Real Sense d435i camera
struct CameraSwitchView: View {
    @Environment(RobotWebRTCClient.self) var client

    var streams = ["Color", "Depth", "Infrared"]
    @State private var selectedStream = "Color"

    var body: some View {
        Picker("Stream", selection: $selectedStream) {
            ForEach(streams, id: \.self) { stream in
                Text(stream).tag(stream)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        
        /// send stream changes to data channel
        .onChange(of: selectedStream) { _, newValue in
            client.sendCommand("stream:\(newValue.lowercased())")
        }
    }
}
