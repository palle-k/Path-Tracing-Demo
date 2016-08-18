//
//  Geometry.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 29.07.16.
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

//MARK: 3D Vectors

struct Vector3D
{
	var x: Float
	var y: Float
	var z: Float
	
	var abs: Float
	{
		return sqrtf(self * self)
	}
	
	var normalized: Vector3D
	{
		return self * (1 / abs)
	}
}

extension Vector3D : CustomStringConvertible
{
	var description: String
	{
		return "(x: \(x), y: \(y), z: \(z))"
	}
}

extension Vector3D : Equatable { }

extension Vector3D : Hashable
{
	var hashValue: Int
	{
		return x.hashValue ^ y.hashValue ^ z.hashValue
	}
}

typealias Point3D = Vector3D

let Vector3DZero  = Vector3D(x: 0, y: 0, z: 0)
let Vector3DUnitX = Vector3D(x: 1, y: 0, z: 0)
let Vector3DUnitY = Vector3D(x: 0, y: 1, z: 0)
let Vector3DUnitZ = Vector3D(x: 0, y: 0, z: 1)


struct Vertex3D
{
	var point: Point3D
	var normal: Vector3D
	var textureCoordinate: TextureCoordinate
}

extension Vertex3D : Equatable { }


//MARK: Barycentric Coordinates

struct BarycentricPoint
{
	let alpha: Float
	let beta: Float
	let gamma: Float
}

extension BarycentricPoint : Equatable { }

extension BarycentricPoint : CustomStringConvertible
{
	var description: String
	{
		return "(alpha: \(alpha), beta: \(beta), gamma: \(gamma))"
	}
}

//MARK: Rays

struct Ray3D
{
	let base: Point3D
	let direction: Vector3D
	
	@inline(__always)
	func point(`for` parameter: Float) -> Point3D
	{
		return base + (direction * parameter)
	}
	
	@inline(__always)
	func findIntersection(with triangle: Triangle3D) -> (rayParameter: Float, barycentric: BarycentricPoint)?
	{
		let bSubA = triangle.b.point - triangle.a.point
		let cSubA = triangle.c.point - triangle.a.point
		let nDir = -direction
		let right = base - triangle.a.point
		
		let det = bSubA.x * cSubA.y * nDir.z
				+ cSubA.x * nDir.y  * bSubA.z
				+ nDir.x  * bSubA.y * cSubA.z
				- nDir.x  * cSubA.y * bSubA.z
				- bSubA.x * nDir.y  * cSubA.z
				- cSubA.x * bSubA.y * nDir.z
		
		guard det != 0 else { return nil }
		
		//solve using cramers rule
		
		let det1 = right.x * cSubA.y * nDir.z
			+ cSubA.x * nDir.y  * right.z
			+ nDir.x  * right.y * cSubA.z
			- nDir.x  * cSubA.y * right.z
			- right.x * nDir.y  * cSubA.z
			- cSubA.x * right.y * nDir.z
		
		let beta = det1 / det
		guard beta >= 0 && beta <= 1.0 else { return nil }
		
		let det2 = bSubA.x * right.y * nDir.z
			+ right.x * nDir.y  * bSubA.z
			+ nDir.x  * bSubA.y * right.z
			- nDir.x  * right.y * bSubA.z
			- bSubA.x * nDir.y  * right.z
			- right.x * bSubA.y * nDir.z
		
		let gamma = det2 / det
		let alpha = 1.0 - gamma - beta
		guard gamma >= 0 && gamma <= 1.0 && alpha >= 0.0 else { return nil }
		
		let det3 = bSubA.x * cSubA.y * right.z
			+ cSubA.x * right.y * bSubA.z
			+ right.x * bSubA.y * cSubA.z
			- right.x * cSubA.y * bSubA.z
			- bSubA.x * right.y * cSubA.z
			- cSubA.x * bSubA.y * right.z
		
		let rayParameter = det3 / det
		guard rayParameter > 0 else { return nil }
		
		return (rayParameter: rayParameter,
		        barycentric: BarycentricPoint(
					alpha: alpha,
					beta: beta,
					gamma: gamma))
	}
}

extension Ray3D : CustomStringConvertible
{
	var description: String
	{
		return "Ray3D (base: \(base), direction: \(direction))"
	}
}

extension Ray3D : Equatable { }


enum RayType
{
	case camera
	case diffuse
	case reflective
	case refractive
}


//MARK: Triangles

