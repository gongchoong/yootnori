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
        HStack(alignment: .center, spacing: 50) {
            ForEach(players, id: \.self) { player in
                PlayerStatusView(
                    player: player,
                    rollResult: model.result,
                    isOutOfThrows: false,
                    isLoading: model.gameState == .animating,
                    currentTurn: model.currentTurn,
                    markersLeftToPlace: model.remainingMarkerCount(for: player))
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

    var newMarkerAvailable: Bool {
        isPlayerTurn && hasMarkersLeftToPlace && !rollResult.isEmpty
    }

    var hasMarkersLeftToPlace: Bool {
        markersLeftToPlace > 0
    }

    private var teamTextColor: Color {
        .primary
    }

    private var teamMarkerColor: Color {
        player.team == .black ? .black : .white
    }

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text(player.team.name)
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(teamTextColor)
                .frame(maxWidth: .infinity)

            NewMarkerButton(
                count: markersLeftToPlace,
                color: teamMarkerColor,
                isPlayerTurn: isPlayerTurn,
                isEnabled: !newMarkerButtonDisabled,
                isHighlighted: newMarkerAvailable,
                action: onMarkerTapped
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(isPlayerTurn ? Color.yellow.opacity(0.3) : Color(.systemBackground))
                .shadow(color: isPlayerTurn ? Color.yellow.opacity(0.5) : .clear, radius: 20)
        )
        .animation(.easeInOut(duration: 0.5), value: isPlayerTurn)
    }
}

struct NewMarkerButton: View {
    let count: Int
    let color: Color
    let isPlayerTurn: Bool
    let isEnabled: Bool
    let isHighlighted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "cylinder.fill")
                    .foregroundStyle(color)
                    .font(.system(size: 40, weight: .medium))

                Text("x\(count)")
                    .font(.system(size: 40, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(isHighlighted ? Color.yellow.opacity(0.8) : Color(.systemBackground))
        )
        .opacity(isPlayerTurn ? 1 : 0.2)
        .disabled(!isEnabled)
    }
}
