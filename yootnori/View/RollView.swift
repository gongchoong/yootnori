//
//  RollView.swift
//  yootnori
//
//  Created by David Lee on 1/20/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct RollView: View {
    var body: some View {
        RealityView { content in
            guard let floor = try? await Entity(named: "box", in: RealityKitContent.realityKitContentBundle) else {
                return
            }
            
            floor.position = SIMD3(x: 0, y: 0, z: 0)
            content.add(floor)
            
            guard let yoot = try? await Entity(named: "yoot", in: RealityKitContent.realityKitContentBundle) else {
                return
            }
            
            yoot.position = SIMD3(x: 0, y: 0, z: 0)
            content.add(yoot)
            
//            if let yootModelEntity = try? await Entity(named: "yoot", in: RealityKitContent.realityKitContentBundle) as? ModelEntity, let meshResouce = yootModelEntity.model?.mesh {
//
//                do {
//                    let convexShape = try await ShapeResource.generateConvex(from: meshResouce)
//                    yootModelEntity.components.set(CollisionComponent(
//                                shapes: [convexShape],
//                                mode: .default
//                            ))
//
//                    print("successfully set collision component")
//                } catch {
//                    print("convex collision compnent error")
//                }
//            }
        }
    }
}

#Preview {
    RollView()
}
