//
//  GameEngine.swift
//  yootnori
//
//  Created by David Lee on 7/26/25.
//
import RealityKit
import Combine

enum GameEngineError: Error {
    case nodeMissing(NodeName)
}

class GameEngine {
    @Published var targetNodes: Set<TargetNode> = []
    private var nodes = Set<Node>()

    init() {
        generateNodes()
    }

    private func generateNodes() {
        nodes = Set(NodeConfig.nodeNames.map { name in
            guard let index = NodeConfig.nodeIndexMap[name], let relationShip = NodeConfig.nodeRelationships[name] else {
                return Node(name: .empty, index: Index.outer(column: 0, row: 0), next: [], prev: [])
            }
            return Node(name: name, index: index, next: relationShip.next, prev: relationShip.prev)
        })
    }
}

// MARK: - Node Lookup
extension GameEngine {
    /// Finds a node by its name
    /// - Parameter nodeName: The name of the node to find
    /// - Returns: The node if found, nil otherwise
    func findNode(named nodeName: NodeName) -> Node? {
        nodes.filter { $0.name == nodeName }.first
    }

    /// Returns the next node names from a given node
    /// - Parameter nodeName: The current node name
    /// - Returns: Array of next node names
    func nextNodeNames(from nodeName: NodeName) -> [NodeName] {
        nodes.filter { $0.name == nodeName }.first?.next ?? []
    }

    /// Returns the previous node names from a given node
    /// - Parameter nodeName: The current node name
    /// - Returns: Array of previous node names
    func previousNodeNames(from nodeName: NodeName) -> [NodeName] {
        nodes.filter { $0.name == nodeName }.first?.prev ?? []
    }
}

// MARK: - Target Node Calculation
extension GameEngine {
    /// Calculates all possible target nodes based on yoot roll results
    /// - Parameter starting: The starting node name (default: bottomRightVertex)
    /// - Parameter rolls: Array of yoot roll results
    /// - Returns: Set of target nodes that can be reached
    func calculateTargetNodes(starting: NodeName?, for rolls: [Yoot]) -> Set<TargetNode> {
        var targetNodes = Set<TargetNode>()

        // Sort the rolls in descending order
        // For markers that can score, use the smallest roll that can score the marker.
        let orderedRolls = rolls.sorted { $0.rawValue < $1.rawValue }

        let next: NodeName = {
            guard let starting else {
                return .bottomRightVertex
            }
            return starting
        }()

        for roll in orderedRolls {
            calculateReachableNodes(
                starting: starting,
                next: next,
                yootRoll: roll,
                remainingSteps: roll.steps,
                destination: &targetNodes
            )
        }

        return targetNodes
    }
    
    /// Recursively calculates reachable nodes for a specific yoot roll
    private func calculateReachableNodes(
        starting: NodeName?,
        next: NodeName,
        yootRoll: Yoot,
        remainingSteps: Int,
        destination: inout Set<TargetNode>
    ) {
        // Marker cannot move past the starting node
        // Display a score button
        if starting != nil, next == .bottomRightVertex, remainingSteps > 0 {
            destination.insert(TargetNode(name: .bottomRightVertex, yootRoll: yootRoll, canScore: true))
            return
        }

        // Marker is sitting on the starting node.
        // Display a starting button
        if starting == .bottomRightVertex, remainingSteps > 0 {
            destination.insert(TargetNode(name: .bottomRightVertex, yootRoll: yootRoll, canScore: true))
            return
        }

        guard remainingSteps > 0 else {
            destination.insert(TargetNode(name: next, yootRoll: yootRoll))
            return
        }

        var nextNodes = nextNodeNames(from: next)
        applyMovementFilters(nextNodes: &nextNodes, starting: starting)

        guard !nextNodes.isEmpty else { return }

        for nextNode in nextNodes {
            calculateReachableNodes(
                starting: starting,
                next: nextNode,
                yootRoll: yootRoll,
                remainingSteps: remainingSteps - 1,
                destination: &destination
            )
        }
    }

