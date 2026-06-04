//
//  DragGestureVisualizer+Build.swift
//  Locomotion
//
//  Created by Can Dindar on 07/05/2026.
//

import RealityKit
import UIKit
import simd

@MainActor
extension DragGestureVisualizer {

    func buildEntities() {
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
