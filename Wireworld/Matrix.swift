//
//  Matrix.swift
//  Wireworld
//
//  Created by nst on 12.05.17.
//  Copyright © 2017 Nicolas Seriot. All rights reserved.
//

import Foundation

protocol MatrixCell {
    init()
}

class Matrix<T:MatrixCell> : NSObject {
    
    let NB_ROWS : Int
    let NB_COLS : Int
    
    var cells : [T] = [] // (0,0), (1,0), (2,0) ... (0,1), (1,0), (2,0) ...
    
    init(rows: Int, columns: Int) {
        
        self.NB_ROWS = rows
        self.NB_COLS = columns
        
        for _ in 0..<(rows*columns) {
            cells.append(T())
        }
    }
    
    subscript(column: Int, row: Int) -> T {
        get {
            assert(indexIsValid(row: row, column: column), "Index out of range, [\(column),\(row)] not within [\(self.NB_COLS),\(self.NB_ROWS)]")
            return cells[(column * NB_ROWS) + row]
        }
        set {
            assert(indexIsValid(row: row, column: column), "Index out of range, [\(column),\(row)] not within [\(self.NB_COLS),\(self.NB_ROWS)]")
            cells[(column * NB_ROWS) + row] = newValue
        }
    }
    
    func indexIsValid(row: Int, column: Int) -> Bool {
        return row >= 0 && row < NB_ROWS && column >= 0 && column < NB_COLS
    }
    
    func mooreNeighborhood(col: Int, row: Int) -> [T] {
        
        let offsets = [(-1,-1),(0,-1),(1,-1),
                       (-1, 0),       (1, 0),
                       (-1, 1),(0, 1),(1, 1)]
        
        return offsets.flatMap { optionalCell(( col + $0.0, row + $0.1)) }
    }
    
    func resetAllCells() {
        self.cells.removeAll()
        for _ in 0..<(NB_ROWS*NB_COLS) {
            cells.append(T())
        }
    }
    
    func optionalCell(_ coordinates:(col:Int, row:Int)) -> T? {
        guard coordinates.col >= 0 else { return nil }
        guard coordinates.row >= 0 else { return nil }
        guard coordinates.col <= NB_COLS-1 else { return nil }
        guard coordinates.row <= NB_ROWS-1 else { return nil }
        return self[coordinates.col,coordinates.row]
    }
    
    func coordinatesKeptInBounds(_ coordinates:(col:Int, row:Int)) -> (col:Int, row:Int) {
        let newCol = min(coordinates.col, NB_COLS-1)
        let newRow = min(coordinates.row, NB_ROWS-1)
        return (newCol, newRow)
    }
}