    /// Applies movement rules to filter valid next nodes
    private func applyMovementFilters(nextNodes: inout [NodeName], starting: NodeName?) {
        guard let starting else { return }
        // Inner nodes can only be reached if starting node is topRightVertex, topLeftVertex, or inner node
        nextNodes = nextNodes.filter { node in
            node.isInnerNode ? (starting.isInnerNode || starting == .topRightVertex || starting == .topLeftVertex) : true
        }

        // If starting node is topRightVertex or topLeftVertex, marker can only travel towards inner nodes
        nextNodes = nextNodes.filter { node in
            starting.isTopVertexNode ? node.isInnerNode : true
        }

        // If starting node is topRightVertex or topRightDiagonals, marker cannot travel towards bottomRightDiagonal nodes
        nextNodes = nextNodes.filter { node in
            (starting == .topRightVertex || starting.isTopRightDiagonalNode) ? !node.isBottomRightDiagonalNode : true
        }

        // If starting node is topLeftVertex or topLeftDiagonals, marker cannot travel towards bottomLeftDiagonal nodes
        nextNodes = nextNodes.filter { node in
            (starting == .topLeftVertex || starting.isTopLeftDiagonalNode) ? !node.isBottomLeftDiagonalNode : true
        }

        // If starting node is center, marker cannot travel towards bottomLeftDiagonal nodes
        nextNodes = nextNodes.filter { node in
            starting == .center ? !node.isBottomLeftDiagonalNode : true
        }
    }
}

    // MARK: - Pathfinding
extension GameEngine {
    /// Finds a route from start node to destination node
    /// - Parameters:
    ///   - start: The starting node
    ///   - destination: The destination node
    ///   - startingPoint: The original starting point for route rules
    ///   - visited: Set of visited nodes to prevent cycles
    /// - Returns: Array of nodes representing the path, or nil if no path exists
    func findRoute(
        from start: Node,
        to destination: Node,
        startingPoint: Node,
        visited: Set<Node> = []
    ) -> [Node]? {
        // Prevent infinite loops
        guard !visited.contains(start) else { return nil }

        var newVisited = visited
        newVisited.insert(start)

        // Found destination
        if start == destination {
            return [start]
        }

        // Get valid next steps based on game rules
        let nextSteps = getValidNextNodes(for: start, startingFrom: startingPoint)

        // Recursively explore each next node
        for nextNodeName in nextSteps {
            guard let nextNode = findNode(named: nextNodeName) else { continue }

            if let path = findRoute(
                from: nextNode,
                to: destination,
                startingPoint: startingPoint,
                visited: newVisited
            ) {
                return [start] + path
            }
        }

        return nil
    }

    /// Gets valid next nodes considering special routing rules
    /// - Parameters:
    ///   - node: Current node
    ///   - origin: Original starting node
    /// - Returns: Array of valid next node names
    private func getValidNextNodes(for node: Node, startingFrom origin: Node) -> [NodeName] {
        // Special routing logic for center node
        if node.name == .center {
            if [.topRightVertex, .rightTopDiagonal1, .rightTopDiagonal2].contains(origin.name) {
                return [.leftBottomDiagonal1]
            }
            if [.topLeftVertex, .leftTopDiagonal1, .leftTopDiagonal2].contains(origin.name) {
                return [.rightBottomDiagonal1]
            }
        }
        return node.next
    }
}

// MARK: - Target Nodes
extension GameEngine {
    func updateTargetNodes(starting: NodeName? = nil, for rolls: [Yoot]) {
        clearAllTargetNodes()
        targetNodes = calculateTargetNodes(starting: starting, for: rolls)
    }

    // For markers in scoring position
    // e.g. Marker position = .bottomNode4, rolls = .yoot, .gae
    // Use the smallest roll (.gae) for scoring.
    func getTargetNode(nodeName: NodeName) -> TargetNode? {
        let filteredTargetNodes = targetNodes.filter({ $0.name == nodeName })
        let min = filteredTargetNodes.min(by: { $0.yootRoll.rawValue > $1.yootRoll.rawValue })
        return min
    }

    func clearAllTargetNodes() {
        self.targetNodes.removeAll()
    }
}
