//
//  DisplayView.swift
//  Chip8Interpreter
//
//  Created by Asher Morse on 7/1/24.
//

import Cocoa

protocol KeyPressResponderDelegate {
    func keyPressed(with: NSEvent)
    func keyReleased(with: NSEvent)
}

class DisplayView: NSView {
    var displayMap = [Bool]()
    var displayWidth = Int()
    var displayHeight = Int()
    
    var displayBackgroundColor = NSColor(resource: ColorResource.defaultDisplayBackground)
    var displayForegroundColor = NSColor(resource: ColorResource.defaultDisplayForeground)
    
    var keyPressResponderDelegate: KeyPressResponderDelegate?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let pixelExtraSize: Double = 0.4 // To fix visible separators between pixels
        
        let viewWidth: Double = bounds.width
        let viewHeight: Double = bounds.height
        
        let pixelWidth: Double = viewWidth / Double(displayWidth)
        let pixelHeight: Double = viewHeight / Double(displayHeight)
        let pixelSize: CGSize = CGSize(width: pixelWidth + pixelExtraSize, height: pixelHeight + pixelExtraSize)
        
        displayBackgroundColor.setFill()
        bounds.fill()
        displayForegroundColor.setFill()
        
        for x in 0..<displayWidth {
            for y in 0..<displayHeight {
                if displayMap[y * displayWidth + x] {
                    NSRect(origin: CGPoint(x: Double(x) * pixelWidth, y: Double(vFlip(y)) * pixelHeight), size: pixelSize).fill()
                }
            }
        }
    }
    
    private func vFlip(_ y: Int) -> Int {
        return displayHeight - 1 - y
    }
    
    override func keyDown(with event: NSEvent) {
        keyPressResponderDelegate?.keyPressed(with: event)
    }
    
    override func keyUp(with event: NSEvent) {
        keyPressResponderDelegate?.keyReleased(with: event)
    }
    
    override var acceptsFirstResponder: Bool { return true }
}
