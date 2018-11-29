//
//  STRtree.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/11/21.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

private extension Rectangle2D {
    func extends(with bounds: Rect2D) {
        self.min = Vector2D(
            x: self.min.x < bounds.min.x ? self.min.x : bounds.min.x,
            y: self.min.y < bounds.min.y ? self.min.y : bounds.min.y
        )
        self.max = Vector2D(
            x: self.max.x > bounds.max.x ? self.max.x : bounds.max.x,
            y: self.max.y > bounds.max.y ? self.max.y : bounds.max.y
        )
    }
}

private let defaultNodeCapacity = 10

public class STRTree<T>: SpatialIndex {
    
    private var capacity: Int
    private var items: [(Rect2D, T?)] = []
    private var root: Node!
    private var built: Bool = false
    
    private class Node {
        
        private var _bounds: Rect2D?
        
        var children: [Node]
        var level: Int
        var item: T?
        
        var bounds: Rect2D {
            if let bounds = _bounds {
                return bounds
            } else {
                let bounds = computeBounds()
                _bounds = bounds
                return bounds
            }
        }
        
        var isEmpty: Bool {
            return children.count == 0
        }
        
        public init(_ level: Int) {
            self.level = level
            self.children = []
        }
        
        public convenience init(bounds: Rect2D, item: T?) {
            self.init(Int.max)
            self._bounds = bounds
            self.item = item
        }
        
        public func addChild(_ child: Node) {
            assert(_bounds == nil)
            self.children.append(child)
        }
        
        private func computeBounds() -> Rect2D {
            let bounds = Rectangle2D()
            for child in children {
                bounds.extends(with: child.bounds)
            }
            return bounds
        }
    }
    
    public var isEmpty: Bool {
        if !built {
            return items.count == 0
        }
        return root.isEmpty
    }
    
    public convenience init() {
        self.init(capacity: defaultNodeCapacity)
    }
    
    /// The minimum recommended capacity setting is 4.
    public init(capacity: Int) {
        assert(capacity > 1, "Node capacity must be greater than 1")
        self.capacity = capacity
    }
    
    public func insert(in bounds: Rect2D, item: T) {
        if bounds.isEmpty {
            return
        }
        assert(!built, "Cannot insert items into an STR packed R-tree after it has been built.")
        items.append((bounds, item))
    }
    
    public func query(in bounds: Rect2D) -> [T] {
        build()
        
        var matches = [T]()
        if isEmpty {
            return matches
        }
        
        if root.bounds.intersects(bounds) {
            queryInternal(in: bounds, node: root, matches: &matches)
        }
        
        return matches
    }
    
    private func build() {
        if built {
            return
        }
    
        if items.count == 0 {
            root = Node(0)
        } else {
            root = _build(items.map { Node(bounds: $0.0, item: $0.1) }, at: -1)
        }
        
        // the item list is no longer needed
        items = []
        built = true
    }
    
    private func _build(_ children: [Node], at level: Int) -> Node {
        assert(children.count > 0)

        let minLeafCount = ceil(Double(children.count) / Double(capacity))
        let sortedChildren = children.sorted(by: { $0.bounds.center.x < $1.bounds.center.x })
        let childrenCount = sortedChildren.count
        let sliceCount = Int(ceil(sqrt(minLeafCount)))
        let sliceCapacity = Int(ceil(Double(childrenCount) / Double(sliceCount)))
        
        var slices = [[Node]]()
        var i = 0
        for _ in 0..<sliceCount {
            var sliceChildren = [Node]()
            
            var j = 0
            while j < sliceCapacity && i < childrenCount {
                sliceChildren.append(sortedChildren[i])
                j += 1
                i += 1
            }
            
            slices.append(sliceChildren)
        }
        
        assert(slices.count > 0)
        
        var parentBoundables = [Node]()
        for slice in slices {
            assert(slice.count > 0)
            
            parentBoundables.append(Node(level + 1))
            
            // JTS does a stable sort here.  List<T>.Sort is not stable.
            let sortedSlice = slice.sorted(by: { $0.bounds.center.y < $1.bounds.center.y })
            for child in sortedSlice {
                if let last = parentBoundables.last, last.children.count == capacity {
                    parentBoundables.append(Node(level + 1))
                }
                parentBoundables.last?.addChild(child)
            }
        }
        
        if parentBoundables.count == 1 {
            return parentBoundables[0]
        }
        
        return _build(parentBoundables, at: level + 1)
    }
    
    private func queryInternal(in bounds: Rect2D, node: Node, matches: inout [T]) {
        for child in node.children {
            if !child.bounds.intersects(bounds) {
                continue
            }
    
            if let item = child.item {
                matches.append(item)
            } else {
                queryInternal(in: bounds, node: child, matches: &matches)
            }
        }
    }
 
 }

extension STRTree where T : Equatable {
    
    public func remove(bounds: Rect2D, item: T?) -> Bool {
        build()
        return root.bounds.intersects(bounds) && _remove(in: bounds, node: root, item: item)
    }
    
    private func _remove(in bounds: Rect2D, node: Node, item: T?) -> Bool {
        // first try removing item from this node
        var found = removeItem(node: node, item: item)
        if found {
            return true
        }
        
        var childIndexToPrune: Int?
        // next try removing item from lower nodes
        for (index, child) in node.children.enumerated() {
            if !child.bounds.intersects(bounds) {
                continue
            }
            
            if child.level == Int.max {
                continue
            }
            
            found = _remove(in: bounds, node: child, item: item)
            
            // if found, record child for pruning and exit
            if !found {
                continue
            }
            
            childIndexToPrune = index
            break
        }
        
        // prune child if possible
        if let index = childIndexToPrune, node.children[index].children.count == 0 {
            node.children.remove(at: index)
        }
        
        return found
    }
    
    private func removeItem(node: Node, item: T?) -> Bool {
        if let index = node.children.index(where: { $0.item == item }) {
            node.children.remove(at: index)
            return true
        }
        return false
    }
}

extension STRTree where T : AnyObject {
    
    public func remove(bounds: Rect2D, item: T?) -> Bool {
        build()
        return root.bounds.intersects(bounds) && _remove(in: bounds, node: root, item: item)
    }
    
    private func _remove(in bounds: Rect2D, node: Node, item: T?) -> Bool {
        // first try removing item from this node
        var found = removeItem(node: node, item: item)
        if found {
            return true
        }
        
        var childIndexToPrune: Int?
        // next try removing item from lower nodes
        for (index, child) in node.children.enumerated() {
            if !child.bounds.intersects(bounds) {
                continue
            }
            
            if child.level == Int.max {
                continue
            }
            
            found = _remove(in: bounds, node: child, item: item)
            
            // if found, record child for pruning and exit
            if !found {
                continue
            }
            
            childIndexToPrune = index
            break
        }
        
        // prune child if possible
        if let index = childIndexToPrune, node.children[index].children.count == 0 {
            node.children.remove(at: index)
        }
        
        return found
    }
    
    private func removeItem(node: Node, item: T?) -> Bool {
        if let index = node.children.index(where: { $0.item === item }) {
            node.children.remove(at: index)
            return true
        }
        return false
    }
}
