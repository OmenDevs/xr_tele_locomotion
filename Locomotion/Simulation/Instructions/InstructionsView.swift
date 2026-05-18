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
                    .foregroundColor(.clear)
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
                            if let videoName = instructions[currentIndex].video,
                               let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
                                VideoPlayer(player: loopingPlayer(url))
                                    .frame(height: 200)
                                    .disabled(true)
                            }
                            Text(instructions[currentIndex].text)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Spacer()
                        }
                        .padding()
                    }
                Spacer(minLength: spacerHorizontal)
            }
            Spacer(minLength: spacerVertical)
        }
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
        guard currentIndex < totalInstructions - 1

        else { return }
        currentIndex += 1
    }
    private func previousIndex() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    private func loopingPlayer(_ url: URL) -> AVPlayer {
        let player = AVPlayer(url: url)
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        player.play()
        return player
    }
}

#Preview {
    InstructionsView()
}
