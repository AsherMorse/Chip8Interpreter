//
//  MainViewController.swift
//  Chip8Interpreter
//
//  Created by Asher Morse on 7/1/24.
//

import Cocoa

class MainViewController: NSViewController {
    @IBOutlet weak var displayView: DisplayView!
    
    private var width = Int()
    private var height = Int()
    
    private var chip8: Chip8?
    private var timer: Timer?
    
    private var tickRate: Double = 1.0/125
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        width = 64
        height = 32
        
        displayView.keyPressResponderDelegate = self
        displayView.displayMap = [Bool](repeating: false, count: width * height)
        displayView.displayWidth = width
        displayView.displayHeight = height
    }
    
    @objc func runTick() {
        guard let chip8, let timer else { return }
        
        chip8.tick()
         if chip8.render {
             displayView.displayMap = chip8.displayMap
             displayView.needsDisplay = true
         }
         if chip8.waitingForKey {
             timer.invalidate()
         }
    }
    
    @IBAction func loadROM(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        openPanel.begin { [weak self] _ in
            guard let self else { return }
            if let fileURL = openPanel.url {
                do {
                    let rom = try Data(contentsOf: fileURL)
                    self.chip8 = Chip8(width: width, height: height, rom: rom.bytes)
                    self.timer = Timer.scheduledTimer(timeInterval: tickRate, target: self, selector: #selector(runTick), userInfo: nil, repeats: true)
                } catch {
                    print("ROM error")
                }
            }
        }
    }
    
    @IBAction func displayBackgroundColorChanged(_ sender: Any) {
        if let sender = sender as? NSColorWell {
            displayView.displayBackgroundColor = sender.color
            displayView.needsDisplay = true
        }
    }
    
    @IBAction func displayForegroundColorChanged(_ sender: Any) {
        if let sender = sender as? NSColorWell {
            displayView.displayForegroundColor = sender.color
            displayView.needsDisplay = true
        }
    }
    
    private let validKeys = ["x", "1", "2", "3",
                             "q", "w", "e", "a",
                             "s", "d", "z", "c",
                             "4", "r", "f", "v"]
}

extension MainViewController: KeyPressResponderDelegate {
    func keyPressed(with event: NSEvent) {
        guard let key = event.characters,
              let chip8 else { return }
        if let index = validKeys.firstIndex(of: key) {
            chip8.keyboard[index] = true
            if chip8.waitingForKey {
                chip8.keyPressVal = Byte(index)
                timer = Timer.scheduledTimer(timeInterval: tickRate, target: self, selector: #selector(self.runTick), userInfo: nil, repeats: true)
            }
        }
    }
    
    func keyReleased(with event: NSEvent) {
        guard let key = event.characters,
              let chip8 else { return }
        if let index = validKeys.firstIndex(of: key) {
            chip8.keyboard[index] = false
        }
    }
}
