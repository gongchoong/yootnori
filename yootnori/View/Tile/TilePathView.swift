//
//  TilePathView.swift
//  yootnori
//
//  Created by David Lee on 9/22/24.
//

import SwiftUI

struct TilePathView: View {
    private let tilePath: TilePath
    private let tileWidth: CGFloat
    private let tileHeight: CGFloat
    private let innerCircleHeight: CGFloat
    private let outerCircleHeight: CGFloat
    var body: some View {
        switch tilePath {
        case .top:
            Path { path in
                path.move(to: CGPoint(x: tileWidth / 2, y: 0))
                path.addLine(to: CGPoint(x: tileWidth / 2, y: (tileHeight - outerCircleHeight) / 2))
           }
           .stroke(Color.black, lineWidth: 3)
        case .left:
            Path { path in
                path.move(to: CGPoint(x: 0, y: tileHeight / 2))
                path.addLine(to: CGPoint(x: (tileWidth - outerCircleHeight) / 2, y: tileHeight / 2))
           }
           .stroke(Color.black, lineWidth: 3)
        case .right:
            Path { path in
                path.move(to: CGPoint(x: tileWidth, y: tileHeight / 2))
                path.addLine(to: CGPoint(x: outerCircleHeight + (tileWidth - outerCircleHeight) / 2, y: tileHeight / 2))
           }
           .stroke(Color.black, lineWidth: 3)
        case .bottom:
            Path { path in
                path.move(to: CGPoint(x: tileWidth / 2, y: tileHeight))
                path.addLine(to: CGPoint(x: tileWidth / 2, y: outerCircleHeight + (tileHeight - outerCircleHeight) / 2))
           }
           .stroke(Color.black, lineWidth: 3)
        case .topLeft:
            Path { path in
                let startPoint = CGPoint(x: 0, y: 0) // Start from top-left corner
                let center = CGPoint(x: tileWidth / 2, y: tileHeight / 2) // Center of the outer circle
                
                // Calculate the angle and length of the diagonal line
                let radius = outerCircleHeight / 2
                let angle = atan2(center.y, center.x) // Angle from top-left to center
                
                // Calculate where the line intersects the circle's edge
                let endPoint = CGPoint(
                    x: center.x - radius * cos(angle),
                    y: center.y - radius * sin(angle)
                )
                
                // Draw the line
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(Color.black, lineWidth: 3)
        case .topRight:
            Path { path in
                let startPoint = CGPoint(x: tileWidth, y: 0) // Start from top-right corner
                let center = CGPoint(x: tileWidth / 2, y: tileHeight / 2) // Center of outer circle
                let radius = outerCircleHeight / 2
                
                // Calculate the angle and find the point on the outer circle's edge
                let angle = atan2(center.y, tileWidth - center.x)
                let endPoint = CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y - radius * sin(angle)
                )
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(Color.black, lineWidth: 3)
        case .bottomLeft:
            Path { path in
                let startPoint = CGPoint(x: 0, y: tileHeight) // Start from bottom-left corner
                let center = CGPoint(x: tileWidth / 2, y: tileHeight / 2) // Center of outer circle
                let radius = outerCircleHeight / 2
                
                // Calculate the angle and find the point on the outer circle's edge
                let angle = atan2(tileHeight - center.y, center.x)
                let endPoint = CGPoint(
                    x: center.x - radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(Color.black, lineWidth: 3)
        case .bottomRight:
            Path { path in
                let startPoint = CGPoint(x: tileWidth, y: tileHeight) // Start from bottom-right corner
                let center = CGPoint(x: tileWidth / 2, y: tileHeight / 2) // Center of outer circle
                let radius = outerCircleHeight / 2
                
                // Calculate the angle and find the point on the outer circle's edge
                let angle = atan2(tileHeight - center.y, tileWidth - center.x)
                let endPoint = CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(Color.black, lineWidth: 3)
        }
    }
    
    init(
        tilePath: TilePath,
        tileWidth: CGFloat,
        tileHeight: CGFloat,
        innerCircleHeight: CGFloat,
        outerCircleHeight: CGFloat
    ) {
        self.tilePath = tilePath
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.innerCircleHeight = innerCircleHeight
        self.outerCircleHeight = outerCircleHeight
    }
}

#Preview {
    TilePathView(
        tilePath: .top,
        tileWidth: 100,
        tileHeight: 100,
        innerCircleHeight: 25,
        outerCircleHeight: 65
    )
}
