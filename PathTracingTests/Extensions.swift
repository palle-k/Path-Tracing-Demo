//
//  Extensions.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 09.08.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Foundation

extension Array
{
	func peek(body: (Element) throws -> ()) rethrows -> [Element]
	{
		try self.forEach(body)
		return self
	}
	
	func limit(n: Int, offset: Int = 0) -> [Element]
	{
		return Array<Element>(self[offset..<(n + offset)])
	}
}

extension Array where Element: Equatable, Element: Hashable
{
	func distinct() -> [Element]
	{
		var set = Set<Element>()
		var result:[Element] = []
		
		for element in self
		{
			guard !set.contains(element) else { continue }
			result.append(element)
			set.insert(element)
		}
		
		return result
	}
}

extension Array where Element: Equatable
{
	func distinct() -> [Element]
	{
		var result:[Element] = []
		
		outer: for i in 0 ..< self.count
		{
			for j in 0 ..< i
			{
				if self[i] == self[j]
				{
					continue outer
				}
			}
			result.append(self[i])
		}
		
		return result
	}
}

extension Array where Element: AnyObject
{
	func distinct() -> [Element]
	{
		var result:[Element] = []
		
		outer: for i in 0 ..< self.count
		{
			for j in 0 ..< i
			{
				if self[i] === self[j]
				{
					continue outer
				}
			}
			result.append(self[i])
		}
		
		return result
	}
}
