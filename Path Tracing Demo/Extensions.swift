//
//  Extensions.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 09.08.16.
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

extension Array where Element: Comparable
{
	func kthSmallestElement(_ k: Int) -> Element
	{
		//using quickselect algorithm
		let pivotIndex = Int(arc4random_uniform(UInt32(self.count)))
		let pivot = self[pivotIndex]
		
		let lower = self.filter{$0 < pivot}
		let upper = self.filter{$0 > pivot}
		
		if k <= lower.count
		{
			return lower.kthSmallestElement(k)
		}
		else if k > self.count - upper.count
		{
			return upper.kthSmallestElement(k - (self.count - upper.count))
		}
		else
		{
			return pivot
		}
	}
	
	func kthLargestElement(_ k: Int) -> Element
	{
		return kthSmallestElement(self.count - k - 1)
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
