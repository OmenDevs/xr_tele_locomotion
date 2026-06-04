//
//  InstructionsView.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 14/05/26.
//

import SwiftUI

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
    var isFirst: Bool { currentIndex == 0 }
    var isLast: Bool { currentIndex == totalInstructions - 1 }

    private let ornamentSize: CGSize = .init(width: 400, height: 440)
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
                                if let gifName = instructions[currentIndex].video {
                                    AnimatedGIFView(name: gifName)
                                        .frame(maxWidth: .infinity, maxHeight: 200)
                                        .clipped()
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
        if satisfied {
            let indexAtCheck = currentIndex
            Task { @MainActor in
                guard currentIndex == indexAtCheck else { return }
                nextIndex()
            }
        }
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
}

private struct AnimatedGIFView: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.image = loadGIF()
        return imageView
    }

    func updateUIView(_ imageView: UIImageView, context: Context) { }

    private func loadGIF() -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        let frames = (0..<count).compactMap {
            CGImageSourceCreateImageAtIndex(source, $0, nil).map { UIImage(cgImage: $0) }
        }
        return UIImage.animatedImage(with: frames, duration: Double(count) * 0.05)
    }
}

#Preview {
    InstructionsView()
}
