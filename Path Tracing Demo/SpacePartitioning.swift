//
//  SpacePartitioning.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 01.08.16.
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

protocol TriangleStore: class
{
	func nearestIntersectingTriangle(forRay ray: Ray3D) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
}

fileprivate struct Volume
{
	let x: Float
	let y: Float
	let z: Float
	let width: Float
	let height: Float
	let depth: Float
	
	init(x: Float, y: Float, z: Float, width: Float, height: Float, depth: Float)
	{
		self.x = x
		self.y = y
		self.z = z
		self.width = width
		self.height = height
		self.depth = depth
	}
	
	init(containing points: [Point3D])
	{
		let minX = points.min{$0.x < $1.x}?.x ?? 0
		let minY = points.min{$0.y < $1.y}?.y ?? 0
		let minZ = points.min{$0.z < $1.z}?.z ?? 0
		let maxX = points.max{$0.x < $1.x}?.x ?? 1
		let maxY = points.max{$0.y < $1.y}?.y ?? 1
		let maxZ = points.max{$0.z < $1.z}?.z ?? 1
		
		let dx = maxX - minX
		let dy = maxY - minY
		let dz = maxZ - minZ
		
		x = minX
		y = minY
		z = minZ
		width = dx
		height = dy
		depth = dz
	}
	
	var mid:Point3D
	{
		return Point3D(x: x + width * 0.5, y: y + height * 0.5, z: z + depth * 0.5)
	}
	
	var innerSphereRadius:Float
	{
		return min(min(width, height), depth) * 0.5
	}
	
	var maxX: Float
	{
		return x + width
	}
	
	var maxY: Float
	{
		return y + height
	}
	
	var maxZ: Float
	{
		return z + depth
	}
	
	var outerSphereRadius: Float
	{
		let mid = self.mid
		let dx = x - mid.x
		let dy = y - mid.y
		let dz = z - mid.z
		return sqrt(dx * dx + dy * dy + dz * dz)
	}
	
	nonmutating func contains(point: Point3D) -> Bool
	{
		guard point.x >= x && point.x <= (x + width)  else { return false }
		guard point.y >= y && point.y <= (y + height) else { return false }
		guard point.z >= z && point.z <= (z + depth)  else { return false }
		return true
	}
	
	nonmutating func intersects(ray: Ray3D, strict: Bool = false) -> Bool
	{
		let baseBFL = Point3D(x: x, y: y, z: z)
		let baseTBR = baseBFL + Vector3D(x: width, y: height, z: depth)
		
		let tA = baseBFL - ray.base
		let tB = baseTBR - ray.base
		
		let tDivA = Vector3D(x: tA.x / ray.direction.x, y: tA.y / ray.direction.y, z: tA.z / ray.direction.z)
		let tDivB = Vector3D(x: tB.x / ray.direction.x, y: tB.y / ray.direction.y, z: tB.z / ray.direction.z)
		
		let tMin = max(max(min(tDivA.x, tDivB.x), min(tDivA.y, tDivB.y)), min(tDivA.z, tDivB.z))
		let tMax = min(min(max(tDivA.x, tDivB.x), max(tDivA.y, tDivB.y)), max(tDivA.z, tDivB.z))
		
		guard tMax >= 0 else { return false }
		guard tMax >= tMin else { return false }
		if strict
		{
			guard tMin <= 1 else { return false }
		}
		return true
	}
	
	nonmutating func contains(_ triangle: Triangle3D) -> Bool
	{
		if (triangle.points.map(self.contains).reduce(false){$0 || $1})
		{
			return true
		}
		else if intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.b.point - triangle.a.point), strict: true)
		{
			return true
		}
		else if intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.c.point - triangle.a.point), strict: true)
		{
			return true
		}
		else if intersects(ray: Ray3D(base: triangle.b.point, direction: triangle.c.point - triangle.b.point), strict: true)
		{
			return true
		}
		else
		{
			let edges = [(nearBottomLeft, nearBottomRight),
			             (nearBottomLeft, nearTopLeft),
			             (nearBottomRight, nearTopRight),
			             (nearTopLeft, nearTopRight),
			             (nearBottomLeft, farBottomLeft),
			             (nearBottomRight, farBottomRight),
			             (nearTopLeft, farTopLeft),
			             (nearTopRight, farTopRight),
			             (farBottomLeft, farBottomRight),
			             (farBottomLeft, farTopLeft),
			             (farBottomRight, farTopRight),
			             (farTopLeft, farTopRight)]
			
			for edge in edges
			{
				let ray = Ray3D(base: edge.0, direction: edge.1 - edge.0)
				
				if let intersection = ray.findIntersection(with: triangle), intersection.rayParameter <= 1.0
				{
					return true
				}
			}
			
			return false
		}
	}
	
	private var nearBottomLeft: Point3D
	{
		return Point3D(x: x, y: y, z: z)
	}
	
	private var nearBottomRight: Point3D
	{
		return Point3D(x: x + width, y: y, z: z)
	}
	
	private var nearTopLeft: Point3D
	{
		return Point3D(x: x, y: y + height, z: z)
	}
	
	private var nearTopRight: Point3D
	{
		return Point3D(x: x + width, y: y + height, z: z)
	}
	
	private var farBottomLeft: Point3D
	{
		return Point3D(x: x, y: y, z: z + depth)
	}
	
	private var farBottomRight: Point3D
	{
		return Point3D(x: x + width, y: y, z: z + depth)
	}
	
	private var farTopLeft: Point3D
	{
		return Point3D(x: x, y: y + height, z: z + depth)
	}
	
	private var farTopRight: Point3D
	{
		return Point3D(x: x + width, y: y + height, z: z + depth)
	}
}

