//
//  GameStatusView.swift
//  yootnori
//
//  Created by David Lee on 6/28/25.
//
import SwiftUI

struct GameStatusView: View {
    var players: [Player]
    @EnvironmentObject var model: AppModel
    var markerButtonTapped: (() -> Void)

    var body: some View {
        VStack(alignment: .center, spacing: 50) {
            ForEach(players, id: \.self) { player in
                PlayerStatusView(
                    player: player,
                    rollResult: [],
                    isOutOfThrows: false,
                    isLoading: model.gameState == .animating,
                    currentTurn: model.currentTurn,
                    markersLeftToPlace: model.availableMarkerCount(for: player))
                {
                    markerButtonTapped()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .glassBackgroundEffect()
    }
}

struct PlayerStatusView: View {
    var player: Player
    var rollResult: [Yoot]
    var isOutOfThrows: Bool
    var isLoading: Bool
    var currentTurn: Player
    var markersLeftToPlace: Int
    let onMarkerTapped: () -> Void

    var description: String {
        rollResult.map { "\($0.steps)" }.joined(separator: ",") + "steps"
    }

    var newMarkerButtonDisabled: Bool {
        isOutOfThrows || isLoading || !hasMarkersLeftToPlace
    }

    var isPlayerTurn: Bool {
        player.team == currentTurn.team
    }

    var hasMarkersLeftToPlace: Bool {
        markersLeftToPlace > 0
    }

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text(player.team.name)
                .font(.system(size: 50, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.system(size: 40))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundColor(.secondary)
            
            Button(action: onMarkerTapped) {
                Text("New Marker \(markersLeftToPlace)")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .opacity(isPlayerTurn ? 1 : 0.2)
            .disabled(newMarkerButtonDisabled)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(isPlayerTurn ? Color.yellow.opacity(0.3) : Color(.systemBackground))
                .shadow(color: isPlayerTurn ? Color.yellow.opacity(0.5) : .clear, radius: 20, x: 0, y: 0)
        )
        .animation(.easeInOut(duration: 0.5), value: isPlayerTurn)
    }
}
