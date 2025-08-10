//
//  MarkerManager.swift
//  yootnori
//
//  Created by David Lee on 7/28/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

@MainActor
protocol MarkerManagerProtocol {
    func didTapPromotedMarkerLevel(marker: Entity)
}

@MainActor
class MarkerManager: ObservableObject {
        // MARK: - Error Types
    enum MarkerError: Error {
        case markerComponentMissing(entity: Entity)
        case nodeMissing(entity: Entity)
        case playerNotFound(entity: Entity)
        case creationFailed(String)
        case movementFailed(String)
        case routeDoesNotExist(from: Node, to: Node)
    }

    private var trackedMarkers: [Player: [Node: Entity]] = [:] {
        didSet {
            print("//////////////////////")
            let _ = trackedMarkers.map { (key, value) in
                value.map { (valueKey, valueValue) in
                    print("\(key.team.name): \(valueKey.name): \(valueValue.name)")
                }
            }
        }
    }

    private let rootEntity: Entity
    let attachmentsProvider: AttachmentsProvider = AttachmentsProvider()
    var delegate: MarkerManagerProtocol? = nil

    init(rootEntity: Entity) {
        self.rootEntity = rootEntity
    }

    func create(at node: Node, for player: Player) async throws -> Entity {
        do {
            let position = try node.index.position()
            let entity = try await Entity(named: player.markerName, in: RealityKitContent.realityKitContentBundle)
            entity.position = position
            entity.components.set([
                CollisionComponent(shapes: [{
                    .generateBox(size: entity.visualBounds(relativeTo: nil).extents)
                }()]),
                InputTargetComponent(),
                MarkerComponent(level: 1, team: player.team.rawValue)
            ])
            rootEntity.addChild(entity)
            return entity
        } catch {
            fatalError("Failed to create a new marker at \(node.index)")
        }
    }

    @discardableResult
    func move(_ marker: Entity, to destinationNode: Node, using gameEngine: GameEngine) async throws -> Bool {
        var didScore = false
        let currentNode = findNode(for: marker) ?? .bottomRightVertex
        guard let route = gameEngine.findRoute(from: currentNode, to: destinationNode, startingPoint: currentNode) else {
            throw MarkerError.routeDoesNotExist(from: currentNode, to: destinationNode)
        }
        let filteredRoute = route.filter { $0.name != currentNode.name }

        for routeNode in filteredRoute {
            try await stepMarker(marker, to: routeNode)
            if routeNode.name == .bottomRightVertex {
                didScore = true
                break
            }
        }
        return didScore
    }

    func piggyBack(rider: Entity, carrier: Entity) async throws {
        try addLevel(to: carrier, from: rider)
        rootEntity.removeChild(rider)
    }

    func capture(capturing: Entity, captured: Entity) async {
        rootEntity.removeChild(captured)

        if let capturedPlayer = player(for: captured),
           let capturedNode = findNode(for: captured, player: capturedPlayer) {
            detachMarker(from: capturedNode, player: capturedPlayer)
        }
    }

    func handleScore(marker: Entity, player: Player) throws {
        guard let startingNode = findNode(for: marker, player: player) else {
            throw MarkerError.nodeMissing(entity: marker)
        }
        guard let scoredMarkerComponent = marker.components[MarkerComponent.self] else {
            throw MarkerError.markerComponentMissing(entity: marker)
        }
        player.score -= scoredMarkerComponent.level
        detachMarker(from: startingNode, player: player)
        detachMarker(from: .bottomRightVertex, player: player)
        rootEntity.removeChild(marker)
    }

    func markerCount(for player: Player) -> Int {
        trackedMarkers[player]?.values.reduce(into: 0) { count, marker in
            guard let level = marker.components[MarkerComponent.self]?.level else {
                fatalError()
            }
            count += level
        } ?? 0
    }
}

