//
//  UniformWindowResize.swift
//  TestWebRTC
//
//  Applies uniform (aspect-ratio-locked) resizing to the current visionOS window.
//

import SwiftUI

/// A view modifier that requests uniform resizing restrictions on the containing
/// visionOS window scene, locking the aspect ratio so width and height scale together.
struct UniformWindowResize: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                applyUniformResize()
            }
    }

    private func applyUniformResize() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        let preferences = UIWindowScene.GeometryPreferences.Vision(
            resizingRestrictions: .uniform
        )
        scene.requestGeometryUpdate(preferences)
    }
}

extension View {
    /// Locks the visionOS window to uniform (proportional) resizing.
    func uniformWindowResize() -> some View {
        modifier(UniformWindowResize())
    }
}
