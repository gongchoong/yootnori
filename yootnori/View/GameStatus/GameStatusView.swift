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
                    playerName: player.name,
                    rollResult: model.rollResult,
                    hasRemainingRoll: model.hasRemainingRoll,
                    isLoading: model.isLoading
                    )
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
    @EnvironmentObject var model: AppModel
    var playerName: String
    var rollResult: [Yoot]
    var hasRemainingRoll: Bool
    var isLoading: Bool
    let onMarkerTapped: () -> Void

    var totalSteps: String {
        rollResult.map { "\($0.steps)" }.joined(separator: ",")
    }

    var canPlaceNewMarker: Bool {
        !hasRemainingRoll || isLoading
    }

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("Player A")
                .font(.system(size: 50, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundColor(.primary)
            
            Text("\(totalSteps) steps")
                .font(.system(size: 40))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundColor(.secondary)
            
            Button(action: onMarkerTapped) {
                Text("New Marker")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .disabled(canPlaceNewMarker)
        }
    }
}