private protocol OctreeNodeType
{
	var volume: Volume { get }
	
	nonmutating func findTriangle(intersecting ray: Ray3D, betterThan bestIntersectionRay: Float?) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
	
	nonmutating func intersects(ray: Ray3D, betterThan bestIntersection: Float?) -> Bool
}

extension OctreeNodeType
{
	@inline(__always)
	fileprivate nonmutating func intersects(ray: Ray3D, betterThan bestIntersection: Float? = nil) -> Bool
	{
		let baseBFL = Point3D(x: volume.x, y: volume.y, z: volume.z)
		let baseTBR = baseBFL + Vector3D(x: volume.width, y: volume.height, z: volume.depth)
		
		let tA = baseBFL - ray.base
		let tB = baseTBR - ray.base
		
		let tDivA = Vector3D(x: tA.x / ray.direction.x, y: tA.y / ray.direction.y, z: tA.z / ray.direction.z)
		let tDivB = Vector3D(x: tB.x / ray.direction.x, y: tB.y / ray.direction.y, z: tB.z / ray.direction.z)
		
		let tMax = min(min(max(tDivA.x, tDivB.x), max(tDivA.y, tDivB.y)), max(tDivA.z, tDivB.z))
		
		guard tMax >= 0 else { return false }
		
		let tMin = max(max(min(tDivA.x, tDivB.x), min(tDivA.y, tDivB.y)), min(tDivA.z, tDivB.z))
		
		guard tMax >= tMin && tMin < (bestIntersection ?? Float.infinity) else { return false }
		return true
	}
	
}

fileprivate class OctreeEmptyLeaf : OctreeNodeType
{
	fileprivate let volume: Volume = Volume(x: 0, y: 0, z: 0, width: 0, height: 0, depth: 0)

	fileprivate func findTriangle(intersecting ray: Ray3D, betterThan bestIntersectionRay: Float?) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
	{
		return nil
	}

}

fileprivate class OctreeLeaf : OctreeNodeType
{
	fileprivate let volume: Volume
	fileprivate let triangles:ContiguousArray<Triangle3D>
	
	init(volume: Volume, triangles: ContiguousArray<Triangle3D>)
	{
		self.volume = volume
		self.triangles = triangles
	}
	
	fileprivate func findTriangle(intersecting ray: Ray3D, betterThan bestIntersectionRay: Float?) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
	{
		guard self.intersects(ray: ray, betterThan: bestIntersectionRay) else { return nil }
		
		var bestIntersection:(triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)? = nil
		
		for triangle in triangles
		{
			guard let intersection = ray.findIntersection(with: triangle) else { continue }
			guard intersection.rayParameter > 0 else { continue }
			if bestIntersection == nil || intersection.rayParameter < bestIntersection!.ray
			{
				bestIntersection = (triangle: triangle, ray: intersection.rayParameter, barycentricIntersection: intersection.barycentric)
			}
		}
		
		return bestIntersection
	}
}

