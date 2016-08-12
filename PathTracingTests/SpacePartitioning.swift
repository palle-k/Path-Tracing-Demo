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
	func nearestIntersectingTriangle(forRay ray: Ray3D) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
}

//Optimized octree (subnodes will be sized to fit their content)
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
		
		func contains(point: Point3D) -> Bool
		{
			guard point.x >= x && point.x <= (x + width)  else { return false }
			guard point.y >= y && point.y <= (y + height) else { return false }
			guard point.z >= z && point.z <= (z + depth)  else { return false }
			return true
		}
		
		func intersects(ray: Ray3D, strict: Bool = false) -> Bool
		{
			let baseBFL = Point3D(x: x, y: y, z: z)
			let baseTBR = baseBFL + Vector3D(x: width, y: height, z: depth)
			
			let tA = baseBFL - ray.base
			let tB = baseTBR - ray.base
			
			var rayDirection = ray.direction
			if rayDirection.x == 0
			{
				rayDirection.x = nextafterf(rayDirection.x, 1)
			}
			
			if rayDirection.y == 0
			{
				rayDirection.y = nextafterf(rayDirection.y, 1)
			}
			
			if rayDirection.z == 0
			{
				rayDirection.z = nextafterf(rayDirection.z, 1)
			}
			
			let tDivA = Vector3D(x: tA.x / rayDirection.x, y: tA.y / rayDirection.y, z: tA.z / ray.direction.z)
			let tDivB = Vector3D(x: tB.x / rayDirection.x, y: tB.y / rayDirection.y, z: tB.z / ray.direction.z)
			
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
	}
	
	private enum OctreeNode
	{
		case inner (OctreeInnerNode)
		case leaf ([Triangle3D])
		case none
	}
	
	private class OctreeInnerNode : CustomStringConvertible
	{
		private let volume: Volume
		
		private let lll: OctreeNode
		private let gll: OctreeNode
		private let lgl: OctreeNode
		private let ggl: OctreeNode
		private let llg: OctreeNode
		private let glg: OctreeNode
		private let lgg: OctreeNode
		private let ggg: OctreeNode
		
		private convenience init(with triangles: [Triangle3D])
		{
			self.init(with: triangles, maxBounds: Volume(containing: triangles.flatMap{[$0.a.point, $0.b.point, $0.c.point]}))
		}
		
		private init(with triangles: [Triangle3D], maxBounds: Volume)
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
					if (triangle.points.map{lllBounds.contains(point: $0)}.reduce(false){$0 || $1})
					{
						return true
					}
					else if lllBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.b.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if lllBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.c.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if lllBounds.intersects(ray: Ray3D(base: triangle.b.point, direction: triangle.c.point - triangle.b.point), strict: true)
					{
						return true
					}
					return false
				}
			let llgBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					if (triangle.points.map{llgBounds.contains(point: $0)}.reduce(false){$0 || $1})
					{
						return true
					}
					else if llgBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.b.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if llgBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.c.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if llgBounds.intersects(ray: Ray3D(base: triangle.b.point, direction: triangle.c.point - triangle.b.point), strict: true)
					{
						return true
					}
					return false
				}
			let lglBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					if (triangle.points.map{lglBounds.contains(point: $0)}.reduce(false){$0 || $1})
					{
						return true
					}
					else if lglBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.b.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if lglBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.c.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if lglBounds.intersects(ray: Ray3D(base: triangle.b.point, direction: triangle.c.point - triangle.b.point), strict: true)
					{
						return true
					}
					return false
				}
			let lggBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					if (triangle.points.map{lggBounds.contains(point: $0)}.reduce(false){$0 || $1})
					{
						return true
					}
					else if lggBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.b.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if lggBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.c.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if lggBounds.intersects(ray: Ray3D(base: triangle.b.point, direction: triangle.c.point - triangle.b.point), strict: true)
					{
						return true
					}
					return false
				}
			let gllBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					if (triangle.points.map{gllBounds.contains(point: $0)}.reduce(false){$0 || $1})
					{
						return true
					}
					else if gllBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.b.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if gllBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.c.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if gllBounds.intersects(ray: Ray3D(base: triangle.b.point, direction: triangle.c.point - triangle.b.point), strict: true)
					{
						return true
					}
					return false
				}
			let glgBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					if (triangle.points.map{glgBounds.contains(point: $0)}.reduce(false){$0 || $1})
					{
						return true
					}
					else if glgBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.b.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if glgBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.c.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if glgBounds.intersects(ray: Ray3D(base: triangle.b.point, direction: triangle.c.point - triangle.b.point), strict: true)
					{
						return true
					}
					return false
				}
			let gglBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					if (triangle.points.map{gglBounds.contains(point: $0)}.reduce(false){$0 || $1})
					{
						return true
					}
					else if gglBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.b.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if gglBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.c.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if gglBounds.intersects(ray: Ray3D(base: triangle.b.point, direction: triangle.c.point - triangle.b.point), strict: true)
					{
						return true
					}
					return false
				}
			let gggBucket:[Triangle3D] = triangles
				.filter
				{ triangle -> Bool in
					if (triangle.points.map{gggBounds.contains(point: $0)}.reduce(false){$0 || $1})
					{
						return true
					}
					else if gggBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.b.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if gggBounds.intersects(ray: Ray3D(base: triangle.a.point, direction: triangle.c.point - triangle.a.point), strict: true)
					{
						return true
					}
					else if gggBounds.intersects(ray: Ray3D(base: triangle.b.point, direction: triangle.c.point - triangle.b.point), strict: true)
					{
						return true
					}
					return false
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
				lll = .inner(OctreeInnerNode(with: lllBucket, maxBounds: lllBounds))
			}
			else if !lllBucket.isEmpty
			{
				lll = .leaf(lllBucket)
			}
			else
			{
				lll = .none
			}
			
			if distinctPoints[1] && llgBucket.count > innerNodeThreshold && llgBucket.count < triangles.count
			{
				llg = .inner(OctreeInnerNode(with: llgBucket, maxBounds: llgBounds))
			}
			else if !llgBucket.isEmpty
			{
				llg = .leaf(llgBucket)
			}
			else
			{
				llg = .none
			}
			
			if distinctPoints[2] && lglBucket.count > innerNodeThreshold && lglBucket.count < triangles.count
			{
				lgl = .inner(OctreeInnerNode(with: lglBucket, maxBounds: lglBounds))
			}
			else if !lglBucket.isEmpty
			{
				lgl = .leaf(lglBucket)
			}
			else
			{
				lgl = .none
			}
			
			if distinctPoints[3] && lggBucket.count > innerNodeThreshold && lggBucket.count < triangles.count
			{
				lgg = .inner(OctreeInnerNode(with: lggBucket, maxBounds: lggBounds))
			}
			else if !lggBucket.isEmpty
			{
				lgg = .leaf(lggBucket)
			}
			else
			{
				lgg = .none
			}
			
			if distinctPoints[4] && gllBucket.count > innerNodeThreshold && gllBucket.count < triangles.count
			{
				gll = .inner(OctreeInnerNode(with: gllBucket, maxBounds: gllBounds))
			}
			else if !gllBucket.isEmpty
			{
				gll = .leaf(gllBucket)
			}
			else
			{
				gll = .none
			}
			
			if distinctPoints[5] && glgBucket.count > innerNodeThreshold && glgBucket.count < triangles.count
			{
				glg = .inner(OctreeInnerNode(with: glgBucket, maxBounds: glgBounds))
			}
			else if !glgBucket.isEmpty
			{
				glg = .leaf(glgBucket)
			}
			else
			{
				glg = .none
			}
			
			if distinctPoints[6] && gglBucket.count > innerNodeThreshold && gglBucket.count < triangles.count
			{
				ggl = .inner(OctreeInnerNode(with: gglBucket, maxBounds: gglBounds))
			}
			else if !gglBucket.isEmpty
			{
				ggl = .leaf(gglBucket)
			}
			else
			{
				ggl = .none
			}
			
			if distinctPoints[7] && gggBucket.count > innerNodeThreshold && gggBucket.count < triangles.count
			{
				ggg = .inner(OctreeInnerNode(with: gggBucket, maxBounds: gggBounds))
			}
			else if !gggBucket.isEmpty
			{
				ggg = .leaf(gggBucket)
			}
			else
			{
				ggg = .none
			}
		}
		
		@inline(__always)
		private final func intersects(ray: Ray3D, betterThan bestIntersection: Float? = nil) -> Bool
		{
			let baseBFL = Point3D(x: volume.x, y: volume.y, z: volume.z)
			let baseTBR = baseBFL + Vector3D(x: volume.width, y: volume.height, z: volume.depth)
			
			let tA = baseBFL - ray.base
			let tB = baseTBR - ray.base
			
			let rayDirection = ray.direction + Vector3D(x: nextafterf(0, 1) * 4.0, y: nextafterf(0, 1) * 4.0, z: nextafterf(0, 1) * 4.0)
			
			let tDivA = Vector3D(x: tA.x / rayDirection.x, y: tA.y / rayDirection.y, z: tA.z / ray.direction.z)
			let tDivB = Vector3D(x: tB.x / rayDirection.x, y: tB.y / rayDirection.y, z: tB.z / ray.direction.z)
			
			let tMax = min(min(max(tDivA.x, tDivB.x), max(tDivA.y, tDivB.y)), max(tDivA.z, tDivB.z))
			
			guard tMax >= 0 else { return false }
			
			let tMin = max(max(min(tDivA.x, tDivB.x), min(tDivA.y, tDivB.y)), min(tDivA.z, tDivB.z))
			
			guard tMax >= tMin && tMin < (bestIntersection ?? Float.infinity) else { return false }
			return true
		}
		
		private final func findTriangle(intersecting ray: Ray3D, betterThan bestIntersectionRay: Float? = nil) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
		{
			guard intersects(ray: ray, betterThan: bestIntersectionRay) else { return nil }
			
			var bestIntersection:(triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)? = nil
			
			for node in [lll, llg, gll, glg, lgl, lgg, ggl, ggg]
			{
				if case let OctreeNode.inner(innerNode) = node
				{
					guard let intersection = innerNode.findTriangle(intersecting: ray, betterThan: bestIntersection?.ray) else { continue }
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
	
	private let root: OctreeInnerNode
	
	init(with triangles: [Triangle3D])
	{
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

//Currently unused (slower than octree. Bug?)
class BSPTree: TriangleStore, CustomStringConvertible
{
	private enum BSPTreeNode
	{
		case inner(InnerNode)
		case leaf([Triangle3D])
		case none
	}
	
	private enum SplittingPlaneOrientation
	{
		case xy
		case xz
		case yz
		
		var pointComparator: (Point3D, Point3D) -> Bool
		{
			switch self
			{
			case .xy:
				return {$0.z < $1.z}
			case .xz:
				return {$0.y < $1.y}
			case .yz:
				return {$0.x < $1.x}
			}
		}
		
		var triangleComparator: (Triangle3D, Triangle3D) -> Bool
		{
			let pc = pointComparator
			return { a, b -> Bool in
				var bb = true
				//∀pb∈B ∃pa∈A: pa<pb
				for pb in b.points
				{
					var smallerExists = false
					for pa in a.points
					{
						smallerExists = smallerExists || pc(pa, pb)
					}
					bb = bb && smallerExists
				}
				return bb
			}
			
		}
	}
	
	private struct Volume: CustomStringConvertible
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
		
		var size: Float
		{
			return width * height * depth
		}
		
		private func contains(point: Point3D) -> Bool
		{
			guard point.x >= x && point.x <= (x + width)  else { return false }
			guard point.y >= y && point.y <= (y + height) else { return false }
			guard point.z >= z && point.z <= (z + depth)  else { return false }
			return true
		}
		
		private func intersects(ray: Ray3D, strict: Bool = false) -> Bool
		{
			let baseBFL = Point3D(x: x, y: y, z: z)
			let baseTBR = baseBFL + Vector3D(x: width, y: height, z: depth)
			
			let tA = baseBFL - ray.base
			let tB = baseTBR - ray.base
			
			var rayDirection = ray.direction
			if rayDirection.x == 0
			{
				rayDirection.x = nextafterf(rayDirection.x, 1)
			}
			
			if rayDirection.y == 0
			{
				rayDirection.y = nextafterf(rayDirection.y, 1)
			}
			
			if rayDirection.z == 0
			{
				rayDirection.z = nextafterf(rayDirection.z, 1)
			}
			
			let tDivA = Vector3D(x: tA.x / rayDirection.x, y: tA.y / rayDirection.y, z: tA.z / ray.direction.z)
			let tDivB = Vector3D(x: tB.x / rayDirection.x, y: tB.y / rayDirection.y, z: tB.z / ray.direction.z)
			
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
		
		private var description: String
		{
			return "x: \(x), y: \(y), z: \(z), w: \(width), h: \(height), d: \(depth)"
		}
	}
	
	private class InnerNode: CustomStringConvertible
	{
		private let volume: Volume
		private let lower:BSPTreeNode
		private let upper:BSPTreeNode
		
		init(triangles:[Triangle3D], volume: Volume, nextSplit: SplittingPlaneOrientation)
		{
			self.volume = volume
			
			let sortedTriangles = triangles.sorted(by: nextSplit.triangleComparator)
			let lowerTriangles = sortedTriangles.limit(n: sortedTriangles.count / 2)
			let upperTriangles = sortedTriangles.limit(n: sortedTriangles.count - lowerTriangles.count, offset: lowerTriangles.count)
			
			let lowerPoints = lowerTriangles.flatMap{[$0.a.point, $0.b.point, $0.c.point]}
			let lowerMinX = lowerPoints.min{$0.x < $1.x}?.x ?? 0
			let lowerMinY = lowerPoints.min{$0.y < $1.y}?.y ?? 0
			let lowerMinZ = lowerPoints.min{$0.z < $1.z}?.z ?? 0
			let lowerMaxX = lowerPoints.max{$0.x < $1.x}?.x ?? 0
			let lowerMaxY = lowerPoints.max{$0.y < $1.y}?.y ?? 0
			let lowerMaxZ = lowerPoints.max{$0.z < $1.z}?.z ?? 0
			
			let upperPoints = upperTriangles.flatMap{[$0.a.point, $0.b.point, $0.c.point]}
			let upperMinX = upperPoints.min{$0.x < $1.x}?.x ?? 0
			let upperMinY = upperPoints.min{$0.y < $1.y}?.y ?? 0
			let upperMinZ = upperPoints.min{$0.z < $1.z}?.z ?? 0
			let upperMaxX = upperPoints.max{$0.x < $1.x}?.x ?? 0
			let upperMaxY = upperPoints.max{$0.y < $1.y}?.y ?? 0
			let upperMaxZ = upperPoints.max{$0.z < $1.z}?.z ?? 0
			
			let lowerDX = lowerMaxX - lowerMinX
			let lowerDY = lowerMaxY - lowerMinY
			let lowerDZ = lowerMaxZ - lowerMinZ
			
			let upperDX = upperMaxX - upperMinX
			let upperDY = upperMaxY - upperMinY
			let upperDZ = upperMaxZ - upperMinZ
			
			let lowerVolume = Volume(x: lowerMinX, y: lowerMinY, z: lowerMinZ, width: lowerDX, height: lowerDY, depth: lowerDZ)
			let upperVolume = Volume(x: upperMinX, y: upperMinY, z: upperMinZ, width: upperDX, height: upperDY, depth: upperDZ)
			
			let capacity = 4
			
			if lowerPoints.count < capacity ||
				(lowerMinX == lowerMaxX &&
				 lowerMinY == lowerMaxY &&
				 lowerMinZ == lowerMaxZ) ||
				lowerTriangles.count == triangles.count
			{
				lower = .leaf(lowerTriangles)
			}
			else
			{
				
				
				let nextSplit: SplittingPlaneOrientation
				
				if lowerDX > lowerDY && lowerDX > lowerDZ
				{
					nextSplit = .yz
				}
				else if lowerDY > lowerDX && lowerDY > lowerDZ
				{
					nextSplit = .xz
				}
				else
				{
					nextSplit = .xy
				}
				
				
				lower = .inner(InnerNode(triangles: lowerTriangles,
				                         volume: lowerVolume,
				                         nextSplit: nextSplit))
			}
			if upperPoints.count < capacity ||
				(upperMinX == upperMaxX &&
				 upperMinY == upperMaxY &&
				 upperMinZ == upperMaxZ) ||
				upperTriangles.count == triangles.count
			{
				upper = .leaf(upperTriangles)
			}
			else
			{
				let nextSplit: SplittingPlaneOrientation
				
				if upperDX > upperDY && upperDX > upperDZ
				{
					nextSplit = .yz
				}
				else if upperDY > upperDX && upperDY > upperDZ
				{
					nextSplit = .xz
				}
				else
				{
					nextSplit = .xy
				}
				
				upper = .inner(InnerNode(triangles: upperTriangles,
				                         volume: upperVolume,
				                         nextSplit: nextSplit))
			}
		}
		
		convenience init(triangles:[Triangle3D])
		{
			let points = triangles.flatMap{[$0.a.point, $0.b.point, $0.c.point]}
			let minX = points.min{$0.x < $1.x}?.x ?? 0
			let minY = points.min{$0.y < $1.y}?.y ?? 0
			let minZ = points.min{$0.z < $1.z}?.z ?? 0
			let maxX = points.max{$0.x < $1.x}?.x ?? 1
			let maxY = points.max{$0.y < $1.y}?.y ?? 1
			let maxZ = points.max{$0.z < $1.z}?.z ?? 1
			
			let dx = maxX - minX
			let dy = maxY - minY
			let dz = maxZ - minZ
			
			let nextSplit: SplittingPlaneOrientation
			
			if dx > dy && dx > dz
			{
				nextSplit = .yz
			}
			else if dy > dx && dy > dz
			{
				nextSplit = .xz
			}
			else
			{
				nextSplit = .xy
			}
			
			let volume = Volume(
				x: minX,
				y: minY,
				z: minZ,
				width: maxX - minX,
				height: maxY - minY,
				depth: maxZ - minZ)
			
			self.init(triangles: triangles, volume: volume, nextSplit: nextSplit)
		}
		
		private final func intersects(ray: Ray3D, betterThan bestIntersection: Float? = nil) -> Bool
		{
			let baseBFL = Point3D(x: volume.x, y: volume.y, z: volume.z)
			let baseTBR = baseBFL + Vector3D(x: volume.width, y: volume.height, z: volume.depth)
			
			let tA = baseBFL - ray.base
			let tB = baseTBR - ray.base
			
			let rayDirection = ray.direction + Vector3D(x: nextafterf(0, 1) * 4.0, y: nextafterf(0, 1) * 4.0, z: nextafterf(0, 1) * 4.0)
			
			let tDivA = Vector3D(x: tA.x / rayDirection.x, y: tA.y / rayDirection.y, z: tA.z / ray.direction.z)
			let tDivB = Vector3D(x: tB.x / rayDirection.x, y: tB.y / rayDirection.y, z: tB.z / ray.direction.z)
			
			let tMax = min(min(max(tDivA.x, tDivB.x), max(tDivA.y, tDivB.y)), max(tDivA.z, tDivB.z))
			
			guard tMax >= 0 else { return false }
			
			let tMin = max(max(min(tDivA.x, tDivB.x), min(tDivA.y, tDivB.y)), min(tDivA.z, tDivB.z))
			
			guard tMax >= tMin && tMin < (bestIntersection ?? Float.infinity) else { return false }
			return true
		}
		
		private final func nearestIntersectingTriangle(forRay ray: Ray3D, betterThan bestIntersection: Float? = nil) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
		{
			guard intersects(ray: ray, betterThan: bestIntersection) else { return nil }
			var bestIntersection: (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)? = nil
			for subnode in [lower, upper]
			{
				if case let .inner(innerNode) = subnode
				{
					guard let subnodeIntersection = innerNode.nearestIntersectingTriangle(forRay: ray, betterThan: nil) else { continue }
					if bestIntersection == nil || bestIntersection?.ray > subnodeIntersection.ray
					{
						bestIntersection = subnodeIntersection
					}
				}
				else if case let .leaf(triangles) = subnode
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
			let lowerDescription:String
			if case let .inner(innerNode) = lower
			{
				lowerDescription = innerNode.description.replacingOccurrences(of: "\n", with: "\n\t")
			}
			else if case let .leaf(triangles) = lower
			{
				lowerDescription = "\tLeaf (\(triangles.count) triangles)"
			}
			else
			{
				lowerDescription = "None"
			}
			let upperDescription:String
			if case let .inner(innerNode) = upper
			{
				upperDescription = innerNode.description.replacingOccurrences(of: "\n", with: "\n\t")
			}
			else if case let .leaf(triangles) = upper
			{
				upperDescription = "\tLeaf (\(triangles.count) triangles)"
			}
			else
			{
				upperDescription = "None"
			}
			return "Inner \(volume)\n\t\(lowerDescription)\n\t\(upperDescription)"
		}
	}
	
	private let root:InnerNode
	
	init(with triangles: [Triangle3D])
	{
		root = InnerNode(triangles: triangles)
	}
	
	final func nearestIntersectingTriangle(forRay ray: Ray3D) -> (triangle: Triangle3D, ray: Float, barycentricIntersection: BarycentricPoint)?
	{
		return root.nearestIntersectingTriangle(forRay: ray)
	}
	
	var description: String
	{
		return "BHVTree:\n\(root.description)"
	}
}
