import RealityKit

// Ensure you register this component in your app’s delegate using:
// MarkerComponent.registerComponent()

public struct MarkerComponent: Component, Codable {
    public var level: Int = 1

    public init(level: Int) {
        self.level = level
    }
}
