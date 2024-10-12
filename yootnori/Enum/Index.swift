//
//  Index.swift
//  yootnori
//
//  Created by David Lee on 10/5/24.
//

import Foundation

enum Index {
    case inner(column: Int, row: Int)
    case outer(column: Int, row: Int)
    case stage(column: Int, row: Int)
}

extension Index {
    var position: SIMD3<Float> {
        do {
            switch self {
            case .inner(let column, let row):
                return try inner(column: column, row: row)
            case .outer(let column, let row):
                return try outer(column: column, row: row)
            case .stage(column: let column, row: let row):
                return try stage(column: column, row: row)
            }
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }

    private func inner(column: Int, row: Int) throws -> SIMD3<Float> {
        guard column < 5 && row < 5 else {
            throw PositionError.innerTileOutOfRange(column, row)
        }
        return .init(x: Float(column - 2) * Dimensions.Board.tileSize * 4/5 - Dimensions.Board.tileSize * 1/2,
                         y: Float(2 - row) * Dimensions.Board.tileSize * 4/5,
                     z: 0.01)
    }

    private func outer(column: Int, row: Int) throws -> SIMD3<Float> {
        guard column < 6 && row < 6 else {
            throw PositionError.outerTileOutOfRange(column, row)
        }
        return .init(x: Float(column - Dimensions.Board.tileCount / 2) * Dimensions.Board.tileSize,
                         y: Float(Dimensions.Board.tileCount / 2 - row) * Dimensions.Board.tileSize - (Dimensions.Board.tileSize / 2),
                         z: 0.01)
    }

    private func stage(column: Int, row: Int) throws -> SIMD3<Float> {
        guard column < 1 && row < 6 else {
            throw PositionError.stageTileOutOfRange(column, row)
        }
        return .init(x: Float(column + Dimensions.Board.tileCount / 2) * Dimensions.Board.tileSize,
                         y: Float(Dimensions.Board.tileCount / 2 - row) * Dimensions.Board.tileSize - (Dimensions.Board.tileSize / 2),
                         z: 0.01)
    }
}
