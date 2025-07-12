import RealityKit

// Ensure you register this component in your app’s delegate using:
// MarkerComponent.registerComponent()

public struct MarkerComponent: Component, Codable {
    public var level: Int = 1
    public var team: Int = 0

    public init(level: Int, team: Int) {
        self.level = level
        self.team = team
    }
}
