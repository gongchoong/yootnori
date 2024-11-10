import RealityKit

// Ensure you register this component in your app’s delegate using:
// MarkerComponent.registerComponent()

public enum IndexType: String, Codable {
    case inner
    case outer
}

public struct MarkerComponent: Component, Codable {
    public var level: Int
    public var nodeName: String

    public init(level: Int = 1, nodeName: String) {
        self.level = level
        self.nodeName = nodeName
    }
}
