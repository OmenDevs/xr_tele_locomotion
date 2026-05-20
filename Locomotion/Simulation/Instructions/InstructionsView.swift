//
//  InstructionsView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 14/05/26.
//

import SwiftUI
import AVKit

struct InstructionsView: View {
    @Environment(InteractionConfig.self) private var interactionConfig
    private var input = InputViewModel.shared
    private let completionThreshold: Double = 0.9
    private var instructions: [Instruction] {
        switch interactionConfig.selectedInteraction {
        case .joystick2D: return Instructions.joytick3D
        case .joystick3D: return Instructions.joytick3D
        case .gestureBased: return Instructions.astrolabium
        }
    }
    var totalInstructions: Int { instructions.count }
    @State private var currentIndex: Int = 0
    @State private var isForward: Bool = true
    @State private var playerCache: [String: AVPlayer] = [:]
    @State private var looperCache: [String: AVPlayerLooper] = [:]
    @State private var areVideosLoaded: Bool = false
    var isFirst: Bool { currentIndex == 0 }
    var isLast: Bool { currentIndex == totalInstructions - 1 }

    private let ornamentSize: CGSize = .init(width: 400, height: 400)
    private let ornamentSpacing: CGFloat = 80
    private var spacerHorizontal: CGFloat = 450
    private var spacerVertical: CGFloat = 250

    var body: some View {
        VStack {
            HStack {
                Rectangle()
                    .foregroundColor(.black)
                    .glassBackgroundEffect()
                    .frame(
                        width: ornamentSize.width,
                        height: ornamentSize.height
                    )
                    .overlay {
                        VStack {
                            HStack {
                                Button { previousIndex() } label: { Image(systemName: "arrow.left") }
                                    .disabled(isFirst)
                                Spacer()
                                Text("\(currentIndex + 1)/\(instructions.count)")
                                Spacer()
                                Button { nextIndex() } label: { Image(systemName: "arrow.right") }
                                    .disabled(isLast)
                            }
                            .padding()
                            Spacer()
                            VStack {
                                Text(instructions[currentIndex].text)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                if let videoName = instructions[currentIndex].video {
                                    if areVideosLoaded, let player = playerCache[videoName] {
                                        VideoPlayer(player: player)
                                            .frame(height: 200)
                                            .disabled(true)
                                    } else {
                                        ProgressView()
                                            .frame(height: 200)
                                    }
                                }
                            }
                            .id(currentIndex)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: isForward ? .trailing : .leading)),
                                removal: .opacity.combined(with: .move(edge: isForward ? .leading : .trailing))
                            ))
                            if isLast {
                                Button {
                                    replay()
                                } label: {
                                    Label("Replay", systemImage: "arrow.counterclockwise")
                                }
                                .padding(.top, 12)
                                .id(currentIndex)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: isForward ? .trailing : .leading)),
                                    removal: .opacity.combined(with: .move(edge: isForward ? .leading : .trailing))
                                ))
                            }
                            Spacer()
                        }
                        .padding()
                    }
                Spacer(minLength: spacerHorizontal)
            }
            Spacer(minLength: spacerVertical)
        }
        .onAppear { preloadPlayers() }
        .onChange(of: input.velocityX) { _, _ in checkCompletion() }
        .onChange(of: input.velocityY) { _, _ in checkCompletion() }
        .onChange(of: input.angularVelocity) { _, _ in checkCompletion() }
        .onChange(of: input.isActive) { _, _ in checkCompletion() }
    }

    private func checkCompletion() {
        guard currentIndex < instructions.count else { return }
        let threshold = completionThreshold
        let satisfied: Bool
        switch instructions[currentIndex].completion {
        case .pinch:
            satisfied = input.isActive
                || input.velocityX != 0
                || input.velocityY != 0
                || input.angularVelocity != 0
        case .moveForward:
            satisfied = input.velocityY >= threshold
        case .moveBackward:
            satisfied = input.velocityY <= -threshold
        case .moveSideways:
            satisfied = abs(input.velocityX) >= threshold
        case .rotateRight:
            satisfied = input.angularVelocity <= -threshold
        case .rotateLeft:
            satisfied = input.angularVelocity >= threshold
        }
        if satisfied { nextIndex() }
    }

    private func nextIndex() {
        guard currentIndex < totalInstructions - 1 else { return }
        isForward = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentIndex += 1
        }
    }
    private func previousIndex() {
        guard currentIndex > 0 else { return }
        isForward = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentIndex -= 1
        }
    }
    private func replay() {
        guard currentIndex != 0 else { return }
        isForward = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentIndex = 0
        }
    }

    private func preloadPlayers() {
        let videoNames = Set(instructions.compactMap { $0.video })
        areVideosLoaded = false
        for name in videoNames {
            guard playerCache[name] == nil,
                  let url = Bundle.main.url(forResource: name, withExtension: "mp4") else { continue }
            let item = AVPlayerItem(url: url)
            let player = AVQueuePlayer(playerItem: item)
            let looper = AVPlayerLooper(player: player, templateItem: item)
            playerCache[name] = player
            looperCache[name] = looper
            player.play()
        }
        areVideosLoaded = true
    }
}

#Preview {
    InstructionsView()
}
