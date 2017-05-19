//
//  Model.swift
//  Wireworld
//
//  Created by nst on 13.05.17.
//  Copyright © 2017 Nicolas Seriot. All rights reserved.
//

import Foundation

protocol ModelDelegate {
    var undoManager : UndoManager? { get set }
    func cellDidChange(col: Int, row: Int, oldState: CellState, newState: CellState)
    func matrixDidChange()
}

class Model: NSObject {
    
    var matrix : Matrix<Cell>

    var delegate: ModelDelegate?
    
    class func defaultModel() -> Model {
        let matrix = Matrix<Cell>(rows: 30, columns: 40)
        return Model(matrix: matrix)
    }
    
    var dictionaryRepresentation : [String:Any] {
        var d : [String:Any] = [:]
        d["NB_COLS"] = matrix.NB_COLS
        d["NB_ROWS"] = matrix.NB_ROWS
        
        var cells : [String] = []
        
        for c in matrix.cells {
            let s = c.state.rawValue
            cells.append(s)
        }

        d["CELLS"] = cells
        
        return d
    }

    init(matrix: Matrix<Cell>) {
        self.matrix = matrix
    }
    
    init?(d:[String:Any]) {
        
        guard let NB_COLS = d["NB_COLS"] as? Int else { assertionFailure(); return nil }
        guard let NB_ROWS = d["NB_ROWS"] as? Int else { assertionFailure(); return nil }
        self.matrix = Matrix<Cell>(rows: NB_ROWS, columns: NB_COLS)
        
        guard let CELLS = d["CELLS"] as? [String] else { assertionFailure(); return nil }
        
        var cells : [Cell] = []
        
        for s in CELLS {
            guard let state = CellState(rawValue: s) else { assertionFailure(); break }
            let cell = Cell(state: state)
            cells.append(cell)
        }
        
        self.matrix.cells = cells
        
    }
    
    func updateCell(col: Int, row: Int, newState: CellState) {
        let oldState = matrix[col,row].state
        matrix[col,row].state = newState
        delegate?.cellDidChange(col: col, row: row, oldState: oldState, newState: newState)
        
        self.delegate?.undoManager?.registerUndo(withTarget: self, handler: { (model) in
            model.updateCell(col: col, row: row, newState: oldState)
        })
    }
    
    func step() {
        
        // fill futureState if needed
        
        delegate?.undoManager?.beginUndoGrouping()

        for col in 0..<matrix.NB_COLS {
            for row in 0..<matrix.NB_ROWS {
                
                let cell = matrix[col,row]
                
                switch cell.state {
                case .empty:
                    continue
                case .head:
                    cell.futureState = .tail
                case .tail:
                    cell.futureState = .wire
                case .wire:
                    let n = self.numberOfNeighbouringHeads(col: col, row: row)
                    if n == 1 || n == 2 {
                        cell.futureState = .head
                    }
                }
            }
        }
        
        // futureState becomes state, ask to draw if needed
        
        for col in 0..<matrix.NB_COLS {
            for row in 0..<matrix.NB_ROWS {
                
                let cell = matrix[col,row]
                
                guard let futureState = cell.futureState else { continue }
                
                if cell.state != futureState {
                    self.updateCell(col: col, row: row, newState: futureState)
                }
                
                cell.futureState = nil
            }
        }

        delegate?.undoManager?.endUndoGrouping()
    }
    
    func numberOfNeighbouringHeads(col: Int, row: Int) -> Int {
        
        let neighbours = matrix.mooreNeighborhood(col: col, row: row)
        
        let heads = neighbours.filter { $0.state == .head }

        return heads.count
    }
    
    func clearMatrix() {
        
        var newCells = Array<Cell>()
        for _ in 0..<(matrix.NB_ROWS*matrix.NB_COLS) {
            newCells.append(Cell())
        }
        
        self.setMatrixCells(cells: newCells)
    }

    func setMatrixCells(cells: [Cell]) {
        let oldCells = matrix.cells
        self.matrix.cells = cells
        
        self.delegate?.undoManager?.registerUndo(withTarget: self, handler: { (model) in
            model.setMatrixCells(cells: oldCells)
            model.delegate?.matrixDidChange()
        })
    }
    
}
