//
//  Chip8.swift
//  Chip8Interpreter
//
//  Created by Asher Morse on 7/1/24.
//

import Foundation

class Chip8 {
    private let width: Int
    private let height: Int
    var render: Bool
    var waitingForKey: Bool
    private var keyPressReg: Int
    var keyPressVal: Byte
    
    private var v: [Byte]
    private var i: Word
    private var dt: Byte
    private var st: Byte
    private var pc: Word
    private var sp: Byte
    
    private var memory: [Byte]
    private var stack: [Word]
    var keyboard: [Bool]
    var displayMap: [Bool]
    
    private let font: [Byte] = [0xF0, 0x90, 0x90, 0x90, 0xF0,
                                0x20, 0x60, 0x20, 0x20, 0x70,
                                0xF0, 0x10, 0xF0, 0x80, 0xF0,
                                0xF0, 0x10, 0xF0, 0x10, 0xF0,
                                0x90, 0x90, 0xF0, 0x10, 0x10,
                                0xF0, 0x80, 0xF0, 0x10, 0xF0,
                                0xF0, 0x80, 0xF0, 0x90, 0xF0,
                                0xF0, 0x10, 0x20, 0x40, 0x40,
                                0xF0, 0x90, 0xF0, 0x90, 0xF0,
                                0xF0, 0x90, 0xF0, 0x10, 0xF0,
                                0xF0, 0x90, 0xF0, 0x90, 0x90,
                                0xE0, 0x90, 0xE0, 0x90, 0xE0,
                                0xF0, 0x80, 0x80, 0x80, 0xF0,
                                0xE0, 0x90, 0x90, 0x90, 0xE0,
                                0xF0, 0x80, 0xF0, 0x80, 0xF0,
                                0xF0, 0x80, 0xF0, 0x80, 0x80]
    
    init(width: Int = 64, height: Int = 32, rom: [Byte]) {
        self.width = width
        self.height = height
        
        render = false
        waitingForKey = false
        keyPressReg = 16
        keyPressVal = 16
        
        v = [Byte](repeating: 0, count: 16)
        i = 0x0
        dt = 0x0
        st = 0x0
        sp = 0x0
        pc = 0x200
        
        stack = [Word](repeating: 0, count: 16)
        keyboard = [Bool](repeating: false, count: 16)
        displayMap = [Bool](repeating: false, count: width * height)
        
        memory = [Byte](repeating: 0, count: 4096)
        memory.replaceSubrange(0..<font.count, with: font)
        memory.replaceSubrange(0x200..<(rom.count + 0x200), with: rom)
    }
    
