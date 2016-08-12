//
//  SpacePartitioning.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 01.08.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Foundation

protocol TriangleStore
{
	var triangles: [Triangle3D] { get }
	
	func nearestIntersectingTriangle(forRay ray: Ray3D) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
}


struct DefaultTriangleStore : TriangleStore
{
	var triangles: [Triangle3D]
	
	init(with triangles: [Triangle3D])
	{
		self.triangles = triangles
	}
	
	func nearestIntersectingTriangle(forRay ray: Ray3D) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
	{
		var closestTriangle: Triangle3D? = nil
		var intersectionDistance: Float = Float.infinity
		var intersectionBarycentricCoordinates: BarycentricPoint = BarycentricPoint(alpha: 0, beta: 0, gamma: 0)
		for triangle in self.triangles
		{
			guard let intersection = ray.findIntersection(with: triangle) else { continue }
			if intersection.rayParameter > 0 && intersection.rayParameter < intersectionDistance
			{
				closestTriangle = triangle
				intersectionDistance = intersection.rayParameter
				intersectionBarycentricCoordinates = intersection.barycentric
			}
		}
		if let closestIntersectingTriangle = closestTriangle
		{
			return (triangle: closestIntersectingTriangle, ray: intersectionDistance, barycentricIntersection: intersectionBarycentricCoordinates)
		}
		return nil
	}
}

class OctreeTriangleStore : TriangleStore, CustomStringConvertible
{
	private struct Volume
	{
		let x: Float
		let y: Float
		let z: Float
		let width: Float
		let height: Float
		let depth: Float
		
		var mid:Point3D
		{
			return Point3D(x: x + width * 0.5, y: y + height * 0.5, z: z + depth * 0.5)
		}
		
		var innerSphereRadius:Float
		{
			return min(min(width, height), depth) * 0.5
		}
		
		var outerSphereRadius: Float
		{
			let mid = self.mid
			let dx = x - mid.x
			let dy = y - mid.y
			let dz = z - mid.z
			return sqrt(dx * dx + dy * dy + dz * dz)
		}
		
		func contains(point: Point3D) -> Bool
		{
			guard point.x >= x && point.x <= (x + width)  else { return false }
			guard point.y >= y && point.y <= (y + height) else { return false }
			guard point.z >= z && point.z <= (z + depth)  else { return false }
			return true
		}
	}
	
	private enum OctreeNode
	{
		case inner (OctreeInnerNode)
		case leaf ([Triangle3D])
		case none
	}
	
	private class OctreeInnerNode : CustomStringConvertible
	{
		private var volume: Volume
		
		private var lll: OctreeNode = .none
		private var gll: OctreeNode = .none
		private var lgl: OctreeNode = .none
		private var ggl: OctreeNode = .none
		private var llg: OctreeNode = .none
		private var glg: OctreeNode = .none
		private var lgg: OctreeNode = .none
		private var ggg: OctreeNode = .none
		
		private init(with volume: Volume)
		{
			self.volume = volume
		}
		
		private convenience init(with triangles: [Triangle3D])
		{
			let points = triangles.flatMap{[$0.a.point, $0.b.point, $0.c.point]}
			let minX = points.min{$0.x < $1.x}?.x ?? 0
			let minY = points.min{$0.y < $1.y}?.y ?? 0
			let minZ = points.min{$0.z < $1.z}?.z ?? 0
			let maxX = points.max{$0.x < $1.x}?.x ?? 1
			let maxY = points.max{$0.y < $1.y}?.y ?? 1
			let maxZ = points.max{$0.z < $1.z}?.z ?? 1
			
			let volume = OctreeTriangleStore.Volume(
				x: minX,
				y: minY,
				z: minZ,
				width: maxX - minX,
				height: maxY - minY,
				depth: maxZ - minZ)
			
			self.init(with: triangles, volume: volume)
		}
		