fileprivate class OctreeNode : OctreeNodeType
{
	fileprivate let volume: Volume
	
	fileprivate let lll: OctreeNodeType
	fileprivate let gll: OctreeNodeType
	fileprivate let lgl: OctreeNodeType
	fileprivate let ggl: OctreeNodeType
	fileprivate let llg: OctreeNodeType
	fileprivate let glg: OctreeNodeType
	fileprivate let lgg: OctreeNodeType
	fileprivate let ggg: OctreeNodeType
	
	fileprivate convenience init(with triangles: ContiguousArray<Triangle3D>)
	{
		self.init(with: triangles, maxBounds: Volume(containing: triangles.flatMap{[$0.a.point, $0.b.point, $0.c.point]}))
	}
	
	private init(with triangles: ContiguousArray<Triangle3D>, maxBounds: Volume)
	{
		
		let v = Volume(containing: triangles.flatMap{[$0.a.point, $0.b.point, $0.c.point]})
		
		self.volume = Volume(x: max(v.x, maxBounds.x),
		                     y: max(v.y, maxBounds.y),
		                     z: max(v.z, maxBounds.z),
		                     width:  min(maxBounds.maxX, v.maxX) - max(v.x, maxBounds.x),
		                     height: min(maxBounds.maxY, v.maxY) - max(v.y, maxBounds.y),
		                     depth:  min(maxBounds.maxZ, v.maxZ) - max(v.z, maxBounds.z))
		
		let minX = volume.x
		let minY = volume.y
		let minZ = volume.z
		
		let points = triangles.flatMap{[$0.a.point, $0.b.point, $0.c.point]}
		
		let mid = volume.mid
		
		let splitX = (points.map{$0.x}.kthSmallestElement(points.count / 2) * 0.6667 + mid.x * 0.3333)
		let splitY = (points.map{$0.y}.kthSmallestElement(points.count / 2) * 0.6667 + mid.y * 0.3333)
		let splitZ = (points.map{$0.z}.kthSmallestElement(points.count / 2) * 0.6667 + mid.z * 0.3333)
		
		//			let splitX = minX + volume.width * 0.5
		//			let splitY = minY + volume.height * 0.5
		//			let splitZ = minZ + volume.depth * 0.5
		
		let lowerWidth = splitX - minX
		let lowerHeight = splitY - minY
		let lowerDepth = splitZ - minZ
		
		let upperWidth = volume.width - lowerWidth
		let upperHeight = volume.height - lowerHeight
		let upperDepth = volume.depth - lowerDepth
		
		let lllBounds = Volume(
			x: minX,
			y: minY,
			z: minZ,
			width:  lowerWidth,
			height: lowerHeight,
			depth:  lowerDepth)
		let llgBounds = Volume(
			x: minX,
			y: minY,
			z: splitZ,
			width:  lowerWidth,
			height: lowerHeight,
			depth:  upperDepth)
		let lglBounds = Volume(
			x: minX,
			y: splitY,
			z: minZ,
			width:  lowerWidth,
			height: upperHeight,
			depth:  lowerDepth)
		let lggBounds = Volume(
			x: minX,
			y: splitY,
			z: splitZ,
			width:  lowerWidth,
			height: upperHeight,
			depth:  upperDepth)
		let gllBounds = Volume(
			x: splitX,
			y: minY,
			z: minZ,
			width:  upperWidth,
			height: lowerHeight,
			depth:  lowerDepth)
		let glgBounds = Volume(
			x: splitX,
			y: minY,
			z: splitZ,
			width:  upperWidth,
			height: lowerHeight,
			depth:  upperDepth)
		let gglBounds = Volume(
			x: splitX,
			y: splitY,
			z: minZ,
			width:  upperWidth,
			height: upperHeight,
			depth:  lowerDepth)
		let gggBounds = Volume(
			x: splitX,
			y: splitY,
			z: splitZ,
			width:  upperWidth,
			height: upperHeight,
			depth:  upperDepth)
		
		var lllBucket:ContiguousArray<Triangle3D> = []
		var llgBucket:ContiguousArray<Triangle3D> = []
		var lglBucket:ContiguousArray<Triangle3D> = []
		var lggBucket:ContiguousArray<Triangle3D> = []
		var gllBucket:ContiguousArray<Triangle3D> = []
		var glgBucket:ContiguousArray<Triangle3D> = []
		var gglBucket:ContiguousArray<Triangle3D> = []
		var gggBucket:ContiguousArray<Triangle3D> = []
		
		for triangle in triangles
		{
			if lllBounds.contains(triangle)
			{
				lllBucket.append(triangle)
			}
			if llgBounds.contains(triangle)
			{
				llgBucket.append(triangle)
			}
			if lglBounds.contains(triangle)
			{
				lglBucket.append(triangle)
			}
			if lggBounds.contains(triangle)
			{
				lggBucket.append(triangle)
			}
			if gllBounds.contains(triangle)
			{
				gllBucket.append(triangle)
			}
			if glgBounds.contains(triangle)
			{
				glgBucket.append(triangle)
			}
			if gglBounds.contains(triangle)
			{
				gglBucket.append(triangle)
			}
			if gggBounds.contains(triangle)
			{
				gggBucket.append(triangle)
			}
		}
		
		let buckets			= [lllBucket, llgBucket, lglBucket, lggBucket, gllBucket, glgBucket, gglBucket, gggBucket]
		let bounds			= [lllBounds, llgBounds, lglBounds, lggBounds, gllBounds, glgBounds, gglBounds, gggBounds]
		var distinctPoints	= Array<Bool>(repeating: false, count: 8)
		
		for i in 0 ..< 8
		{
			var distinct = false
			let points = buckets[i].flatMap{[$0.a.point, $0.b.point, $0.c.point]}.filter{bounds[i].contains(point: $0)}
			
			let minX = points.min{$0.x < $1.x}?.x ?? 0
			let maxX = points.max{$0.x < $1.x}?.x ?? 0
			distinct = distinct || (minX != maxX)
			
			let minY = points.min{$0.y < $1.y}?.y ?? 0
			let maxY = points.max{$0.y < $1.y}?.y ?? 0
			distinct = distinct || (minY != maxY)
			
			let minZ = points.min{$0.z < $1.z}?.z ?? 0
			let maxZ = points.max{$0.z < $1.z}?.z ?? 0
			distinct = distinct || (minZ != maxZ)
			
			distinctPoints[i] = distinct
		}
		
		let innerNodeThreshold = 4
		
		if distinctPoints[0] && lllBucket.count > innerNodeThreshold && lllBucket.count < triangles.count
		{
			lll = OctreeNode(with: lllBucket, maxBounds: lllBounds)
		}
		else if !lllBucket.isEmpty
		{
			lll = OctreeLeaf(volume: lllBounds, triangles: lllBucket)
		}
		else
		{
			lll = OctreeEmptyLeaf()
		}
		
		if distinctPoints[1] && llgBucket.count > innerNodeThreshold && llgBucket.count < triangles.count
		{
			llg = OctreeNode(with: llgBucket, maxBounds: llgBounds)
		}
		else if !llgBucket.isEmpty
		{
			llg = OctreeLeaf(volume: llgBounds, triangles: llgBucket)
		}
		else
		{
			llg = OctreeEmptyLeaf()
		}
		
		if distinctPoints[2] && lglBucket.count > innerNodeThreshold && lglBucket.count < triangles.count
		{
			lgl = OctreeNode(with: lglBucket, maxBounds: lglBounds)
		}
		else if !lglBucket.isEmpty
		{
			lgl = OctreeLeaf(volume: lglBounds, triangles: lglBucket)
		}
		else
		{
			lgl = OctreeEmptyLeaf()
		}
		
		if distinctPoints[3] && lggBucket.count > innerNodeThreshold && lggBucket.count < triangles.count
		{
			lgg = OctreeNode(with: lggBucket, maxBounds: lggBounds)
		}
		else if !lggBucket.isEmpty
		{
			lgg = OctreeLeaf(volume: lggBounds, triangles: lggBucket)
		}
		else
		{
			lgg = OctreeEmptyLeaf()
		}
		
		if distinctPoints[4] && gllBucket.count > innerNodeThreshold && gllBucket.count < triangles.count
		{
			gll = OctreeNode(with: gllBucket, maxBounds: gllBounds)
		}
		else if !gllBucket.isEmpty
		{
			gll = OctreeLeaf(volume: gllBounds, triangles: gllBucket)
		}
		else
		{
			gll = OctreeEmptyLeaf()
		}
		
		if distinctPoints[5] && glgBucket.count > innerNodeThreshold && glgBucket.count < triangles.count
		{
			glg = OctreeNode(with: glgBucket, maxBounds: glgBounds)
		}
		else if !glgBucket.isEmpty
		{
			glg = OctreeLeaf(volume: glgBounds, triangles: glgBucket)
		}
		else
		{
			glg = OctreeEmptyLeaf()
		}
		
		if distinctPoints[6] && gglBucket.count > innerNodeThreshold && gglBucket.count < triangles.count
		{
			ggl = OctreeNode(with: gglBucket, maxBounds: gglBounds)
		}
		else if !gglBucket.isEmpty
		{
			ggl = OctreeLeaf(volume: gglBounds, triangles: gglBucket)
		}
		else
		{
			ggl = OctreeEmptyLeaf()
		}
		
		if distinctPoints[7] && gggBucket.count > innerNodeThreshold && gggBucket.count < triangles.count
		{
			ggg = OctreeNode(with: gggBucket, maxBounds: gggBounds)
		}
		else if !gggBucket.isEmpty
		{
			ggg = OctreeLeaf(volume: gggBounds, triangles: gggBucket)
		}
		else
		{
			ggg = OctreeEmptyLeaf()
		}
	}
	
	fileprivate func findTriangle(intersecting ray: Ray3D, betterThan bestIntersectionRay: Float? = nil) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
	{
		guard intersects(ray: ray, betterThan: bestIntersectionRay) else { return nil }
		
		var bestIntersection:(triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)? = nil
		
		if let subnodeIntersection = lll.findTriangle(intersecting: ray, betterThan: bestIntersection?.ray)
		{
			if bestIntersection == nil || bestIntersection!.ray > subnodeIntersection.ray
			{
				bestIntersection = subnodeIntersection
			}
		}
		if let subnodeIntersection = llg.findTriangle(intersecting: ray, betterThan: bestIntersection?.ray)
		{
			if bestIntersection == nil || bestIntersection!.ray > subnodeIntersection.ray
			{
				bestIntersection = subnodeIntersection
			}
		}
		if let subnodeIntersection = lgl.findTriangle(intersecting: ray, betterThan: bestIntersection?.ray)
		{
			if bestIntersection == nil || bestIntersection!.ray > subnodeIntersection.ray
			{
				bestIntersection = subnodeIntersection
			}
		}
		if let subnodeIntersection = lgg.findTriangle(intersecting: ray, betterThan: bestIntersection?.ray)
		{
			if bestIntersection == nil || bestIntersection!.ray > subnodeIntersection.ray
			{
				bestIntersection = subnodeIntersection
			}
		}
		if let subnodeIntersection = gll.findTriangle(intersecting: ray, betterThan: bestIntersection?.ray)
		{
			if bestIntersection == nil || bestIntersection!.ray > subnodeIntersection.ray
			{
				bestIntersection = subnodeIntersection
			}
		}
		if let subnodeIntersection = glg.findTriangle(intersecting: ray, betterThan: bestIntersection?.ray)
		{
			if bestIntersection == nil || bestIntersection!.ray > subnodeIntersection.ray
			{
				bestIntersection = subnodeIntersection
			}
		}
		if let subnodeIntersection = ggl.findTriangle(intersecting: ray, betterThan: bestIntersection?.ray)
		{
			if bestIntersection == nil || bestIntersection!.ray > subnodeIntersection.ray
			{
				bestIntersection = subnodeIntersection
			}
		}
		if let subnodeIntersection = ggg.findTriangle(intersecting: ray, betterThan: bestIntersection?.ray)
		{
			if bestIntersection == nil || bestIntersection!.ray > subnodeIntersection.ray
			{
				bestIntersection = subnodeIntersection
			}
		}
		
		return bestIntersection
	}
}

