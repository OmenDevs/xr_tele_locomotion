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

    private let radius: Float = 0.16
    private let ringThickness: Float = 0.003
    private let ringSegments: Int = 64

    private let centerRadius: Float = 0.005
    private let cursorRadius: Float = 0.008
    private let turnBallRadius: Float = 0.010

    private let markLength: Float = 0.012
    private let markThickness: Float = 0.003

    private let turnNeutralTheta: Float = .pi / 2
    private let turnMaxAngularTravel: Float = .pi / 2

    private var cursorEntity: ModelEntity?
    private var turnBallEntity: ModelEntity?
    private var entitiesBuilt = false

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

        let offset = state.cursor - state.origin
        cursorEntity?.position = SIMD3<Float>(offset.x, 0, offset.z)

        let signed = Float(state.normalizedTurnAngle).clamped(to: -1...1)
        let theta = turnNeutralTheta - turnMaxAngularTravel * signed
        turnBallEntity?.position = SIMD3<Float>(radius * cos(theta), radius * sin(theta), 0)
    }

    func hide() {
        rootEntity.isEnabled = false
    }

    private func buildEntities() {
        buildCenterMark()
        buildDragRing()
        buildTurnRing()
        buildCursors()
    }

    private func buildCenterMark() {
        add(
            ModelEntity(mesh: .generateSphere(radius: centerRadius), materials: [unlit(.white)]),
            name: "centerMark"
        )
    }

    private func buildDragRing() {
        addRing(
            name: "dragRing",
            startAngle: 0, endAngle: 2 * .pi,
            basisU: SIMD3<Float>(1, 0, 0),
            basisV: SIMD3<Float>(0, 0, 1)
        )
        let tickOffset = radius + markLength / 2
        let size = SIMD3<Float>(markThickness, markThickness, markLength)
        addTick(name: "dragFrontMark", size: size, position: SIMD3<Float>(0, 0, -tickOffset))
        addTick(name: "dragBackMark", size: size, position: SIMD3<Float>(0, 0, tickOffset))
    }

    private func buildTurnRing() {
        addRing(
            name: "turnRing",
            startAngle: 0, endAngle: .pi,
            basisU: SIMD3<Float>(1, 0, 0),
            basisV: SIMD3<Float>(0, 1, 0)
        )
        let tickOffset = radius + markLength / 2
        let size = SIMD3<Float>(markThickness, markLength, markThickness)
        addTick(name: "turnNeutralMark", size: size, position: SIMD3<Float>(0, tickOffset, 0))
    }

    private func buildCursors() {
        let cursor = ModelEntity(mesh: .generateSphere(radius: cursorRadius), materials: [unlit(.cyan)])
        add(cursor, name: "dragCursor")
        cursorEntity = cursor

        let ball = ModelEntity(mesh: .generateSphere(radius: turnBallRadius), materials: [unlit(.cyan)])
        add(ball, name: "turnBall")
        turnBallEntity = ball
    }

    private func add(_ entity: Entity, name: String) {
        entity.name = name
        rootEntity.addChild(entity)
    }

    private func addTick(name: String, size: SIMD3<Float>, position: SIMD3<Float>) {
        let entity = ModelEntity(mesh: .generateBox(size: size), materials: [unlit(.white)])
        entity.position = position
        add(entity, name: name)
    }

    private func addRing(name: String, startAngle: Float, endAngle: Float,
                         basisU: SIMD3<Float>, basisV: SIMD3<Float>) {
        guard let mesh = buildRingMesh(startAngle: startAngle, endAngle: endAngle,
                                       basisU: basisU, basisV: basisV) else { return }
        var material = unlit(.white)
        material.faceCulling = .none
        add(ModelEntity(mesh: mesh, materials: [material]), name: name)
    }

    private func unlit(_ color: UIColor) -> UnlitMaterial {
        var mat = UnlitMaterial()
        mat.color = .init(tint: color)
        return mat
    }

    private func buildRingMesh(startAngle: Float, endAngle: Float,
                               basisU: SIMD3<Float>, basisV: SIMD3<Float>) -> MeshResource? {
        guard ringSegments >= 1, endAngle > startAngle else { return nil }

        let inner = max(radius - ringThickness / 2, 0.0001)
        let outer = radius + ringThickness / 2
        let normal = simd_normalize(simd_cross(basisU, basisV))

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        let step = (endAngle - startAngle) / Float(ringSegments)
        for idx in 0...ringSegments {
            let theta = startAngle + step * Float(idx)
            let cosT = cos(theta), sinT = sin(theta)
            positions.append(inner * cosT * basisU + inner * sinT * basisV)
            positions.append(outer * cosT * basisU + outer * sinT * basisV)
            normals.append(contentsOf: [normal, normal])
        }

        for idx in 0..<ringSegments {
            let index = UInt32(idx * 2)
            indices.append(contentsOf: [index, index+1, index+3, index, index+3, index+2])
        }

        var descriptor = MeshDescriptor(name: "ring")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.primitives = .triangles(indices)

        return try? MeshResource.generate(from: [descriptor])
    }
}