// MARK: - Animation Helpers
extension MarkerManager {
    /// Elevates a marker upward for a visual highlight effect (e.g., when selected).
    /// - Parameters:
    ///   - marker: The entity to elevate.
    ///   - duration: The duration of the elevation animation.
    func elevate(entity marker: Entity, duration: CGFloat = 0.6) async {
        do {
            var translation = marker.position
            translation.z = Dimensions.Marker.elevated
            marker.move(to: .init(translation: translation),
                                 relativeTo: self.rootEntity,
                                 duration: duration)
            try? await Task.sleep(for: .seconds(duration))
        }
    }

    /// Drops a marker back to its resting Z-position after elevation or movement.
    /// - Parameters:
    ///   - marker: The marker entity to drop.
    ///   - duration: The duration of the drop animation.
    func drop(_ marker: Entity, duration: CGFloat = 0.6) async {
        var translation = marker.position
        translation.z = Dimensions.Marker.dropped
        marker.move(
            to: .init(translation: translation),
            relativeTo: rootEntity,
            duration: duration
        )
        try? await Task.sleep(for: .seconds(duration))
    }

    /// Animates a marker step-by-step along a path by moving and then dropping it.
    /// - Parameters:
    ///   - marker: The marker entity to move.
    ///   - node: The target node the marker is stepping to.
    private func stepMarker(_ marker: Entity, to node: Node) async throws {
        let newPosition = try node.index.position()
        var translation = newPosition
        translation.z = Dimensions.Marker.elevated

        marker.move(
            to: .init(translation: translation),
            relativeTo: rootEntity,
            duration: Dimensions.Marker.duration
        )

        try? await Task.sleep(for: .seconds(Dimensions.Marker.duration))
        await drop(marker, duration: Dimensions.Marker.duration)
    }
}

// MARK: - Private helpers
extension MarkerManager {
    private func addLevel(to carrier: Entity, from rider: Entity) throws {
        guard var carrierComponent = carrier.components[MarkerComponent.self] else {
            throw MarkerError.markerComponentMissing(entity: carrier)
        }
        guard let riderComponent = rider.components[MarkerComponent.self] else {
            throw MarkerError.markerComponentMissing(entity: rider)
        }
        let newLevel = carrierComponent.level + riderComponent.level
        carrierComponent.level = newLevel
        carrier.components[MarkerComponent.self] = carrierComponent
        attachmentsProvider.attachments[carrier.id] = AnyView(MarkerLevelView(tapAction: {
            self.delegate?.didTapPromotedMarkerLevel(marker: carrier)
        }, level: newLevel, team: Team(rawValue: carrierComponent.team) ?? .black))
    }
}

// MARK: - Marker handling
extension MarkerManager {
    func assign(marker: Entity, to node: Node, player: Player) {
        trackedMarkers[player, default: [:]][node] = marker
    }

    func reassign(_ marker: Entity, to node: Node, player: Player) {
        guard let previous = trackedMarkers[player]?.first(where: { $0.value == marker })?.key else { return }
        trackedMarkers[player]?[previous] = nil
        trackedMarkers[player]?[node] = marker
    }

    func detachMarker(from node: Node, player: Player) {
        print("detaching \(player.team)'s marker from \(node.name)")
        trackedMarkers[player]?[node] = nil
    }

    func findNode(for marker: Entity, player: Player) -> Node? {
        return trackedMarkers[player]?.first(where: { $0.value == marker })?.key
    }

    /// For lookup across *all* players (if player is not known)
    func findNode(for marker: Entity) -> Node? {
        for (_, dict) in trackedMarkers {
            if let node = dict.first(where: { $0.value == marker })?.key {
                return node
            }
        }
        return nil
    }

    /// For lookup across *all* players (if player is not known)
    func findMarker(for node: Node) -> Entity? {
        for (_, dict) in trackedMarkers {
            if let marker = dict.first(where: { $0.key == node })?.value {
                return marker
            }
        }
        return nil
    }

    func player(for marker: Entity) -> Player? {
        for (player, markers) in trackedMarkers {
            if markers.values.contains(marker) {
                return player
            }
        }
        return nil
    }

    subscript(player: Player, node: Node) -> Entity? {
        get { trackedMarkers[player]?[node] }
        set { trackedMarkers[player]?[node] = newValue }
    }
}
