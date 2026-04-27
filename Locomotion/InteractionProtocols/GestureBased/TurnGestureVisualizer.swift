//
//  TurnGestureVisualizer.swift
//  Locomotion
//
//  Created by Bekhruzjon Hakmirzaev on 23/04/26.
//

import RealityKit
import UIKit
import simd

struct TurnVisualizerState {
    let origin: SIMD3<Float>
    let axis: SIMD3<Float>
    let referenceDir: SIMD3<Float>
    let currentDir: SIMD3<Float>
}

/// Manages RealityKit entities that visualize the turn gesture.
@MainActor
final class TurnGestureVisualizer {

    // MARK: - Public

    /// The root entity to add to the RealityKit scene.
    let rootEntity = Entity()

    // MARK: - Configuration

    private let diskRadius: Float = 0.06       // meters
    private let sphereRadius: Float = 0.006
    private let lineThickness: Float = 0.002
    private let arcSegments: Int = 32

    // MARK: - Child Entities

    private var sphereEntity: ModelEntity?
    private var referenceLineEntity: ModelEntity?
    private var currentLineEntity: ModelEntity?
    private var diskEntity: ModelEntity?
    private var isShowing = false

    // MARK: - Initialization

    init() {
        rootEntity.name = "TurnGestureVisualizer"
        rootEntity.isEnabled = false
    }

    // MARK: - Public API

    func update(with visualState: TurnVisualizerState) {
        if !isShowing {
            buildEntities()
            rootEntity.isEnabled = true
            isShowing = true
        }

        rootEntity.position = visualState.origin

        // Build a right-handed rotation matrix:
        //   local +X  →  referenceDir
        //   local +Y  →  axis  (normal to the disk plane)
        //   local +Z  →  cross(referenceDir, axis)
        // col0 × col1 must equal col2 for det = +1; cross(axis, referenceDir) gives det = -1.
        let tangent = simd_normalize(simd_cross(visualState.referenceDir, visualState.axis))
        let orientationMatrix = simd_float3x3(
            columns: (visualState.referenceDir, visualState.axis, tangent))
        rootEntity.orientation = simd_quatf(orientationMatrix)

        sphereEntity?.position = .zero
        updateLine(referenceLineEntity, length: diskRadius, localDirection: SIMD3<Float>(1, 0, 0))

        let invOrientation = rootEntity.orientation.inverse
        let localCurrentDir = invOrientation.act(visualState.currentDir)
        updateLine(currentLineEntity, length: diskRadius, localDirection: simd_normalize(localCurrentDir))

        diskEntity?.position = .zero
    }

    func hide() {
        rootEntity.isEnabled = false
        isShowing = false
    }

    // MARK: - Build Entities

    private func buildEntities() {
        guard sphereEntity == nil else { return }

        // --- Sphere at pivot ---
        let sphereMesh = MeshResource.generateSphere(radius: sphereRadius)
        var sphereMat = UnlitMaterial()
        sphereMat.color = .init(tint: .white)
        let sphere = ModelEntity(mesh: sphereMesh, materials: [sphereMat])
        sphere.name = "pivotSphere"
        rootEntity.addChild(sphere)
        sphereEntity = sphere

        // --- Half-circle disk (background) ---
        if let halfDiskMesh = buildHalfDiskMesh(radius: diskRadius) {
            var diskMat = UnlitMaterial()
            diskMat.color = .init(tint: UIColor(white: 0.5, alpha: 0.15))
            diskMat.faceCulling = .none
            let disk = ModelEntity(mesh: halfDiskMesh, materials: [diskMat])
            disk.name = "halfDisk"
            rootEntity.addChild(disk)
            diskEntity = disk
        }

        // --- Reference line (white) ---
        let refLine = buildLineEntity(color: .white)
        refLine.name = "referenceLine"
        rootEntity.addChild(refLine)
        referenceLineEntity = refLine

        // --- Current line (cyan) ---
        let curLine = buildLineEntity(color: .cyan)
        curLine.name = "currentLine"
        rootEntity.addChild(curLine)
        currentLineEntity = curLine
    }

    // MARK: - Line Helpers

    private func buildLineEntity(color: UIColor) -> ModelEntity {
        let mesh = MeshResource.generateBox(
            size: SIMD3<Float>(diskRadius, lineThickness, lineThickness))
        var mat = UnlitMaterial()
        mat.color = .init(tint: color)
        return ModelEntity(mesh: mesh, materials: [mat])
    }

    private func updateLine(_ entity: ModelEntity?, length: Float, localDirection: SIMD3<Float>) {
        guard let entity else { return }
        // The box mesh is centered at origin along X; offset midpoint so line runs from 0 to `length`.
        let dir = simd_normalize(localDirection)
        entity.position = dir * (length / 2.0)

        // Orient the box so its local +X aligns with `dir`.
        let defaultDir = SIMD3<Float>(1, 0, 0)
        if simd_length(simd_cross(defaultDir, dir)) > 0.0001 {
            entity.orientation = simd_quatf(from: defaultDir, to: dir)
        } else if simd_dot(defaultDir, dir) < 0 {
            // 180° flip
            entity.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
        } else {
            entity.orientation = .init()
        }
    }

    // MARK: - Mesh Generation

    private func buildHalfDiskMesh(radius: Float) -> MeshResource? {
        let startAngle: Float = -.pi / 2
        return buildFanMesh(startAngle: startAngle, endAngle: startAngle + .pi,
                            radius: radius, segments: arcSegments)
    }

    private func buildFanMesh(
        startAngle: Float,
        endAngle: Float,
        radius: Float,
        segments: Int
    ) -> MeshResource? {
        guard segments > 0 else { return nil }

        var positions: [SIMD3<Float>] = [.zero]  // center vertex
        var normals: [SIMD3<Float>] = [SIMD3<Float>(0, 1, 0)]
        var indices: [UInt32] = []

        let step = (endAngle - startAngle) / Float(segments)
        for idx in 0...segments {
            let theta = startAngle + step * Float(idx)
            positions.append(SIMD3<Float>(radius * cos(theta), 0, radius * sin(theta)))
            normals.append(SIMD3<Float>(0, 1, 0))
        }

        // Build triangles: center(0) → idx → idx+1
        for idx in 1...segments {
            if endAngle > startAngle {
                indices.append(contentsOf: [0, UInt32(idx), UInt32(idx + 1)])
            } else {
                indices.append(contentsOf: [0, UInt32(idx + 1), UInt32(idx)])
            }
        }

        var descriptor = MeshDescriptor(name: "fan")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.primitives = .triangles(indices)

        return try? MeshResource.generate(from: [descriptor])
    }
}