		private init(with triangles: [Triangle3D], volume: Volume)
		{
			self.volume = volume
			
			let minX = volume.x
			let minY = volume.y
			let minZ = volume.z
			
			let lllBounds = OctreeTriangleStore.Volume(
				x: minX,
				y: minY,
				z: minZ,
				width: volume.width * 0.5,
				height: volume.height * 0.5,
				depth: volume.depth * 0.5)
			let llgBounds = OctreeTriangleStore.Volume(
				x: minX,
				y: minY,
				z: minZ + volume.depth * 0.5,
				width: volume.width * 0.5,
				height: volume.height * 0.5,
				depth: volume.depth * 0.5)
			let lglBounds = OctreeTriangleStore.Volume(
				x: minX,
				y: minY + volume.height * 0.5,
				z: minZ,
				width: volume.width * 0.5,
				height: volume.height * 0.5,
				depth: volume.depth * 0.5)
			let lggBounds = OctreeTriangleStore.Volume(
				x: minX,
				y: minY + volume.height * 0.5,
				z: minZ + volume.depth * 0.5,
				width: volume.width * 0.5,
				height: volume.height * 0.5,
				depth: volume.depth * 0.5)
			let gllBounds = OctreeTriangleStore.Volume(
				x: minX + volume.width * 0.5,
				y: minY,
				z: minZ,
				width: volume.width * 0.5,
				height: volume.height * 0.5,
				depth: volume.depth * 0.5)
			let glgBounds = OctreeTriangleStore.Volume(
				x: minX + volume.width * 0.5,
				y: minY,
				z: minZ + volume.depth * 0.5,
				width: volume.width * 0.5,
				height: volume.height * 0.5,
				depth: volume.depth * 0.5)
			let gglBounds = OctreeTriangleStore.Volume(
				x: minX + volume.width * 0.5,
				y: minY + volume.height * 0.5,
				z: minZ,
				width: volume.width * 0.5,
				height: volume.height * 0.5,
				depth: volume.depth * 0.5)
			let gggBounds = OctreeTriangleStore.Volume(
				x: minX + volume.width * 0.5,
				y: minY + volume.height * 0.5,
				z: minZ + volume.depth * 0.5,
				width: volume.width * 0.5,
				height: volume.height * 0.5,
				depth: volume.depth * 0.5)
			
			let lllBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					return triangle.points.map{lllBounds.contains(point: $0)}.reduce(false){$0 || $1}
				}
			let llgBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					return triangle.points.map{llgBounds.contains(point: $0)}.reduce(false){$0 || $1}
				}
			let lglBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					return triangle.points.map{lglBounds.contains(point: $0)}.reduce(false){$0 || $1}
				}
			let lggBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					return triangle.points.map{lggBounds.contains(point: $0)}.reduce(false){$0 || $1}
				}
			let gllBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					return triangle.points.map{gllBounds.contains(point: $0)}.reduce(false){$0 || $1}
				}
			let glgBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					return triangle.points.map{glgBounds.contains(point: $0)}.reduce(false){$0 || $1}
				}
			let gglBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					return triangle.points.map{gglBounds.contains(point: $0)}.reduce(false){$0 || $1}
			}
			let gggBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					return triangle.points.map{gggBounds.contains(point: $0)}.reduce(false){$0 || $1}
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
			
			let innerNodeThreshold = 8
			
			if distinctPoints[0] && lllBucket.count > innerNodeThreshold
			{
				lll = .inner(OctreeInnerNode(with: lllBucket, volume: lllBounds))
			}
			else if !lllBucket.isEmpty
			{
				lll = .leaf(lllBucket)
			}
			
			if distinctPoints[1] && llgBucket.count > innerNodeThreshold
			{
				llg = .inner(OctreeInnerNode(with: llgBucket, volume: llgBounds))
			}
			else if !llgBucket.isEmpty
			{
				llg = .leaf(llgBucket)
			}
			
			if distinctPoints[2] && lglBucket.count > innerNodeThreshold
			{
				lgl = .inner(OctreeInnerNode(with: lglBucket, volume: lglBounds))
			}
			else if !lglBucket.isEmpty
			{
				lgl = .leaf(lglBucket)
			}
			
			if distinctPoints[3] && lggBucket.count > innerNodeThreshold
			{
				lgg = .inner(OctreeInnerNode(with: lggBucket, volume: lggBounds))
			}
			else if !lggBucket.isEmpty
			{
				lgg = .leaf(lggBucket)
			}
			
			if distinctPoints[4] && gllBucket.count > innerNodeThreshold
			{
				gll = .inner(OctreeInnerNode(with: gllBucket, volume: gllBounds))
			}
			else if !gllBucket.isEmpty
			{
				gll = .leaf(gllBucket)
			}
			
			if distinctPoints[5] && glgBucket.count > innerNodeThreshold
			{
				glg = .inner(OctreeInnerNode(with: glgBucket, volume: glgBounds))
			}
			else if !glgBucket.isEmpty
			{
				glg = .leaf(glgBucket)
			}
			
			if distinctPoints[6] && gglBucket.count > innerNodeThreshold
			{
				ggl = .inner(OctreeInnerNode(with: gglBucket, volume: gglBounds))
			}
			else if !gglBucket.isEmpty
			{
				ggl = .leaf(gglBucket)
			}
			
			if distinctPoints[7] && gggBucket.count > innerNodeThreshold
			{
				ggg = .inner(OctreeInnerNode(with: gggBucket, volume: gggBounds))
			}
			else if !gggBucket.isEmpty
			{
				ggg = .leaf(gggBucket)
			}
			
		}
		
		private final func intersects(ray: Ray3D) -> Bool
		{
			let distanceToCenter = ray <-> volume.mid
			if distanceToCenter <= volume.innerSphereRadius
			{
				return true
			}
			else if distanceToCenter > volume.outerSphereRadius
			{
				return false
			}
			
			let vecX = Vector3DUnitX * volume.width
			let vecY = Vector3DUnitY * volume.height
			let vecZ = Vector3DUnitZ * volume.depth
			let baseBFL = Point3D(x: volume.x, y: volume.y, z: volume.z)
			let baseTBR = baseBFL + vecX + vecZ + vecZ
			
			let frontSystem = Matrix(vectors: vecX, vecZ, -ray.direction, ray.base - baseBFL)
			if let solution = frontSystem.solve3x3(), solution.x >= 0 && solution.x <= 1 && solution.y >= 0 && solution.y <= 1 && solution.z > 0
			{
				return true
			}
			
			let bottomSystem = Matrix(vectors: vecX, vecY, -ray.direction, ray.base - baseBFL)
			if let solution = bottomSystem.solve3x3(), solution.x >= 0 && solution.x <= 1 && solution.y >= 0 && solution.y <= 1 && solution.z > 0
			{
				return true
			}
			
			let leftSystem = Matrix(vectors: vecY, vecZ, -ray.direction, ray.base - baseBFL)
			if let solution = leftSystem.solve3x3(), solution.x >= 0 && solution.x <= 1 && solution.y >= 0 && solution.y <= 1 && solution.z > 0
			{
				return true
			}
			
			let topSystem = Matrix(vectors: -vecX, -vecY, -ray.direction, ray.base - baseTBR)
			if let solution = topSystem.solve3x3(), solution.x >= 0 && solution.x <= 1 && solution.y >= 0 && solution.y <= 1 && solution.z > 0
			{
				return true
			}
			
			let rightSystem = Matrix(vectors: -vecZ, -vecY, -ray.direction, ray.base - baseTBR)
			if let solution = rightSystem.solve3x3(), solution.x >= 0 && solution.x <= 1 && solution.y >= 0 && solution.y <= 1 && solution.z > 0
			{
				return true
			}
//			
//			let backSystem = Matrix(vectors: -vecZ, -vecX, -ray.direction, ray.base - baseTBR)
//			if let solution = backSystem.solve3x3(), solution.x >= 0 && solution.x <= 1 && solution.y >= 0 && solution.y <= 1 && solution.z > 0
//			{
//				return true
//			}
//			
			
			return false
		}
		
		private final func findTriangle(intersecting ray: Ray3D) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
		{
			guard intersects(ray: ray) else { return nil }
			
			var bestIntersection:(triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)? = nil
			
			for node in [lll, llg, lgl, lgg, gll, glg, ggl, ggg]
			{
				if case let OctreeNode.inner(innerNode) = node
				{
					guard let intersection = innerNode.findTriangle(intersecting: ray) else { continue }
					if bestIntersection == nil || intersection.ray < bestIntersection?.ray
					{
						bestIntersection = intersection
					}
				}
				else if case let OctreeNode.leaf(triangles) = node
				{
					for triangle in triangles
					{
						guard let intersection = ray.findIntersection(with: triangle) else { continue }
						guard intersection.rayParameter > 0 else { continue }
						if bestIntersection == nil || intersection.rayParameter < bestIntersection?.ray
						{
							bestIntersection = (triangle: triangle, ray: intersection.rayParameter, barycentricIntersection: intersection.barycentric)
						}
					}
				}
			}
			
			return bestIntersection
		}
		
		private var description: String
		{
			var lllDescription:String
			
			switch lll
			{
			case .none:
				lllDescription = "none"
				break
			case .inner(let innerNode):
				lllDescription = innerNode.description.replacingOccurrences(of: "\n", with: "\n\t")
				break
			case .leaf(let triangles):
				let triangleString:String = triangles
					.map{$0.description}
					.joined(separator: "\n")
					.replacingOccurrences(of: "\n", with: "\n\t")
				lllDescription = "\(triangleString)"
			}
			
			var llgDescription:String
			
			switch llg
			{
			case .none:
				llgDescription = "none"
				break
			case .inner(let innerNode):
				llgDescription = innerNode.description.replacingOccurrences(of: "\n", with: "\n\t")
				break
			case .leaf(let triangles):
				let triangleString:String = triangles
					.map{$0.description}
					.joined(separator: "\n")
					.replacingOccurrences(of: "\n", with: "\n\t")
				llgDescription = "\(triangleString)"
			}
			
			var lglDescription:String
			
			switch lgl
			{
			case .none:
				lglDescription = "none"
				break
			case .inner(let innerNode):
				lglDescription = innerNode.description.replacingOccurrences(of: "\n", with: "\n\t")
				break
			case .leaf(let triangles):
				let triangleString:String = triangles
					.map{$0.description}
					.joined(separator: "\n")
					.replacingOccurrences(of: "\n", with: "\n\t")
				lglDescription = "\(triangleString)"
			}
			
			var lggDescription:String
			
			switch lgg
			{
			case .none:
				lggDescription = "none"
				break
			case .inner(let innerNode):
				lggDescription = innerNode.description.replacingOccurrences(of: "\n", with: "\n\t")
				break
			case .leaf(let triangles):
				let triangleString:String = triangles
					.map{$0.description}
					.joined(separator: "\n")
					.replacingOccurrences(of: "\n", with: "\n\t")
				lggDescription = "\(triangleString)"
			}
			
			var gllDescription:String
			
			switch gll
			{
			case .none:
				gllDescription = "none"
				break
			case .inner(let innerNode):
				gllDescription = innerNode.description.replacingOccurrences(of: "\n", with: "\n\t")
				break
			case .leaf(let triangles):
				let triangleString:String = triangles
					.map{$0.description}
					.joined(separator: "\n")
					.replacingOccurrences(of: "\n", with: "\n\t")
				gllDescription = "\(triangleString)"
			}
			
			var glgDescription:String
			
			switch glg
			{
			case .none:
				glgDescription = "none"
				break
			case .inner(let innerNode):
				glgDescription = innerNode.description.replacingOccurrences(of: "\n", with: "\n\t")
				break
			case .leaf(let triangles):
				let triangleString:String = triangles
					.map{$0.description}
					.joined(separator: "\n")
					.replacingOccurrences(of: "\n", with: "\n\t")
				glgDescription = "\(triangleString)"
			}
			
			var gglDescription:String
			
			switch ggl
			{
			case .none:
				gglDescription = "none"
				break
			case .inner(let innerNode):
				gglDescription = innerNode.description.replacingOccurrences(of: "\n", with: "\n\t")
				break
			case .leaf(let triangles):
				let triangleString:String = triangles
					.map{$0.description}
					.joined(separator: "\n")
					.replacingOccurrences(of: "\n", with: "\n\t")
				gglDescription = "\(triangleString)"
			}
			
			var gggDescription:String
			
			switch ggg
			{
			case .none:
				gggDescription = "none"
				break
			case .inner(let innerNode):
				gggDescription = innerNode.description.replacingOccurrences(of: "\n", with: "\n\t")
				break
			case .leaf(let triangles):
				let triangleString:String = triangles
					.map{$0.description}
					.joined(separator: "\n")
					.replacingOccurrences(of: "\n", with: "\n\t")
				gggDescription = "\(triangleString)"
			}
			
			return "Inner Node (\(volume)):"
				+ "\n\tlll:\n\t\t\(lllDescription.replacingOccurrences(of: "\n", with: "\n\t"))"
				+ "\n\tllg:\n\t\t\(llgDescription.replacingOccurrences(of: "\n", with: "\n\t"))"
				+ "\n\tlgl:\n\t\t\(lglDescription.replacingOccurrences(of: "\n", with: "\n\t"))"
				+ "\n\tlgg:\n\t\t\(lggDescription.replacingOccurrences(of: "\n", with: "\n\t"))"
				+ "\n\tgll:\n\t\t\(gllDescription.replacingOccurrences(of: "\n", with: "\n\t"))"
				+ "\n\tglg:\n\t\t\(glgDescription.replacingOccurrences(of: "\n", with: "\n\t"))"
				+ "\n\tggl:\n\t\t\(gglDescription.replacingOccurrences(of: "\n", with: "\n\t"))"
				+ "\n\tggg:\n\t\t\(gggDescription.replacingOccurrences(of: "\n", with: "\n\t"))"
		}
	}
	
	private var root: OctreeInnerNode
	
	var triangles: [Triangle3D]
	
	init(with triangles: [Triangle3D])
	{
		self.triangles = triangles
		root = OctreeInnerNode(with: triangles)
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





