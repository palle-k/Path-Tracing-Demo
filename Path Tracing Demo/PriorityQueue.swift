//
//  PriorityQueue.swift
//  Path Tracing Demo
//
//  Created by Palle Klewitz on 16.08.16.
//  Copyright © 2016 Palle Klewitz.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished
//  to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

public struct BinomialHeapHandle
{
	fileprivate init()
	{
		handle = (UInt64(arc4random()) << 32) | UInt64(arc4random())
	}
	
	fileprivate let handle: UInt64
}

extension BinomialHeapHandle: Equatable {}

public func == (left: BinomialHeapHandle, right: BinomialHeapHandle) -> Bool
{
	return left.handle == right.handle
}

extension BinomialHeapHandle: Hashable
{
	public var hashValue: Int
	{
		return handle.hashValue
	}
}

public class BinomialHeap<Priority: Comparable, Element>
{
	fileprivate var roots:[BinomialHeapNode<Priority, Element>] = []
	private var handles:[UInt64: BinomialHeapNode<Priority, Element>] = [:]
	
	public private(set) var count: Int = 0
	
	public init()
	{
		
	}
	
	public func append(element: Element, withPriority priority: Priority) -> BinomialHeapHandle
	{
		let node = BinomialHeapNode<Priority, Element>(priority: priority, element: element)
		roots.append(node)
		cleanup()
		count += 1
		
		let handle = BinomialHeapHandle()
		handles[handle.handle] = node
		return handle
	}
	
	public func append(contentsOf collection: Array<(Priority, Element)>) -> [BinomialHeapHandle]
	{
		let nodes = collection.map{BinomialHeapNode<Priority, Element>(priority: $0.0, element: $0.1)}
		roots.append(contentsOf: nodes)
		cleanup()
		count += collection.count
		
		var handles = (0 ..< collection.count).map{_ in BinomialHeapHandle()}
		
		for i in 0 ..< collection.count
		{
			while self.handles[handles[i].handle] != nil
			{
				handles[i] = BinomialHeapHandle()
			}
			
			self.handles[handles[i].handle] = nodes[i]
		}
		
		return handles
	}
	
	public func append(contentsOf priorityQueue: BinomialHeap<Priority, Element>)
	{
		roots.append(contentsOf: priorityQueue.roots)
		cleanup()
		count += priorityQueue.count
		for (handle, element) in priorityQueue.handles
		{
			handles[handle] = element
		}
	}
	
	public func decreasePriority(of handle: BinomialHeapHandle, to newPriority: Priority) -> Bool
	{
		guard let node = handles[handle.handle], node.priority >= newPriority else { return false }
		
		node.priority = newPriority
		node.siftUp()
		
		return true
	}
	
	public func priority(of handle: BinomialHeapHandle) -> Priority?
	{
		return handles[handle.handle]?.priority
	}
	
	public func contains(_ handle: BinomialHeapHandle) -> Bool
	{
		return handles[handle.handle] != nil
	}
	
	public func element(`for` handle: BinomialHeapHandle) -> Element?
	{
		return handles[handle.handle]?.element
	}
	
	private func cleanup()
	{
		let maxRank = roots.map{$0.depth}.max() ?? 0
		var rankedRoots = [[BinomialHeapNode<Priority, Element>]](repeating: [], count: maxRank + 1)
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
				let merged = mergeNode(node1, with: node2)
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
	
	private func mergeNode(_ node1: BinomialHeapNode<Priority, Element>, with node2: BinomialHeapNode<Priority, Element>) -> BinomialHeapNode<Priority, Element>
	{
		if node1.priority <= node2.priority
		{
			node1.children.append(node2)
			node1.depth = max(node1.depth, node2.depth + 1)
			node2.parent = node1
			return node1
		}
		else
		{
			node2.children.append(node1)
			node2.depth = max(node2.depth, node1.depth + 1)
			node1.parent = node2
			return node2
		}
	}
	
	public var min: Element!
	{
		return roots.first?.element
	}
	
	public var isEmpty: Bool
	{
		return roots.isEmpty
	}
	
	public func removeMin() -> Element?
	{
		guard roots.count > 0 else { return nil }
		let minNode = roots.first!
		
		roots.remove(at: 0)
		roots.append(contentsOf: minNode.children)
		
		cleanup()
		
		count -= 1
		
		return minNode.element
	}
}

fileprivate class BinomialHeapNode<Priority: Comparable, Element>
{
	var element: Element
	var priority: Priority
	
	weak var parent: BinomialHeapNode<Priority, Element>?
	var children:[BinomialHeapNode<Priority, Element>]
	
	var depth: Int
	
	init(priority: Priority, element: Element)
	{
		self.element = element
		self.priority = priority
		self.children = []
		depth = 0
	}
	
	fileprivate final func siftUp()
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
}

extension BinomialHeap: CustomStringConvertible
{
	public var description: String
	{
		let description = "Binomial Heap (\(count) nodes)\n"
		let subnodeDescriptions = roots.map{$0.description}.joined(separator: "\n").replacingOccurrences(of: "\n", with: "\n\t")
		return "\(description)\n\t\(subnodeDescriptions)"
	}
}

extension BinomialHeapNode: CustomStringConvertible
{
	fileprivate var description: String
	{
		let description = "- \(priority): \(element)"
		let subnodeDescriptions = children.map{$0.description}.joined(separator: "\n").replacingOccurrences(of: "\n", with: "\n\t")
		return "\(description)\n\t\(subnodeDescriptions)"
	}
}

