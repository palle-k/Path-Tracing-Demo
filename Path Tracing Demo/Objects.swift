//
//  Objects.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 31.07.16.
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

protocol Object3D : CustomStringConvertible
{
	var location: Point3D { get set }
	var scale: Float { get set }
	var rotation: (alpha:Float, beta:Float, gamma:Float) { get set }
	
	var transformed:[Triangle3D] { get }
	
	var name: String { get }
	
	var materials:[Material] { get }
	
	nonmutating func translated(to point: Point3D) -> Object3D
	nonmutating func scaled(_ factor: Float) -> Object3D
	
	mutating func assignMaterial(_ material: Material)
}

struct ExplicitTriangleMesh3D : Object3D
{
	var location: Point3D
	var scale: Float
	var rotation: (alpha:Float, beta:Float, gamma:Float)
	var triangles:[Triangle3D]
	var name: String
	var materials: [Material]
	{
		return triangles.map{$0.material}.distinct()
	}
	
	init(location: Point3D, scale: Float, rotation: (alpha:Float, beta:Float, gamma:Float), triangles: [Triangle3D], name: String = "unnamed")
	{
		self.location = location
		self.scale = scale
		self.rotation = rotation
		self.triangles = triangles
		self.name = name
	}
	
	init(triangles: [Triangle3D])
	{
		self.triangles = triangles
		location = Vector3DZero
		scale = 1.0
		rotation = (alpha: 0.0, beta: 0.0, gamma: 0.0)
		self.name = "unnamed"
	}
	
	var transformed:[Triangle3D]
	{
		let rotationMatrix = Matrix(rotatingWithAlpha: rotation.alpha, beta: rotation.beta, gamma: rotation.gamma)
		
		//FIXME: Normal Rotation
		
		return triangles
			.map
			{
				// Applying rotation. The transformation matrix for normals is identical, because (A^-1)^T=A for rotation matrices
				Triangle3D(
					a: Vertex3D(point: rotationMatrix * $0.a.point, normal: rotationMatrix * $0.a.normal, textureCoordinate: $0.a.textureCoordinate),
					b: Vertex3D(point: rotationMatrix * $0.b.point, normal: rotationMatrix * $0.b.normal, textureCoordinate: $0.b.textureCoordinate),
					c: Vertex3D(point: rotationMatrix * $0.c.point, normal: rotationMatrix * $0.c.normal, textureCoordinate: $0.c.textureCoordinate),
					material: $0.material)
			}
			.map{$0.scaled(self.scale)}
			.map{$0.translated(to: self.location)}
	}
	
	func translated(to point: Point3D) -> Object3D
	{
		return ExplicitTriangleMesh3D(location: location + point, scale: scale, rotation: rotation, triangles: triangles)
	}
	
	func scaled(_ factor: Float) -> Object3D
	{
		return ExplicitTriangleMesh3D(location: location, scale: scale * factor, rotation: rotation, triangles: triangles)
	}
	
	var description: String
	{
		let triangleString = triangles.map{$0.description}.joined(separator: "\n\t- ")
		return "- ExplicitTriangleMesh3D: (location: \(location), scale: \(scale), rotation: \(rotation)\n\t- \(triangleString)"
		//return "Object3D"
	}
	
	mutating func assignMaterial(_ material: Material)
	{
		for i in 0 ..< triangles.count
		{
			triangles[i].material = material
		}
	}
}

//struct IndexedVertexMesh3D : Object3D
//{
//	var location: Point3D
//	var scale: Float
//	var rotation: (alpha:Float, beta:Float, gamma:Float)
//	var vertices: [Point3D]
//	var triangles: [[Int]]
//	
//	var transformed: [Triangle3D]
//	{
//		return triangles
//			.map{[vertices[$0[0]], vertices[$0[1]], vertices[$0[2]]]}
//			.map{Triangle3D(a: $0[0], b: $0[1], c: $0[2])}
//	}
//	
//	func translated(to point: Point3D) -> Object3D
//	{
//		return IndexedVertexMesh3D(location: location + point, scale: scale, rotation: rotation, vertices: vertices, triangles: triangles)
//	}
//	
//	func scaled(_ factor: Float) -> Object3D
//	{
//		return IndexedVertexMesh3D(location: location, scale: scale * factor, rotation: rotation, vertices: vertices, triangles: triangles)
//	}
//	
//	var description: String
//	{
//		return "- SharedVertexMesh3D"
//	}
//}

struct Camera
{
	var location: Point3D
	var rotation: (alpha: Float, beta: Float, gamma: Float)
	var apertureSize: Float
	var focalDistance: Float
	var fieldOfView: Float
}

struct Scene3D : CustomStringConvertible
{
	var objects:[Object3D]
	var camera: Camera
	var ambientColor: Color
	
	var wavefrontString: String
	{
		let triangles = objects.map{$0.transformed}.flatten()
		let vertices = triangles.map{[$0.a, $0.b, $0.c]}.flatten()
		let vertexString = vertices.map{"v \($0.point.x) \($0.point.y) \($0.point.z)"}.joined(separator: "\n")
		let triangleString:String = triangles
			.enumerated()
			.map{$0.offset}
			.map{$0*3+1}
			.map{"f \($0) \($0+1) \($0+2)"}
			.joined(separator: "\n")
		return "# Path tracing tests by PK\n# Vertices\n\(vertexString)\n# Triangles\n\(triangleString)"
	}
		
	var description: String
	{
		return "Scene3D:\n\(objects.map{$0.description}.joined(separator: "\n"))"
	}
	
	var transformed: [Triangle3D]
	{
		let rotationMatrix = Matrix(rotatingWithAlpha: -camera.rotation.alpha, beta: -camera.rotation.beta, gamma: -camera.rotation.gamma)
		return objects
			.flatMap{$0.transformed}
			.map{ $0.translated(to: -camera.location) }
			.map
			{
				Triangle3D(
					a: Vertex3D(point: rotationMatrix * $0.a.point, normal: rotationMatrix * $0.a.normal, textureCoordinate: $0.a.textureCoordinate),
					b: Vertex3D(point: rotationMatrix * $0.b.point, normal: rotationMatrix * $0.b.normal, textureCoordinate: $0.b.textureCoordinate),
					c: Vertex3D(point: rotationMatrix * $0.c.point, normal: rotationMatrix * $0.c.normal, textureCoordinate: $0.c.textureCoordinate),
					material: $0.material)
			}
	}
}
