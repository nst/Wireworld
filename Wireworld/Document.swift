//
//  Document.swift
//  Wireworld
//
//  Created by nst on 12.05.17.
//  Copyright © 2017 Nicolas Seriot. All rights reserved.
//

import Cocoa

class Document: NSDocument, GridViewDelegate, ModelDelegate {

    var model: Model = Model.defaultModel()
    var timer: Timer? = nil
    var gifImages : [NSImage] = []
    
    @IBOutlet weak var gridView: GridView!
    @IBOutlet weak var headColorView: ColorView!
    @IBOutlet weak var tailColorView: ColorView!
    @IBOutlet weak var wireColorView: ColorView!
    @IBOutlet weak var emptyColorView: ColorView!

    @IBOutlet weak var runStopButton: NSButton!

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
        
    }
    
    override func awakeFromNib() {
        self.headColorView.fillColor = CellState.head.color
        self.tailColorView.fillColor = CellState.tail.color
        self.wireColorView.fillColor = CellState.wire.color
        self.emptyColorView.fillColor = CellState.empty.color

        self.gridView.setNeedsDisplay(self.gridView.frame)
        
        self.runStopButton.title = "Run"

        self.model.delegate = self
    }
    
    override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
        super.windowControllerDidLoadNib(windowController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
        
        windowController.document = self
    }
    
    override func close() {
        if let t = self.timer {
            t.invalidate()
            self.timer = nil
        }
        super.close()
    }

    override class func autosavesInPlace() -> Bool {
        return false
    }
    
    override func defaultDraftName() -> String {
        return "Untitled.wwd"
    }
    
    override var windowNibName: String? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }
    
    override func data(ofType typeName: String) throws -> Data {
        guard let data = model.stringRepresentation.data(using: .utf8) else {
            throw NSError(domain: "WireWorld", code: 0, userInfo: [NSLocalizedDescriptionKey:"Cannot get data out of model"])
        }
        return data
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
                
        do {
            guard let s = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "WireWorld", code: 1, userInfo: [NSLocalizedDescriptionKey:"Cannot get string out of data"])
            }
            
            guard let existingModel = Model(s: s) else {
                throw NSError(domain: "WireWorld", code: 2, userInfo: [NSLocalizedDescriptionKey:"No model"])
            }

            self.model = existingModel
            model.delegate = self
            self.hasUndoManager = true
        
        } catch let e {
            Swift.print("-- no data")
            self.presentError(e)
        }
        
        self.updateChangeCount(.changeCleared)

        if let gv = self.gridView {
            gv.setNeedsDisplay(self.gridView.bounds)
        }
    }
    
    @IBAction func stepAction(sender: NSButton) {
        self.model.step()
    }
    
    @IBAction func runStopAction(sender: NSButton) {
        Swift.print("-- runStopAction")
        
        if let t = timer {
            t.invalidate()
            timer = nil
            runStopButton.title = "Run"

            if self.gifImages.count == 0 {
                return // nothing to save
            }
            
            let savePanel = NSSavePanel()
            
            var filename = "\(Date().timeIntervalSince1970)"
            if let dn = NSURL(fileURLWithPath: self.displayName).deletingPathExtension?.lastPathComponent {
                filename = dn
            }
            savePanel.nameFieldStringValue = "\(filename).gif"
            
            guard let window = self.windowForSheet else { return }
            
            savePanel.beginSheetModal(for: window) { (result: Int) -> Void in
                if result == NSFileHandlingPanelOKButton {
                    guard let exportedFileURL = savePanel.url else {
                        self.gifImages = []
                        return
                    }
                    
                    guard let existingGIF = STGIFMaker(destinationPath: exportedFileURL.path, loop: true) else {
                        Swift.print("-- cannot use path \(exportedFileURL.path)")
                        return
                    }
                    
                    for image in self.gifImages {
                        existingGIF.append(image: image, duration: 0.25)
                    }
                    
                    _ = existingGIF.write()
                    
                    self.gifImages = []
                }
            }
            
        } else {
            
            var makeGIF = false
            if let altPressed = NSApp.currentEvent?.modifierFlags.contains(.option) {
                makeGIF = altPressed
            }
            
            runStopButton.title = "Stop"
            
            // start making gif
            
            self.gifImages = []
            
            guard let image0 = self.gridView.toImage() else { assertionFailure(); return }
            if makeGIF {
                gifImages.append(image0)
            }
            
            self.model.step()

            guard let image1 = self.gridView.toImage() else { assertionFailure(); return }
            if makeGIF {
                gifImages.append(image1)
            }
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { (Timer) in
                self.model.step()
                guard let image = self.gridView.toImage() else { assertionFailure(); return }
                if makeGIF {
                    self.gifImages.append(image)
                }
                
                //if self.gifImages.count == 32 { self.runStopAction(sender: self.runStopButton) }
            })
        }
    }

    @IBAction func cellTypeAction(sender: NSButton) {

        guard let id = sender.identifier else { return }
        
        guard let state = CellState(rawValue: id) else {
            Swift.print("-- no cell state for id \(id)")
            return
        }
        
        self.gridView.editCellState = state
    }
    
    @IBAction func clearAction(sender: Any) {
        Swift.print("-- clearAction")
        
        model.clearMatrix()
        
        self.gridView.setNeedsDisplay(gridView.bounds)
    }
    
    @IBAction func saveImageAction(sender: NSMenuItem?) {
        
        guard let window = self.windowForSheet else { return }
        
        guard let pngData = gridView.PNGRepresentation() else { return }
        
        let savePanel = NSSavePanel()
        let timestamp = Date().timeIntervalSince1970
        savePanel.nameFieldStringValue = "wwd_\(timestamp).png"
        
        savePanel.beginSheetModal(for: window) { (result: Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                guard let exportedFileURL = savePanel.url else { return }
                do {
                    try pngData.write(to: exportedFileURL)
                } catch let e {
                    Swift.print(e)
                }
            }
        }
    }

    // MARK: GridViewDelegate
    
    func cellDidChange(col: Int, row: Int, oldState: CellState, newState: CellState) {
        self.gridView.cellDidChange(col: col, row: row, oldState: oldState, newState: newState)
    }
    
    func matrixDidChange() {
        self.gridView.setNeedsDisplay(gridView.bounds)
    }
}

class ColorView: NSView {
    
    var fillColor: NSColor = NSColor.lightGray
    
    override func draw(_ dirtyRect: NSRect) {
        
        guard let c = NSGraphicsContext.current()?.cgContext else { assertionFailure(); return }
        
        c.setFillColor(fillColor.cgColor)
        c.setStrokeColor(NSColor.black.cgColor)
        c.fill(self.bounds)
        c.stroke(self.bounds)
    }
}

extension NSView {
    func toImage() -> NSImage? {
        let size = self.frame.size
        guard let bir = self.bitmapImageRepForCachingDisplay(in:self.bounds) else { assertionFailure(); return nil }
        bir.size = size
        self.cacheDisplay(in: self.bounds, to: bir)
        let image = NSImage(size: size)
        image.addRepresentation(bir)
        return image
    }
}
