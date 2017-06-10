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
    
    var stringRepresentation : String {
        var rep = ""
        
        for row in 0..<matrix.NB_ROWS {
            for col in 0..<matrix.NB_COLS {
                guard let cell = matrix.optionalCell((col: col, row: row)) else { assertionFailure(); return "" }
                rep += cell.state.rawValue
            }
            rep += "\n"
        }

        return rep
    }

    init(matrix: Matrix<Cell>) {
        self.matrix = matrix
    }
    
    init?(s:String) {
        
        let lines = s.components(separatedBy: "\n").filter { $0.characters.count > 0 }
        
        guard let firstLine = lines.first else { assertionFailure(); return nil }
        
        let NB_ROWS = lines.count
        let NB_COLS = firstLine.characters.count

        self.matrix = Matrix<Cell>(rows: NB_ROWS, columns: NB_COLS)
        
        var cells : [Cell] = []
        
        for row in 0..<NB_ROWS {
            let lineChars = lines[row].characters
            
            if lineChars.count != NB_COLS {
                print("-- expected line of \(NB_COLS) chars, found \(lineChars.count)")
                return nil
            }
            
            for c in lineChars {
                guard let state = CellState(rawValue: "\(c)") else {
                    assertionFailure("-- found unknown state: \(c)")
                    return nil
                }
                let cell = Cell(state: state)
                cells.append(cell)
            }
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
