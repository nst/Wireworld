//
//  GridView.swift
//  Wireworld
//
//  Created by nst on 12.05.17.
//  Copyright © 2017 Nicolas Seriot. All rights reserved.
//

import AppKit

@objc protocol GridViewDelegate {
    
    var model: Model { get }
    
    var undoManager : UndoManager? { get set }
}

class GridView: NSView {
    
    let CELL_SIZE : CGFloat = 16.0
    
    var editCellState : CellState = .wire
    
    @IBOutlet var delegate : GridViewDelegate? = nil
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        
        // ...
    }
    
    override var isOpaque : Bool {
        return true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        //Swift.print("***** dirtyRect: \(dirtyRect)")
        
        guard let c = NSGraphicsContext.current()?.cgContext else { assertionFailure(); return }
        
        c.setShouldAntialias(false)
        
        c.setFillColor(NSColor.black.cgColor)
        c.fill(self.bounds)
        
        guard let model = self.delegate?.model else {
            Swift.print("-- GridView cannot draw because it has no model")
            return
        }
        
        let matrix = model.matrix
        
        for col in 0..<matrix.NB_COLS {
            for row in 0..<matrix.NB_ROWS {
                
                let r = self.rectForCell(col: col, row: row)
                //if dirtyRect.intersects(r) == false { continue }
                if self.needsToDraw(r) == false { continue }
                
                //Swift.print("      draw \(col),\(row)")
                
                self.drawCell(col:col, row:row, context:c)
            }
        }
    }
    
    func drawCell(col: Int, row: Int, context c: CGContext) {
        
        guard let model = self.delegate?.model else {
            assertionFailure()
            return
        }
        
        let matrix = model.matrix
        
        let cell = matrix[col,row]
        
        let rect = self.rectForCell(col: col, row: row)
        
        //Swift.print("rect \(rect)")
        
        c.setStrokeColor(NSColor.darkGray.cgColor)
        //c.setLineWidth(1.0)
        
        c.setFillColor(cell.state.color.cgColor)
        
        c.fill(rect)
        c.stroke(rect)
    }
    
    func rectForCell(col:Int, row:Int) -> CGRect {
        return CGRect(x: CGFloat(col) * self.CELL_SIZE,
                      y: CGFloat(row) * self.CELL_SIZE,
                      width: self.CELL_SIZE,
                      height: self.CELL_SIZE)
    }
    
    func drawGrid(nbCols: Int, nbRows: Int, context c: CGContext) {
        c.saveGState()
        
        c.setStrokeColor(NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor)
        //c.setLineWidth(0.5)
        
        let path = NSBezierPath()
        
        let cellSize = Int(CELL_SIZE)
        
        for x in stride(from: 0, to: (nbCols + 1) * cellSize, by: cellSize) {
            let p1 = CGPoint(x:x, y:0)
            let p2 = CGPoint(x:x, y:Int(self.bounds.size.height))
            path.move(to: p1)
            path.line(to: p2)
        }
        
        for y in stride(from: 0, to: (nbRows + 1) * cellSize, by: cellSize) {
            let p1 = CGPoint(x:0, y:y)
            let p2 = CGPoint(x:Int(self.bounds.size.width), y:y)
            path.move(to: p1)
            path.line(to: p2)
        }
        
        path.stroke()
        
        c.restoreGState()
    }
    
    func setCellState(event: NSEvent) {
        guard let model = self.delegate?.model else {
            assertionFailure()
            return
        }
        
        let matrix = model.matrix
        
        let (col, row) = colRowForMouseEvent(event:event)
        guard let cell = matrix.optionalCell((col,row)) else {
            Swift.print("-- no cell for \(col),\(row)")
            return
        }
        
        if cell.state == self.editCellState { return }

        delegate?.model.updateCell(col: col, row: row, newState: editCellState)
        
        cell.state = self.editCellState
        
        let rect = self.rectForCell(col: col, row: row)
        
        self.setNeedsDisplay(rect)
    }
    
    override func mouseDown(with event: NSEvent) {
        Swift.print("-- mouseDown")
        
        self.delegate?.undoManager?.beginUndoGrouping()
        
        self.setCellState(event: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.setCellState(event: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        Swift.print("-- mouseUp")
        self.delegate?.undoManager?.endUndoGrouping()
    }
    
    func colRowForMouseEvent(event: NSEvent) -> (Int,Int) {
        let clickPoint = convert(event.locationInWindow, from: self.superview)
        let yOffset = self.frame.origin.y
        let p = CGPoint(x:max(clickPoint.x,0.0), y:max(clickPoint.y-yOffset,0.0))
        
        let col = Int(floor(p.x / CELL_SIZE))
        let row = Int(floor(p.y / CELL_SIZE))
        
        guard let model = self.delegate?.model else {
            assertionFailure()
            return (0,0)
        }
        
        let matrix = model.matrix
        
        return matrix.coordinatesKeptInBounds((col,row))
    }
    
    func clear() {
        
        guard let model = self.delegate?.model else {
            assertionFailure()
            return
        }
        
        model.matrix.resetAllCells()
        
        self.setNeedsDisplay(self.bounds)
    }
    
    func cellDidChange(col: Int, row: Int, oldState: CellState, newState: CellState) {
        let rect = self.rectForCell(col: col, row: row)
        self.setNeedsDisplay(rect)
    }
}

extension NSView {
    func PNGRepresentation() -> Data? {
        guard let rep = self.bitmapImageRepForCachingDisplay(in: self.bounds) else { return nil }
        self.cacheDisplay(in: self.bounds, to: rep)
        return rep.representation(using: .PNG, properties: [:])
    }
}
