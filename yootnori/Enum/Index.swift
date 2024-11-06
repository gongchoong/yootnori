//
//  Index.swift
//  yootnori
//
//  Created by David Lee on 10/5/24.
//

import Foundation

enum Index: Hashable {
    case inner(column: Int, row: Int)
    case outer(column: Int, row: Int)
}

extension Index {
    func position() throws -> SIMD3<Float> {
        switch self {
        case .inner(let column, let row):
            return try inner(column: column, row: row)
        case .outer(let column, let row):
            return try outer(column: column, row: row)
        }
    }

    private func outer(column: Int, row: Int) throws -> SIMD3<Float> {
        // @TODO: check if out of bounds values are correct
        switch column {
        case 0:
            guard row < 6 && row > -1 else {
                throw PositionError.outerTileOutOfRange(column, row)
            }
        case 1...4:
            guard row == 0 || row == 5 else {
                throw PositionError.outerTileOutOfRange(column, row)
            }
        case 5:
            guard row < 6 && row > -1 else {
                throw PositionError.outerTileOutOfRange(column, row)
            }
        default:
            throw PositionError.outerTileOutOfRange(column, row)
        }
        return .init(x: Float(column - Dimensions.Board.tileCount / 2) * Dimensions.Board.tileSize + Dimensions.Board.tileSize / 2,
                         y: Float(Dimensions.Board.tileCount / 2 - row) * Dimensions.Board.tileSize - (Dimensions.Board.tileSize / 2),
                         z: 0.01)
    }

    private func inner(column: Int, row: Int) throws -> SIMD3<Float> {
        // @TODO: check if out of bounds values are correct
        switch column {
        case 0:
            guard row == 0 || row == 4 else {
                throw PositionError.innerTileOutOfRange(column, row)
            }
        case 1:
            guard row == 1 || row == 3 else {
                throw PositionError.innerTileOutOfRange(column, row)
            }
        case 2:
            guard row == 2 else {
                throw PositionError.innerTileOutOfRange(column, row)
            }
        case 3:
            guard row == 1 || row == 3 else {
                throw PositionError.innerTileOutOfRange(column, row)
            }
        case 4:
            guard row == 0 || row == 4 else {
                throw PositionError.innerTileOutOfRange(column, row)
            }
        default:
            throw PositionError.innerTileOutOfRange(column, row)
        }

        return .init(x: Float(column - 2) * Dimensions.Board.tileSize * 4/5,
                         y: Float(2 - row) * Dimensions.Board.tileSize * 4/5,
                     z: 0.01)
    }
}