//private let defaultShader = DiffuseShader(color: Color(withRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
//private let defaultShader = EmissionShader(color: Color(withRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), strhe)
let defaultShader = DefaultShader(color: Color(withRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
let defaultMaterial = Material(withShader: DefaultShader(color: .white()), named: "Default Material")

struct Triangle3D
{
	let a: Vertex3D
	let b: Vertex3D
	let c: Vertex3D
	var material: Material
	
	var points:[Point3D]
	{
		return [a.point, b.point, c.point]
	}
	
	init(a: Vertex3D, b: Vertex3D, c: Vertex3D, material: Material = defaultMaterial)
	{
		self.a = a
		self.b = b
		self.c = c
		self.material = material
	}
	
	init(a: Point3D, b: Point3D, c: Point3D, material: Material = defaultMaterial)
	{
		let normal = (b-a)⨯(c-a)
		self.a = Vertex3D(point: a, normal: normal, textureCoordinate: TextureCoordinate(u: 0, v: 0))
		self.b = Vertex3D(point: b, normal: normal, textureCoordinate: TextureCoordinate(u: 1, v: 0))
		self.c = Vertex3D(point: c, normal: normal, textureCoordinate: TextureCoordinate(u: 0, v: 1))
		self.material = material
	}
	
	var normal: Vector3D
	{
		return ((b.point-a.point)⨯(c.point-a.point)).normalized
	}
	
	func translated(to point: Point3D) -> Triangle3D
	{
		return Triangle3D(
			a: Vertex3D(point: a.point + point, normal: a.normal, textureCoordinate: a.textureCoordinate),
			b: Vertex3D(point: b.point + point, normal: b.normal, textureCoordinate: b.textureCoordinate),
			c: Vertex3D(point: c.point + point, normal: c.normal, textureCoordinate: c.textureCoordinate),
			material: material)
	}
	
	func scaled(_ factor: Float) -> Triangle3D
	{
		return Triangle3D(
			a: Vertex3D(point: a.point * factor, normal: a.normal, textureCoordinate: a.textureCoordinate),
			b: Vertex3D(point: b.point * factor, normal: b.normal, textureCoordinate: b.textureCoordinate),
			c: Vertex3D(point: c.point * factor, normal: c.normal, textureCoordinate: c.textureCoordinate),
			material: material)
	}
}

extension Triangle3D : CustomStringConvertible
{
	var description: String
	{
		return "Triangle3D (\(a), \(b), \(c))"
	}
}

extension Triangle3D : Equatable { }

//MARK: Operator Declarations

infix operator ⨯ : MultiplicationPrecedence
infix operator <-> : MultiplicationPrecedence
infix operator  ∠ : MultiplicationPrecedence

//MARK: Vector to Vector Real Arithmetic

@inline(__always)
func ⨯ (left: Vector3D, right: Vector3D) -> Vector3D
{
	return Vector3D(
		x: left.y * right.z - left.z * right.y,
		y: left.z * right.x - left.x * right.z,
		z: left.x * right.y - left.y * right.x)
}

@inline(__always)
func * (left: Vector3D, right: Vector3D) -> Float
{
	return left.x * right.x + left.y * right.y + left.z * right.z
}

@inline(__always)
func ∠ (left: Vector3D, right: Vector3D) -> Float
{
	return abs(acosf(left.normalized * right.normalized))
}

@inline(__always)
func + (left: Vector3D, right: Vector3D) -> Vector3D
{
	return Vector3D(
		x: left.x + right.x,
		y: left.y + right.y,
		z: left.z + right.z)
}

@inline(__always)
func - (left: Vector3D, right: Vector3D) -> Vector3D
{
	return Vector3D(
		x: left.x - right.x,
		y: left.y - right.y,
		z: left.z - right.z)
}

@inline(__always)
func <-> (left: Point3D, right: Point3D) -> Float
{
	return (left-right).abs
}

//MARK: Vector to Ray Real Arithmetic

@inline(__always)
func <-> (left: Ray3D, right: Point3D) -> Float
{
	return ((right - left.base) ⨯ left.direction).abs / left.direction.abs
}

@inline(__always)
func <-> (left: Point3D, right: Ray3D) -> Float
{
	return right <-> left
}

//MARK: Vector to Scalar Real Arithmetic

@inline(__always)
func * (left: Vector3D, right: Float) -> Vector3D
{
	return Vector3D(
		x: left.x * right,
		y: left.y * right,
		z: left.z * right)
}

@inline(__always)
func * (left: Float, right: Vector3D) -> Vector3D
{
	return right * left
}

//MARK: Single Vector Operations

@inline(__always)
prefix func - (right: Vector3D) -> Vector3D
{
	return Vector3D(
		x: -right.x,
		y: -right.y,
		z: -right.z)
}

//MARK: Equatables

@inline(__always)
func == (left: Vector3D, right: Vector3D) -> Bool
{
	return left.x == right.x && left.y == right.y && left.z == right.z
}

@inline(__always)
func == (left: BarycentricPoint, right: BarycentricPoint) -> Bool
{
	return left.alpha == right.alpha && left.beta == right.beta && left.gamma == right.gamma
}

@inline(__always)
func == (left: Ray3D, right: Ray3D) -> Bool
{
	return left.base == right.base && left.direction == right.direction
}

@inline(__always)
func == (left: Triangle3D, right: Triangle3D) -> Bool
{
	return left.a == right.a && left.b == right.b && left.c == right.c
}

@inline(__always)
func == (left: Vertex3D, right: Vertex3D) -> Bool
{
	return left.point == right.point && left.normal == right.normal
}

