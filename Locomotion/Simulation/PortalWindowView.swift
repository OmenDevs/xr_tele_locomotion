//
//  PortalWindowView.swift
//  Locomotion
//
//  Created by Bekhruzjon Hakmirzaev on 11/05/26.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct PortalWindowView: View {
    @Environment(POVSimulatorViewModel.self) private var povSimulator
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var frameSubscription: EventSubscription?
    @State private var portalPlaneEntity: ModelEntity?
    @State private var windowSize: CGSize = CGSize(width: 1280, height: 720)
    @State private var showExitConfirm: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            portalContent

            HStack {
                Button("Exit") { showExitConfirm = true }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .offset(z: 10)
        }
        .confirmationDialog("Exit", isPresented: $showExitConfirm) {
            Button("Yes", role: .destructive) {
                exitToLanding()
            }
            Button("No") { showExitConfirm = false }
        } message: {
            Text("Do you want to exit this view?")
        }
        .onDisappear {
            dismissWindow(id: "joystick")
            dismissWindow(id: "dashboard")
            openWindow(id: "landing")
            Task { await dismissImmersiveSpace() }
        }
        .uniformWindowResize()
    }

    private var portalContent: some View {
        GeometryReader { geo in
            RealityView { content in
                let portalContentRoot = Entity()
                portalContentRoot.components.set(WorldComponent())
                content.add(portalContentRoot)

                let plane = ModelEntity(
                    mesh: .generatePlane(width: 3.55, height: 2),
                    materials: [PortalMaterial()]
                )
                plane.components.set(PortalComponent(target: portalContentRoot))
                content.add(plane)
                portalPlaneEntity = plane

                guard let scenarioEntity = try? await Entity(named: "Draft_Road", in: realityKitContentBundle)
                else { return }

                scenarioEntity.transform = Transform(
                    scale: SIMD3<Float>(repeating: 0.4),
                    rotation: simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(1, 0, 0)),
                    translation: SIMD3<Float>(0, -1.5, 0)
                )
                makeUnlit(scenarioEntity)

                let scenarioWrapper = Entity()
                scenarioWrapper.name = "scenarioEntity"
                scenarioWrapper.addChild(scenarioEntity)
                portalContentRoot.addChild(scenarioWrapper)

                frameSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                    guard let entity = event.scene.findEntity(named: "scenarioEntity") else { return }
                    let userPose = Transform(
                        rotation: simd_quatf(
                            angle: Float(povSimulator.scenarioHeading),
                            axis: SIMD3<Float>(0, 1, 0)),
                        translation: SIMD3<Float>(
                            Float(povSimulator.scenarioX),
                            0,
                            -Float(povSimulator.scenarioY))
                    )
                    entity.transform = Transform(matrix: userPose.matrix.inverse)
                }
            } update: { content in
                guard let plane = portalPlaneEntity else { return }
                let origin = content.convert(Point3D(x: 0, y: 0, z: 0), from: .local, to: .scene)
                let corner = content.convert(
                    Point3D(x: windowSize.width, y: windowSize.height, z: 0),
                    from: .local,
                    to: .scene
                )
                let planeWidth  = Float(abs(corner.x - origin.x))
                let planeHeight = Float(abs(corner.y - origin.y))
                plane.model?.mesh = .generatePlane(width: planeWidth, height: planeHeight)
            }
            .onChange(of: geo.size) { _, newSize in
                windowSize = newSize
            }
        }
        .uniformWindowResize()
        .ornament(attachmentAnchor: .scene(.leading)) {
            InstructionsView()
        }
    }

    private func exitToLanding() {
        dismissWindow(id: "portal")

    }

    @MainActor
    private func makeUnlit(_ entity: Entity) {
        if let model = entity as? ModelEntity, var component = model.model {
            component.materials = component.materials.map { mat in
                guard let pbr = mat as? PhysicallyBasedMaterial else { return mat }
                var unlit = UnlitMaterial()
                unlit.color = .init(tint: pbr.baseColor.tint, texture: pbr.baseColor.texture)
                return unlit
            }
            model.model = component
        }
        for child in entity.children {
            makeUnlit(child)
        }
    }
}
