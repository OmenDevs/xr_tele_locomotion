//
//  Instructions+Model.swift
//  Locomotion
//
//  Created by Julio Enrique Sanchez Guajardo on 14/05/26.
//

import Foundation

struct Instruction: Identifiable {
    let id = UUID()
    let text: String
    let video: String?
}
