//
//  Document.swift
//  Wireworld
//
//  Created by nst on 12.05.17.
//  Copyright © 2017 Nicolas Seriot. All rights reserved.
//

import Cocoa

class Document: NSDocument, GridViewDelegate, ModelDelegate {

    var model : Model = Model.defaultModel()
    
    @IBOutlet weak var gridView: GridView!
    @IBOutlet weak var headColorView: ColorView!
    @IBOutlet weak var tailColorView: ColorView!
    @IBOutlet weak var wireColorView: ColorView!
    @IBOutlet weak var emptyColorView: ColorView!

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
        
        self.model.delegate = self
    }
    
    override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
        super.windowControllerDidLoadNib(windowController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
        
        windowController.document = self
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
        
        let d = model.dictionaryRepresentation

        var data = Data()
        
        do {
            data = try JSONSerialization.data(withJSONObject: d, options: [/*.prettyPrinted*/])
        } catch let e as NSError {
            self.presentError(e)
        }
        
        return data
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        
        do {
            if let d = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                
                if let m = Model(d: d) {
                    self.hasUndoManager = true
                    self.model = m
                    
                } else {
                    Swift.print("-- no model from \(d)")
                }
            } else {
                Swift.print("-- no data")
            }
        } catch let e {
            self.presentError(e)
        }
                
        self.updateChangeCount(.changeCleared)
    }
    
    @IBAction func stepAction(sender: NSButton) {
        Swift.print("-- stepAction")
        
        self.model.step()
    }
    
    @IBAction func cellTypeAction(sender: NSButton) {
        Swift.print("-- stepCellType")
        
        guard let id = sender.identifier else { return }
        Swift.print("-- id:            \(id)")
        
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
