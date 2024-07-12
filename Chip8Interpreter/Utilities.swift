//
//  Utilities.swift
//  Chip8Interpreter
//
//  Created by Asher Morse on 7/1/24.
//

import Foundation

typealias Byte = UInt8
typealias Word = UInt16

extension Data {
    var bytes: [Byte] {
        return withUnsafeBytes { buffer -> [Byte] in
            return Array(buffer.bindMemory(to: Byte.self))
        }
    }
}

extension Array {
    subscript<T: UnsignedInteger>(index: T) -> Element {
        get { return self[Int(index)] }
        set { self[Int(index)] = newValue }
    }
}
