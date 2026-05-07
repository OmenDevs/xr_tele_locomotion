//
//  UniformWindowResize.swift
//  Locomotion
//
//  Created by Bekhruzjon Hakmirzaev on 26/03/26.
//

import SwiftUI

extension View {
    /// Locks the visionOS window to uniform (proportional) resizing for CameraView.
    func uniformWindowResize() -> some View {
        self.onAppear {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                return
            }
            let preferences = UIWindowScene.GeometryPreferences.Vision(
                resizingRestrictions: .uniform
            )
            scene.requestGeometryUpdate(preferences)
        }
    }
}