extension OctreeEmptyLeaf: CustomStringConvertible
{
	fileprivate var description: String
	{
		return "none"
	}
}

extension OctreeLeaf: CustomStringConvertible
{
	fileprivate var description: String
	{
		return "Leaf \(volume):\n\t\(triangles.map{$0.description}.joined(separator: "\n\t"))"
	}
}

extension OctreeNode: CustomStringConvertible
{
	fileprivate var description: String
	{
		var descriptions = [String](repeating: "", count: 8)
		
		for (index, (node, name)) in [(lll, "lll"), (llg, "llg"), (lgl, "lgl"), (lgg, "lgg"), (gll, "gll"), (glg, "glg"), (ggl, "ggl"), (ggg, "ggg")].enumerated()
		{
			var description:String
			
			description = "\(node)"
			
			descriptions[index] = "\t\(name):\n\t\t\(description.replacingOccurrences(of: "\n", with: "\n\t"))"
		}
		
		let combinedDescriptions = descriptions.joined(separator: "\n")
		
		return "Inner Node (\(volume)):\n\(combinedDescriptions)"
	}
}

class OctreeTriangleStore : TriangleStore, CustomStringConvertible
{
	private let root: OctreeNode
	
	init(with triangles: [Triangle3D])
	{
		root = OctreeNode(with: ContiguousArray<Triangle3D>(triangles))
	}
	