    func tick() {
        let b1: Byte = memory[Int(pc)]
        let b2: Byte = memory[Int(pc) + 1]
        let n1: Byte = b1 >> 4
        let n2: Byte = (b1 & 0x0F)
        let n3: Byte = b2 >> 4
        let n4: Byte = (b2 & 0x0F)
        
        let nnn: Word = Word(n2) << 8 | Word(b2)
        let x: Byte = n2
        let y: Byte = n3
        let kk: Byte = b2
        
        dt -= dt > 0 ? 1 : 0
        st -= st > 0 ? 1 : 0
        
        render = false
        
        if keyPressReg != 16 {
            v[keyPressReg] = keyPressVal
            keyPressReg = 16
            return
        }
        
        switch (n1, n2, n3, n4) {
        case (0x0, 0x0, 0xE, 0x0):
            // 00E0 - CLS
            // Clear the display.
            displayMap = [Bool](repeating: false, count: 2048)
            render = true
            pc += 2
        case (0x0, 0x0, 0xE, 0xE):
            // 00EE - RET
            // Return from a subroutine.
            pc = stack[sp]
            sp -= 1
            pc += 2
        case (0x1, _, _, _):
            // 1nnn - JP addr
            // Jump to location nnn.
            pc = nnn
        case (0x2, _, _, _):
            // 2nnn - CALL addr
            // Call subroutine at nnn.
            sp += 1
            stack[sp] = pc
            pc = nnn
        case (0x3, _, _, _):
            // 3xkk - SE Vx, byte
            // Skip next instruction if Vx = kk.
            pc += v[x] == kk ? 4 : 2
        case (0x4, _, _, _):
            // 4xkk - SNE Vx, byte
            // Skip next instruction if Vx != kk.
            pc += v[x] != kk ? 4 : 2
        case (0x5, _, _, 0x0):
            // 5xy0 - SE Vx, Vy
            // Skip next instruction if Vx = Vy.
            pc += v[x] == v[y] ? 4 : 2
        case (0x6, _, _, _):
            // 6xkk - LD Vx, byte
            // Set Vx = kk.
            v[x] = kk
            pc += 2
        case (0x7, _, _, _):
            // 7xkk - ADD Vx, byte
            // Set Vx = Vx + kk.
            v[x] = v[x] &+ kk
            pc += 2
        case (0x8, _, _, 0x0):
            // 8xy0 - LD Vx, Vy
            // Set Vx = Vy.
            v[x] = v[y]
            pc += 2
        case (0x8, _, _, 0x1):
            // 8xy1 - OR Vx, Vy
            // Set Vx = Vx OR Vy.
            v[x] |= v[y]
            v[0xF] = 0
            pc += 2
        case (0x8, _, _, 0x2):
            // 8xy2 - AND Vx, Vy
            // Set Vx = Vx AND Vy.
            v[x] &= v[y]
            v[0xF] = 0
            pc += 2
        case (0x8, _, _, 0x3):
            // 8xy3 - XOR Vx, Vy
            // Set Vx = Vx XOR Vy.
            v[x] ^= v[y]
            v[0xF] = 0
            pc += 2
        case (0x8, _, _, 0x4):
            // 8xy4 - ADD Vx, Vy
            // Set Vx = Vx + Vy, set VF = carry.
            let (sum, carry) = v[x].addingReportingOverflow(v[y])
            v[x] = sum
            v[0xF] = carry ? 1 : 0
            pc += 2
        case (0x8, _, _, 0x5):
            // 8xy5 - SUB Vx, Vy
            // Set Vx = Vx - Vy, set VF = NOT borrow.
            let (diff, carry) = v[x].subtractingReportingOverflow(v[y])
            v[x] = diff
            v[0xF] = carry ? 0 : 1
            pc += 2
        case (0x8, _, _, 0x6):
            // 8xy6 - SHR Vx {, Vy}
            // Set Vx = Vx SHR 1.
            let vf: Byte = v[x] & 0x1
            v[x] = v[x] >> 1
            v[0xF] = vf
            pc += 2
        case (0x8, _, _, 0x7):
            // 8xy7 - SUBN Vx, Vy
            // Set Vx = Vy - Vx, set VF = NOT borrow.
            let (diff, carry) = v[y].subtractingReportingOverflow(v[x])
            v[x] = diff
            v[0xF] = carry ? 0 : 1
            pc += 2
        case (0x8, _, _, 0xE):
            // 8xyE - SHL Vx {, Vy}
            // Set Vx = Vx SHL 1.
            let vf = (v[x] & 0x80) >> 7
            v[x] = v[x] << 1
            v[0xF] = vf
            pc += 2
        case (0x9, _, _, 0x0):
            // 9xy0 - SNE Vx, Vy
            // Skip next instruction if Vx != Vy.
            pc += v[x] != v[y] ? 4 : 2
        case (0xA, _, _, _):
            // Annn - LD I, addr
            // Set I = nnn.
            i = nnn
            pc += 2
        case (0xB, _, _, _):
            // Bnnn - JP V0, addr
            // Jump to location nnn + V0.
            pc = nnn + Word(v[x])
        case (0xC, _, _, _):
            // Cxkk - RND Vx, byte
            // Set Vx = random byte AND kk.
            v[x] = Byte.random(in: 0...Byte.max) & kk
            pc += 2
        case (0xD, _, _, _):
            // Dxyn - DRW Vx, Vy, nibble
            // Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision.
            v[0xF] = draw(x: Int(v[x]), y: Int(v[y]), n: Int(n4)) ? 1 : 0
            pc += 2
        case (0xE, _, 0x9, 0xE):
            // Ex9E - SKP Vx
            // Skip next instruction if key with the value of Vx is pressed.
            pc += keyboard[v[x]] ? 4 : 2
        case (0xE, _, 0xA, 0x1):
            // ExA1 - SKNP Vx
            // Skip next instruction if key with the value of Vx is not pressed.
            pc += !keyboard[v[x]] ? 4 : 2
        case (0xF, _, 0x0, 0x7):
            // Fx07 - LD Vx, DT
            // Set Vx = delay timer value.
            v[x] = dt
            pc += 2
        case (0xF, _, 0x0, 0xA):
            // Fx0A - LD Vx, K
            // Wait for a key press, store the value of the key in Vx.
            waitingForKey = true
            pc += 2
        case (0xF, _, 0x1, 0x5):
            // Fx15 - LD DT, Vx
            // Set delay timer = Vx.
            dt = v[x]
            pc += 2
        case (0xF, _, 0x1, 0x8):
            // Fx18 - LD ST, Vx
            // Set sound timer = Vx.
            st = v[x]
            pc += 2
        case (0xF, _, 0x1, 0xE):
            // Fx1E - ADD I, Vx
            // Set I = I + Vx.
            i += Word(v[x])
            pc += 2
        case (0xF, _, 0x2, 0x9):
            // Fx29 - LD F, Vx
            // Set I = location of sprite for digit Vx.
            i = Word(v[x] * 5)
            pc += 2
        case (0xF, _, 0x3, 0x3):
            // Fx33 - LD B, Vx
            // Store BCD representation of Vx in memory locations I, I+1, and I+2.
            memory[i] = v[x] / 100
            memory[i + 1] = (v[x] % 100) / 10
            memory[i + 2] = v[x] % 10
            pc += 2
        case (0xF, _, 0x5, 0x5):
            // Fx55 - LD [I], Vx
            // Store registers V0 through Vx in memory starting at location I.
            for r in 0...x {
                memory[i] = v[r]
                i += 1
            }
            pc += 2
        case (0xF, _, 0x6, 0x5):
            // Fx65 - LD Vx, [I]
            // Read registers V0 through Vx from memory starting at location I.
            for r in 0...x {
                v[r] = memory[i]
                i += 1
            }
            pc += 2
        default:
            print(String(format: "Invalid opcode: 0x%X", Word(b1) << 8 | Word(b2)))
        }
    }
    
    private func draw(x: Int, y: Int, n: Int) -> Bool {
        var collision = false
        let spriteWidth = 8
        
        for row in 0..<n {
            let spriteRow = memory[Int(i) + row]
            for col in 0..<spriteWidth {
                let newPixel = ((spriteRow << col) & 0x80) != 0
                let wrappedX = (x + col) % width
                let wrappedY = (y + row) % height
                let currentPixel = displayMap[wrappedY * width + wrappedX]
                collision = (currentPixel && newPixel) || collision
                displayMap[wrappedY * width + wrappedX] = currentPixel != newPixel
            }
        }
        
        render = true
        return collision
    }
}
