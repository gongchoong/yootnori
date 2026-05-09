//
//  SharePlayManagerProtocol.swift
//  yootnori
//
//  Created by davidlee on 5/9/26.
//

import Foundation

protocol SharePlayManagerProtocol {
    func startSharePlay()
    func configureGroupSessions()
    func sendMessage(_ message: GroupMessage)
    var delegate: SharePlayManagerDelegate? { get set }
//    var sharePlayMessenger: GroupSessionMessenger? { get }
}

protocol SharePlayManagerDelegate: AnyObject {
    /// Notifies the delegate that player identities have been assigned.
    /// - Parameters:
    ///   - participantIDs: Ordered list of all participant IDs.
    ///   - localParticipantID: The local participant’s ID.
    func sharePlayManager(didAssignPlayersWith participantIDs: [UUID], localParticipantID: UUID) async throws

    /// Notifies the delegate of a debug roll result for testing.
    /// - Parameters:
    ///   - result: The debug-generated `Yoot` roll result.
    ///   - snapshot: The corresponding game state.
    func sharePlayManager(didReceiveDebugRollResult result: Yoot, snapshot: GameStateSnapshot) async throws

    /// Notifies the delegate of a buffer frame result.
    /// - Parameters:
    ///   - bufferFrame: The resolved throw frames.
    ///   - result: The resulting `Yoot`.
    ///   - snapshot: The updated game state.
    func sharePlayManager(didReceiveBufferFrame bufferFrame: [ThrowFrame], result: Yoot, snapshot: GameStateSnapshot) async throws

    /// Notifies the delegate to start the game.
    /// - Parameter snapshot: The initial game state.
    func sharePlayManagerDidInitiateGameStart(snapshot: GameStateSnapshot) async throws

    /// Notifies the delegate that the "New Marker" button was tapped.
    /// - Parameter snapshot: The game state at the time.
    func sharePlayManagerDidTapNewMarkerButton(snapshot: GameStateSnapshot) async throws

    /// Notifies the delegate that a tile was tapped.
    /// - Parameters:
    ///   - tile: The tapped tile.
    ///   - snapshot: The current game state.
    func sharePlayManager(didTapTile tile: Tile, snapshot: GameStateSnapshot) async throws

    /// Notifies the delegate that a marker node was tapped.
    /// - Parameters:
    ///   - node: The tapped node.
    ///   - snapshot: The current game state.
    func sharePlayManager(didTapMarker node: Node, snapshot: GameStateSnapshot) async throws

    /// Notifies the delegate that the score area was tapped.
    /// - Parameter snapshot: The current game state.
    func sharePlayManagerDidTapScore(snapshot: GameStateSnapshot) async throws
}