	func nearestIntersectingTriangle(forRay ray: Ray3D) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
	{
		return root.findTriangle(intersecting: ray)
	}
	
	var description: String
	{
		return "Octree:\n\(root)"
	}
}


//Currently unused (slower than octree. Bug?)
//class BSPTriangleStore: TriangleStore, CustomStringConvertible
//{
//	private enum BSPTreeNode
//	{
//		case inner(InnerNode)
//		case leaf([Triangle3D])
//		case none
//	}
//	
//	private enum SplittingPlaneOrientation
//	{
//		case xy
//		case xz
//		case yz
//		
//		var pointComparator: (Point3D, Point3D) -> Bool
//		{
//			switch self
//			{
//			case .xy:
//				return {$0.z < $1.z}
//			case .xz:
//				return {$0.y < $1.y}
//			case .yz:
//				return {$0.x < $1.x}
//			}
//		}
//		
//		var triangleComparator: (Triangle3D, Triangle3D) -> Bool
//		{
//			let pc = pointComparator
//			return { a, b -> Bool in
//				var bb = true
//				//∀pb∈B ∃pa∈A: pa<pb
//				for pb in b.points
//				{
//					var smallerExists = false
//					for pa in a.points
//					{
//						smallerExists = smallerExists || pc(pa, pb)
//					}
//					bb = bb && smallerExists
//				}
//				return bb
//			}
//			
//		}
//	}
//	
//	private struct Volume: CustomStringConvertible
//	{
//		let x: Float
//		let y: Float
//		let z: Float
//		let width: Float
//		let height: Float
//		let depth: Float
//		
//		var mid:Point3D
//		{
//			return Point3D(x: x + width * 0.5, y: y + height * 0.5, z: z + depth * 0.5)
//		}
//		
//		var innerSphereRadius:Float
//		{
//			return min(min(width, height), depth) * 0.5
//		}
//		
//		var outerSphereRadius: Float
//		{
//			let mid = self.mid
//			let dx = x - mid.x
//			let dy = y - mid.y
//			let dz = z - mid.z
//			return sqrt(dx * dx + dy * dy + dz * dz)
//		}
//		
//		var size: Float
//		{
//			return width * height * depth
//		}
//		
//		private func contains(point: Point3D) -> Bool
//		{
//			guard point.x >= x && point.x <= (x + width)  else { return false }
//			guard point.y >= y && point.y <= (y + height) else { return false }
//			guard point.z >= z && point.z <= (z + depth)  else { return false }
//			return true
//		}
//		
//		private func intersects(ray: Ray3D, strict: Bool = false) -> Bool
//		{
//			let baseBFL = Point3D(x: x, y: y, z: z)
//			let baseTBR = baseBFL + Vector3D(x: width, y: height, z: depth)
//			
//			let tA = baseBFL - ray.base
//			let tB = baseTBR - ray.base
//			
//			var rayDirection = ray.direction
//			if rayDirection.x == 0
//			{
//				rayDirection.x = nextafterf(rayDirection.x, 1)
//			}
//			
//			if rayDirection.y == 0
//			{
//				rayDirection.y = nextafterf(rayDirection.y, 1)
//			}
//			
//			if rayDirection.z == 0
//			{
//				rayDirection.z = nextafterf(rayDirection.z, 1)
//			}
//			
//			let tDivA = Vector3D(x: tA.x / rayDirection.x, y: tA.y / rayDirection.y, z: tA.z / ray.direction.z)
//			let tDivB = Vector3D(x: tB.x / rayDirection.x, y: tB.y / rayDirection.y, z: tB.z / ray.direction.z)
//			
//			let tMin = max(max(min(tDivA.x, tDivB.x), min(tDivA.y, tDivB.y)), min(tDivA.z, tDivB.z))
//			let tMax = min(min(max(tDivA.x, tDivB.x), max(tDivA.y, tDivB.y)), max(tDivA.z, tDivB.z))
//			
//			guard tMax >= 0 else { return false }
//			guard tMax >= tMin else { return false }
//			if strict
//			{
//				guard tMin <= 1 else { return false }
//			}
//			return true
//		}
//		
//		fileprivate var description: String
//		{
//			return "x: \(x), y: \(y), z: \(z), w: \(width), h: \(height), d: \(depth)"
//		}
//	}
//	
//	private class InnerNode: CustomStringConvertible
//	{
//		private let volume: Volume
//		private let lower:BSPTreeNode
//		private let upper:BSPTreeNode
//		
//		init(triangles:[Triangle3D], volume: Volume, nextSplit: SplittingPlaneOrientation)
//		{
//			self.volume = volume
//			
//			let sortedTriangles = triangles.sorted(by: nextSplit.triangleComparator)
//			let lowerTriangles = sortedTriangles.limit(n: sortedTriangles.count / 2)
//			let upperTriangles = sortedTriangles.limit(n: sortedTriangles.count - lowerTriangles.count, offset: lowerTriangles.count)
//			
//			let lowerPoints = lowerTriangles.flatMap{[$0.a.point, $0.b.point, $0.c.point]}
//			let lowerMinX = lowerPoints.min{$0.x < $1.x}?.x ?? 0
//			let lowerMinY = lowerPoints.min{$0.y < $1.y}?.y ?? 0
//			let lowerMinZ = lowerPoints.min{$0.z < $1.z}?.z ?? 0
//			let lowerMaxX = lowerPoints.max{$0.x < $1.x}?.x ?? 0
//			let lowerMaxY = lowerPoints.max{$0.y < $1.y}?.y ?? 0
//			let lowerMaxZ = lowerPoints.max{$0.z < $1.z}?.z ?? 0
//			
//			let upperPoints = upperTriangles.flatMap{[$0.a.point, $0.b.point, $0.c.point]}
//			let upperMinX = upperPoints.min{$0.x < $1.x}?.x ?? 0
//			let upperMinY = upperPoints.min{$0.y < $1.y}?.y ?? 0
//			let upperMinZ = upperPoints.min{$0.z < $1.z}?.z ?? 0
//			let upperMaxX = upperPoints.max{$0.x < $1.x}?.x ?? 0
//			let upperMaxY = upperPoints.max{$0.y < $1.y}?.y ?? 0
//			let upperMaxZ = upperPoints.max{$0.z < $1.z}?.z ?? 0
//			
//			let lowerDX = lowerMaxX - lowerMinX
//			let lowerDY = lowerMaxY - lowerMinY
//			let lowerDZ = lowerMaxZ - lowerMinZ
//			
//			let upperDX = upperMaxX - upperMinX
//			let upperDY = upperMaxY - upperMinY
//			let upperDZ = upperMaxZ - upperMinZ
//			
//			let lowerVolume = Volume(x: lowerMinX, y: lowerMinY, z: lowerMinZ, width: lowerDX, height: lowerDY, depth: lowerDZ)
//			let upperVolume = Volume(x: upperMinX, y: upperMinY, z: upperMinZ, width: upperDX, height: upperDY, depth: upperDZ)
//			
//			let capacity = 4
//			
//			if lowerPoints.count < capacity ||
//				(lowerMinX == lowerMaxX &&
//				 lowerMinY == lowerMaxY &&
//				 lowerMinZ == lowerMaxZ) ||
//				lowerTriangles.count == triangles.count
//			{
//				lower = .leaf(lowerTriangles)
//			}
//			else
//			{
//				let nextSplit: SplittingPlaneOrientation
//				
//				if lowerDX > lowerDY && lowerDX > lowerDZ
//				{
//					nextSplit = .yz
//				}
//				else if lowerDY > lowerDX && lowerDY > lowerDZ
//				{
//					nextSplit = .xz
//				}
//				else
//				{
//					nextSplit = .xy
//				}
//				
//				
//				lower = .inner(InnerNode(triangles: lowerTriangles,
//				                         volume: lowerVolume,
//				                         nextSplit: nextSplit))
//			}
//			if upperPoints.count < capacity ||
//				(upperMinX == upperMaxX &&
//				 upperMinY == upperMaxY &&
//				 upperMinZ == upperMaxZ) ||
//				upperTriangles.count == triangles.count
//			{
//				upper = .leaf(upperTriangles)
//			}
//			else
//			{
//				let nextSplit: SplittingPlaneOrientation
//				
//				if upperDX > upperDY && upperDX > upperDZ
//				{
//					nextSplit = .yz
//				}
//				else if upperDY > upperDX && upperDY > upperDZ
//				{
//					nextSplit = .xz
//				}
//				else
//				{
//					nextSplit = .xy
//				}
//				
//				upper = .inner(InnerNode(triangles: upperTriangles,
//				                         volume: upperVolume,
//				                         nextSplit: nextSplit))
//			}
//		}
//		
//		convenience init(triangles:[Triangle3D])
//		{
//			let points = triangles.flatMap{[$0.a.point, $0.b.point, $0.c.point]}
//			let minX = points.min{$0.x < $1.x}?.x ?? 0
//			let minY = points.min{$0.y < $1.y}?.y ?? 0
//			let minZ = points.min{$0.z < $1.z}?.z ?? 0
//			let maxX = points.max{$0.x < $1.x}?.x ?? 1
//			let maxY = points.max{$0.y < $1.y}?.y ?? 1
//			let maxZ = points.max{$0.z < $1.z}?.z ?? 1
//			
//			let dx = maxX - minX
//			let dy = maxY - minY
//			let dz = maxZ - minZ
//			
//			let nextSplit: SplittingPlaneOrientation
//			
//			if dx > dy && dx > dz
//			{
//				nextSplit = .yz
//			}
//			else if dy > dx && dy > dz
//			{
//				nextSplit = .xz
//			}
//			else
//			{
//				nextSplit = .xy
//			}
//			
//			let volume = Volume(
//				x: minX,
//				y: minY,
//				z: minZ,
//				width: maxX - minX,
//				height: maxY - minY,
//				depth: maxZ - minZ)
//			
//			self.init(triangles: triangles, volume: volume, nextSplit: nextSplit)
//		}
//		
//		private final func intersects(ray: Ray3D, betterThan bestIntersection: Float? = nil) -> Bool
//		{
//			let baseBFL = Point3D(x: volume.x, y: volume.y, z: volume.z)
//			let baseTBR = baseBFL + Vector3D(x: volume.width, y: volume.height, z: volume.depth)
//			
//			let tA = baseBFL - ray.base
//			let tB = baseTBR - ray.base
//			
//			let rayDirection = ray.direction + Vector3D(x: nextafterf(0, 1) * 4.0, y: nextafterf(0, 1) * 4.0, z: nextafterf(0, 1) * 4.0)
//			
//			let tDivA = Vector3D(x: tA.x / rayDirection.x, y: tA.y / rayDirection.y, z: tA.z / ray.direction.z)
//			let tDivB = Vector3D(x: tB.x / rayDirection.x, y: tB.y / rayDirection.y, z: tB.z / ray.direction.z)
//			
//			let tMax = min(min(max(tDivA.x, tDivB.x), max(tDivA.y, tDivB.y)), max(tDivA.z, tDivB.z))
//			
//			guard tMax >= 0 else { return false }
//			
//			let tMin = max(max(min(tDivA.x, tDivB.x), min(tDivA.y, tDivB.y)), min(tDivA.z, tDivB.z))
//			
//			guard tMax >= tMin && tMin < (bestIntersection ?? Float.infinity) else { return false }
//			return true
//		}
//		
//		fileprivate final func nearestIntersectingTriangle(forRay ray: Ray3D, betterThan bestIntersection: Float? = nil) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
//		{
//			guard intersects(ray: ray, betterThan: bestIntersection) else { return nil }
//			var bestIntersection: (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)? = nil
//			for subnode in [lower, upper]
//			{
//				if case let .inner(innerNode) = subnode
//				{
//					guard let subnodeIntersection = innerNode.nearestIntersectingTriangle(forRay: ray, betterThan: nil) else { continue }
//					if bestIntersection == nil || bestIntersection!.ray > subnodeIntersection.ray
//					{
//						bestIntersection = subnodeIntersection
//					}
//				}
//				else if case let .leaf(triangles) = subnode
//				{
//					for triangle in triangles
//					{
//						guard let intersection = ray.findIntersection(with: triangle) else { continue }
//						guard intersection.rayParameter > 0 else { continue }
//						if bestIntersection == nil || intersection.rayParameter < bestIntersection!.ray
//						{
//							bestIntersection = (triangle: triangle, ray: intersection.rayParameter, barycentricIntersection: intersection.barycentric)
//						}
//					}
//				}
//			}
//			return bestIntersection
//		}
//		
//		fileprivate var description: String
//		{
//			let lowerDescription:String
//			if case let .inner(innerNode) = lower
//			{
//				lowerDescription = innerNode.description.replacingOccurrences(of: "\n", with: "\n\t")
//			}
//			else if case let .leaf(triangles) = lower
//			{
//				lowerDescription = "\tLeaf (\(triangles.count) triangles)"
//			}
//			else
//			{
//				lowerDescription = "None"
//			}
//			let upperDescription:String
//			if case let .inner(innerNode) = upper
//			{
//				upperDescription = innerNode.description.replacingOccurrences(of: "\n", with: "\n\t")
//			}
//			else if case let .leaf(triangles) = upper
//			{
//				upperDescription = "\tLeaf (\(triangles.count) triangles)"
//			}
//			else
//			{
//				upperDescription = "None"
//			}
//			return "Inner \(volume)\n\t\(lowerDescription)\n\t\(upperDescription)"
//		}
//	}
//	
//	private let root:InnerNode
//	
//	init(with triangles: [Triangle3D])
//	{
//		root = InnerNode(triangles: triangles)
//	}
//	
//	final func nearestIntersectingTriangle(forRay ray: Ray3D) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
//	{
//		return root.nearestIntersectingTriangle(forRay: ray)
//	}
//	
//	var description: String
//	{
//		return "BHVTree:\n\(root.description)"
//	}
//}
