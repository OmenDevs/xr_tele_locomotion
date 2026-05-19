//
//  Instructions+Model.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 14/05/26.
//

import Foundation

enum InstructionCompletion {
    case pinch
    case moveForward
    case moveBackward
    case moveSideways
    case rotateRight
    case rotateLeft
}

struct Instruction: Identifiable {
    let id = UUID()
    let text: String
    let video: String?
    let completion: InstructionCompletion
}
