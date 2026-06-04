//
//  DragGestureVisualizer.swift
//  Locomotion
//
//  Created by Can Dindar on 27/04/26.
//

import RealityKit
import UIKit
import simd

struct DragVisualizerState {
    let origin: SIMD3<Float>
    let cursor: SIMD3<Float>
    /// Yaw (radians, +Y axis) of the user-local frame captured at pinch start.
    /// The visualizer rotates so its front mark points along the user's forward.
    let yaw: Float
    let normalizedTurnAngle: Double
}

/// Visualizes the drag + turn gesture as a pair of perpendicular rings:
/// - Drag ring (white, XZ plane) with front/back ticks and a cyan cursor.
/// - Turn ring (white, top half-circle on XY plane) with a neutral tick and
///   a cyan ball whose angular position reflects the normalized turn.
@MainActor
final class DragGestureVisualizer {

    let rootEntity = Entity()

    // MARK: - Configuration

    let radius: Float = 0.16
    let ringThickness: Float = 0.003
    let ringSegments: Int = 64

    let centerRadius: Float = 0.005
    let cursorRadius: Float = 0.008
    let turnBallRadius: Float = 0.010

    let markLength: Float = 0.012
    let markThickness: Float = 0.003

    let turnNeutralTheta: Float = .pi / 2
    let turnMaxAngularTravel: Float = .pi / 2

    var cursorEntity: ModelEntity?
    var turnBallEntity: ModelEntity?
    var entitiesBuilt = false

    init() {
        rootEntity.name = "DragGestureVisualizer"
        rootEntity.isEnabled = false
    }

    func update(with state: DragVisualizerState) {
        if !entitiesBuilt {
            buildEntities()
            entitiesBuilt = true
        }
        rootEntity.isEnabled = true
        rootEntity.position = state.origin
        rootEntity.orientation = simd_quatf(angle: state.yaw, axis: SIMD3<Float>(0, 1, 0))

        // Cursor offset is in world space; convert into the visualizer's local
        // (yaw-rotated) frame so it tracks against the rotated ring.
        let worldOffset = state.cursor - state.origin
        let inverse = simd_quatf(angle: -state.yaw, axis: SIMD3<Float>(0, 1, 0))
        let localOffset = inverse.act(worldOffset)
        cursorEntity?.position = SIMD3<Float>(localOffset.x, 0, localOffset.z)

        let signed = Float(state.normalizedTurnAngle).clamped(to: -1...1)
        let theta = turnNeutralTheta - turnMaxAngularTravel * signed
        turnBallEntity?.position = SIMD3<Float>(radius * cos(theta), radius * sin(theta), 0)
    }

    func hide() {
        rootEntity.isEnabled = false
    }
}
