import RealityKit

// Ensure you register this component in your app’s delegate using:
// MarkerComponent.registerComponent()

//public enum Index: Hashable, Codable {
//    case inner(column: Int, row: Int)
//    case outer(column: Int, row: Int)
//}

public enum IndexType: String, Codable {
    case inner
    case outer
}

public struct MarkerComponent: Component, Codable {
    public let indexType: IndexType
    public var column: Int = 0
    public var row: Int = 0

    public init(indexType: IndexType, col: Int, row: Int) {
        self.indexType = indexType
        self.column = col
        self.row = row
    }
}
