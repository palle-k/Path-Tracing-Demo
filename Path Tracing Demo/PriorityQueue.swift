//
//  PriorityQueue.swift
//  Path Tracing Demo
//
//  Created by Palle Klewitz on 16.08.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Foundation

class PriorityQueue<Priority: Comparable, Element>
{
	private var roots:[PriorizedNode<Priority, Element>] = []
	
	final func append(element: Element, withPriority priority: Priority)
	{
		roots.append(PriorizedNode<Priority, Element>(priority: priority, element: element))
		
		cleanup()
	}
	
	final func append(contentsOf collection: Array<(Priority, Element)>)
	{
		roots.append(contentsOf: collection.map{PriorizedNode<Priority, Element>(priority: $0.0, element: $0.1)})
		
		cleanup()
	}
	
	private func cleanup()
	{
		let maxRank = roots.map{$0.depth}.max() ?? 0
		var rankedRoots = [[PriorizedNode<Priority, Element>]](repeating: [], count: maxRank + 1)
		for root in roots
		{
			rankedRoots[root.depth].append(root)
		}
		var i = 0
		while i < rankedRoots.count
		{
			while rankedRoots[i].count >= 2
			{
				let node1 = rankedRoots[i].removeLast()
				let node2 = rankedRoots[i].removeLast()
				let merged = merge(node1, with: node2)
				if rankedRoots.count > i + 1
				{
					rankedRoots[i + 1].append(merged)
				}
				else
				{
					rankedRoots.append([merged])
				}
			}
			i += 1
		}
		roots = rankedRoots.flatMap{$0}.sorted(by: {$0.priority < $1.priority})
	}
	
	private final func merge(_ node1: PriorizedNode<Priority, Element>, with node2: PriorizedNode<Priority, Element>) -> PriorizedNode<Priority, Element>
	{
		if node1.priority <= node2.priority
		{
			node1.children.append(node2)
			node1.depth = max(node1.depth, node2.depth + 1)
			return node1
		}
		else
		{
			node2.children.append(node1)
			node2.depth = max(node2.depth, node1.depth + 1)
			return node2
		}
	}
	
	var min: Element!
	{
		return roots.first?.element
	}
	
	var isEmpty: Bool
	{
		return roots.isEmpty
	}
	
	final func removeMin() -> Element?
	{
		guard roots.count > 0 else { return nil }
		let minNode = roots.first!
		
		roots.remove(at: 0)
		roots.append(contentsOf: minNode.children)
		
		cleanup()
		
		return minNode.element
	}
}

private class PriorizedNode<Priority: Comparable, Element>
{
	var element: Element
	var priority: Priority
	
	weak var parent: PriorizedNode<Priority, Element>?
	var children:[PriorizedNode<Priority, Element>]
	
	var depth: Int
	
	init(priority: Priority, element: Element)
	{
		self.element = element
		self.priority = priority
		self.children = []
		depth = 0
	}
	
	private final func siftUp()
	{
		while let parent = self.parent, parent.priority > self.priority
		{
			let children = self.children
			self.children = parent.children
			
			self.children.remove(at: self.children.index(where: {$0 === self})!)
			self.children.append(parent)
			
			parent.children = children
			
			self.parent = parent.parent
			parent.parent = self
			
			let depth = parent.depth
			parent.depth = self.depth
			self.depth = depth
		}
	}
	
	static func merge<Priority, Element>(_ node1: PriorizedNode<Priority, Element>, with node2: PriorizedNode<Priority, Element>) -> PriorizedNode<Priority, Element>
	{
		if node1.priority <= node2.priority
		{
			node1.children.append(node2)
			node1.depth = max(node1.depth, node2.depth + 1)
			return node1
		}
		else
		{
			node2.children.append(node1)
			node2.depth = max(node2.depth, node1.depth + 1)
			return node2
		}
	}
}

