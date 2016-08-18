//
//  Shading.swift
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


struct Color
{
	var red:   Float
	var green: Float
	var blue:  Float
	var alpha: Float
	
	var red8: UInt8
	{
		get
		{
			return UInt8(min(max(red, 0.0), 1.0) * 255)
		}
		
		set (new)
		{
			self.red = Float(new) / 255.0
		}
	}
	
	var green8: UInt8
	{
		get
		{
			return UInt8(min(max(green, 0.0), 1.0) * 255)
		}
		
		set (new)
		{
			self.green = Float(new) / 255.0
		}
	}
	
	var blue8: UInt8
	{
		get
		{
			return UInt8(min(max(blue, 0.0), 1.0) * 255)
		}
		
		set (new)
		{
			self.blue = Float(new) / 255.0
		}
	}
	
	var alpha8: UInt8
	{
		get
		{
			return UInt8(min(max(alpha, 0.0), 1.0) * 255)
		}
		
		set (new)
		{
			self.alpha = Float(new) / 255
		}
	}
	
	var red16: UInt16
	{
		get
		{
			return UInt16(min(max(red, 0.0), 1.0) * 65535)
		}
		
		set (new)
		{
			self.red = Float(new) / 65535
		}
	}
	
	var green16: UInt16
	{
		get
		{
			return UInt16(min(max(green, 0.0), 1.0) * 65535)
		}
		
		set (new)
		{
			self.green = Float(new) / 65535
		}
	}
	
	var blue16: UInt16
	{
		get
		{
			return UInt16(min(max(blue, 0.0), 1.0) * 65535)
		}
		
		set (new)
		{
			self.blue = Float(new) / 65535
		}
	}
	
	var alpha16: UInt16
	{
		get
		{
			return UInt16(min(max(alpha, 0.0), 1.0) * 65535)
		}
		
		set (new)
		{
			self.alpha = Float(new) / 65535
		}
	}
	
	var premultipliedAlpha: Color
	{
		return Color(withRed: self.red / self.alpha, green: self.green / self.alpha, blue: self.blue / self.alpha, alpha: self.alpha)
	}
	
	var brightness: Float
	{
		return sqrt(red * red + green * green + blue * blue) * 0.577350269
	}
	
	var clamped: Color
	{
		return Color(withRed: max(min(red, 1.0), 0.0), green: max(min(green, 1.0), 0.0), blue: max(min(blue, 1.0), 0.0), alpha: max(min(alpha, 1.0), 0.0))
	}
	
	init(withRed red: Float, green: Float, blue: Float, alpha: Float)
	{
		self.red   = red
		self.green = green
		self.blue  = blue
		self.alpha = alpha
	}
	
	init(withRed red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)
	{
		self.red   = Float(red)   / 255.0
		self.green = Float(green) / 255.0
		self.blue  = Float(blue)  / 255.0
		self.alpha = Float(alpha) / 255.0
	}
	
	init(withRed red: UInt16, green: UInt16, blue: UInt16, alpha: UInt16)
	{
		self.red   = Float(red)   / 65535.0
		self.green = Float(green) / 65535.0
		self.blue  = Float(blue)  / 65535.0
		self.alpha = Float(alpha) / 65535.0
	}
	
	static func white() -> Color
	{
		return Color(withRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
	}
	
	static func black() -> Color
	{
		return Color(withRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
	}
	
	static func clear() -> Color
	{
		return Color(withRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
	}
}

extension Color: CustomStringConvertible
{
	var description: String
	{
		return "Color (r: \(red8), g: \(green8), b: \(blue8), a: \(alpha8))"
	}
}


func * (left: Color, right: Color) -> Color
{
	return Color(withRed: left.red * right.red,
	             green: left.green * right.green,
	             blue: left.blue   * right.blue,
	             alpha: left.alpha * right.alpha)
}

func * (left: Color, right: Float) -> Color
{
	return Color(withRed: left.red * right,
	             green: left.green * right,
	             blue: left.blue   * right,
	             alpha: left.alpha * right)
}

func * (left: Float, right: Color) -> Color
{
	return Color(withRed: left * right.red,
	             green:   left * right.green,
	             blue:    left * right.blue,
	             alpha:   left * right.alpha)
}

func + (left: Color, right: Color) -> Color
{
	return Color(withRed: left.red + right.red,
	             green: left.green + right.green,
	             blue: left.blue   + right.blue,
	             alpha: left.alpha + right.alpha)
}

class Material
{
	var shader: Shader
	var name: String
	
	init(withShader shader: Shader, named name: String)
	{
		self.shader = shader
		self.name = name
	}
}

extension Material: CustomStringConvertible
{
	var description: String
	{
		return "Material \(name): \(shader)"
	}
}

protocol Shader: class
{
	var color: Color { get }
	var texture: Texture? { get }
	
	func color(forTriangle triangle: Triangle3D,
	           at barycentricIntersectionCoordinates: BarycentricPoint,
	           point: Point3D,
	           rayDirection: Vector3D,
	           sceneGeometry: TriangleStore,
	           environmentShader: EnvironmentShader,
	           previousColor: Color,
	           maximumRayDepth: Int) -> Color
}

extension Shader
{
	func textureColor(forTriangle triangle: Triangle3D, withIntersectionCoordinates intersectionCoordinates: BarycentricPoint, atAngle angle: Float = Float(M_PI_2)) -> Color
	{
		let color:Color
		if let texture = self.texture
		{
			let textureCoordinate = triangle.a.textureCoordinate * intersectionCoordinates.alpha +
				triangle.b.textureCoordinate * intersectionCoordinates.beta +
				triangle.c.textureCoordinate * intersectionCoordinates.gamma
			
			color = texture.color(for: textureCoordinate, atAngle: angle)
		}
		else
		{
			color = self.color
		}
		return color
	}
}


class DefaultShader: Shader
{
	var color: Color
	var texture: Texture?
	
	init(color: Color, texture: Texture? = nil)
	{
		self.color = color
		self.texture = texture
	}
	
	func color(forTriangle triangle: Triangle3D,
	           at barycentricIntersectionCoordinates: BarycentricPoint,
	           point: Point3D,
	           rayDirection: Vector3D,
	           sceneGeometry: TriangleStore,
	           environmentShader: EnvironmentShader,
	           previousColor: Color,
	           maximumRayDepth: Int) -> Color
	{
		let normal  = (triangle.a.normal * barycentricIntersectionCoordinates.alpha
					+ triangle.b.normal * barycentricIntersectionCoordinates.beta
					+ triangle.c.normal * barycentricIntersectionCoordinates.gamma).normalized
		let ray = rayDirection
		let brightness = 0.66667 * abs(normal * ray) + 0.33333
		let color = textureColor(forTriangle: triangle, withIntersectionCoordinates: barycentricIntersectionCoordinates)
		return color * brightness
	}
}

extension DefaultShader: CustomStringConvertible
{
	var description: String
	{
		return "DefaultShader (color: \(color), texture: \(texture))"
	}
}


class DiffuseShader: Shader
{
	
	var color: Color
	var texture: Texture?
	
	init(color: Color, texture: Texture? = nil)
	{
		self.color = color
		self.texture = texture
	}
	
	func color(forTriangle triangle: Triangle3D,
	           at barycentricIntersectionCoordinates: BarycentricPoint,
	           point: Point3D, rayDirection: Vector3D,
	           sceneGeometry: TriangleStore,
	           environmentShader: EnvironmentShader,
	           previousColor: Color,
	           maximumRayDepth: Int) -> Color
	{
		let color = self.textureColor(forTriangle: triangle, withIntersectionCoordinates: barycentricIntersectionCoordinates)
		guard (color * previousColor).brightness > 0.001 else { return .black() }
		
		let normal  = triangle.a.normal * barycentricIntersectionCoordinates.alpha
			+ triangle.b.normal * barycentricIntersectionCoordinates.beta
			+ triangle.c.normal * barycentricIntersectionCoordinates.gamma
		var outgoingRayDirection = Vector3D(x: Float(drand48() * 2.0 - 1.0),
		                                    y: Float(drand48() * 2.0 - 1.0),
		                                    z: Float(drand48() * 2.0 - 1.0)).normalized
		if outgoingRayDirection * normal < 0
		{
			outgoingRayDirection = -outgoingRayDirection
		}

		let base = point + normal * 0.001
		let ray = Ray3D(base: base, direction: outgoingRayDirection)
		
		if let nextIntersection = sceneGeometry.nearestIntersectingTriangle(forRay: ray)
		{
			if maximumRayDepth > 0
			{
				let nextColor = nextIntersection.triangle.material.shader.color(
					forTriangle:	   nextIntersection.triangle,
					at:				   nextIntersection.barycentricIntersection,
					point:			   ray.point(for: nextIntersection.ray),
					rayDirection:	   outgoingRayDirection,
					sceneGeometry:	   sceneGeometry,
					environmentShader: environmentShader,
					previousColor:	   previousColor * color,
					maximumRayDepth:   maximumRayDepth - 1)
				return nextColor * color
			}
			else
			{
				return Color(withRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
			}
		}
		else
		{
			return environmentShader.environmentColor(for: outgoingRayDirection) * color
		}
	}
}

extension DiffuseShader: CustomStringConvertible
{
	var description: String
	{
		return "DiffuseShader (color: \(color), texture: \(texture))"
	}
}

class EmissionShader: Shader
{
	var strength: Float
	var color: Color
	var texture: Texture?
	init(strength: Float, color: Color, texture: Texture? = nil)
	{
		self.strength = strength
		self.color = color
		self.texture = texture
	}
	
	func color(forTriangle triangle: Triangle3D,
	           at barycentricIntersectionCoordinates: BarycentricPoint,
	           point: Point3D,
	           rayDirection: Vector3D,
	           sceneGeometry: TriangleStore,
	           environmentShader: EnvironmentShader,
	           previousColor: Color,
	           maximumRayDepth: Int) -> Color
	{
		let color = textureColor(forTriangle: triangle, withIntersectionCoordinates: barycentricIntersectionCoordinates)
		return color * strength
	}
}

extension EmissionShader: CustomStringConvertible
{
	var description: String
	{
		return "EmissionShader (color: \(color), texture: \(texture), strength: \(strength))"
	}
}


class ReflectionShader: Shader
{
	var color: Color
	var texture: Texture?
	var roughness: Float
	
	init(color: Color, roughness: Float, texture: Texture? = nil)
	{
		self.color = color
		self.roughness = roughness
		self.texture = texture
	}
	
	func color(forTriangle triangle: Triangle3D,
	           at barycentricIntersectionCoordinates: BarycentricPoint,
	           point: Point3D,
	           rayDirection: Vector3D,
	           sceneGeometry: TriangleStore,
	           environmentShader: EnvironmentShader,
	           previousColor: Color,
	           maximumRayDepth: Int) -> Color
	{
		let color = self.textureColor(forTriangle: triangle, withIntersectionCoordinates: barycentricIntersectionCoordinates)
		guard (color * previousColor).brightness > 0.001 else { return .black() }
		
		var normal  = (triangle.a.normal * barycentricIntersectionCoordinates.alpha
			+ triangle.b.normal * barycentricIntersectionCoordinates.beta
			+ triangle.c.normal * barycentricIntersectionCoordinates.gamma).normalized
		
		let toCamera = -rayDirection
		
		if rayDirection * normal < 0
		{
			normal = -normal
		}
		
		var outgoingRayDirection = (toCamera - 2 * (toCamera - (normal * toCamera) * normal)).normalized
		
		if roughness != 0.0
		{
			//inverse of the sigmoid function scaled by the roughness factor
			let roughnessFactor = roughness * roughness
			let randomizedOutgoingRayDirection = Vector3D(x: -logf(1.0 / nextafterf(Float(drand48()), 0.5) - 1.0),
			                                              y: -logf(1.0 / nextafterf(Float(drand48()), 0.5) - 1.0),
			                                              z: -logf(1.0 / nextafterf(Float(drand48()), 0.5) - 1.0)) * roughnessFactor
			
			outgoingRayDirection = (randomizedOutgoingRayDirection + outgoingRayDirection).normalized
			if outgoingRayDirection * normal < 0
			{
				outgoingRayDirection = -outgoingRayDirection
			}
		}
		
		let base = point + outgoingRayDirection * 0.001
		let ray = Ray3D(base: base, direction: outgoingRayDirection)
		
		if let nextIntersection = sceneGeometry.nearestIntersectingTriangle(forRay: ray)
		{
			if maximumRayDepth > 0
			{
				let nextColor = nextIntersection.triangle.material.shader.color(
					forTriangle:	   nextIntersection.triangle,
					at:				   nextIntersection.barycentricIntersection,
					point:			   ray.point(for: nextIntersection.ray),
					rayDirection:      outgoingRayDirection,
					sceneGeometry:	   sceneGeometry,
					environmentShader: environmentShader,
					previousColor:     previousColor * color,
					maximumRayDepth:   maximumRayDepth - 1)
				return nextColor * color
			}
			else
			{
				return Color(withRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
			}
		}
		else
		{
			return environmentShader.environmentColor(for: outgoingRayDirection) * color
		}
	}
}

extension ReflectionShader: CustomStringConvertible
{
	var description: String
	{
		return "ReflectionShader (color: \(color), texture: \(texture), roughness: \(roughness))"
	}
}


class RefractionShader: Shader
{
	var color: Color
	var texture: Texture?
	
	var volumeColor: Color
	var absorptionStrength: Float
	
	var indexOfRefraction: Float
	var roughness: Float
	
	init(color: Color, texture: Texture? = nil, indexOfRefraction: Float, roughness: Float, volumeColor: Color = .white(), absorptionStrength: Float = 0.0)
	{
		self.color = color
		self.texture = texture
		self.indexOfRefraction = indexOfRefraction
		self.roughness = roughness
		self.volumeColor = volumeColor
		self.absorptionStrength = absorptionStrength
	}
	
	func color(forTriangle triangle: Triangle3D,
	           at barycentricIntersectionCoordinates: BarycentricPoint,
	           point: Point3D,
	           rayDirection: Vector3D,
	           sceneGeometry: TriangleStore,
	           environmentShader: EnvironmentShader,
	           previousColor: Color,
	           maximumRayDepth: Int) -> Color
	{
		let color = self.textureColor(forTriangle: triangle, withIntersectionCoordinates: barycentricIntersectionCoordinates)
		guard (color * previousColor).brightness > 0.001 else { return .black() }
		
		var normal  = (triangle.a.normal * barycentricIntersectionCoordinates.alpha
			+ triangle.b.normal * barycentricIntersectionCoordinates.beta
			+ triangle.c.normal * barycentricIntersectionCoordinates.gamma).normalized
		
		let ior: Float
		let incoming: Bool
		
		if normal * rayDirection <= 0 //into the object
		{
			ior = self.indexOfRefraction
			incoming = true
		}
		else //out of the object
		{
			ior = 1 / self.indexOfRefraction
			normal = -normal
			incoming = false
		}
		
		let iorInv = 1.0 / ior
		
		let cosIncident = abs(normal * rayDirection)
		let sinIncidentSquared = 1 - cosIncident * cosIncident
		
		var transmissionRayDirection = ((iorInv * rayDirection) +
			(iorInv * cosIncident - sqrt(1.0 - iorInv * iorInv * sinIncidentSquared)) * normal)
			.normalized
		
		let cosOutgoing = abs(normal * transmissionRayDirection)
		
		let reflectanceCrossPolarizedSqrt = (cosIncident - ior * cosOutgoing) / (cosIncident + ior * cosOutgoing)
		let reflectanceCrossPolarized = reflectanceCrossPolarizedSqrt * reflectanceCrossPolarizedSqrt
		
		let reflectanceParallelPolarizedSqrt = (ior * cosIncident - cosOutgoing) / (ior * cosIncident + cosOutgoing)
		let reflectanceParallelPolarized = reflectanceParallelPolarizedSqrt * reflectanceParallelPolarizedSqrt
		
		var reflectance = (reflectanceCrossPolarized + reflectanceParallelPolarized) * 0.5
		reflectance = reflectance.isNaN ? 1.0 : reflectance
		
		let transmittance = 1.0 - reflectance
		
		let transmittedColor: Color
		
		if transmittance > 0.001
		{
			if roughness != 0.0
			{
				//let roughnessFactor = roughness * abs(cos(transmissionRayDirection ∠ normal))
				let roughnessFactor = roughness * roughness
				let randomizedOutgoingRayDirection = Vector3D(x: -logf(1.0 / nextafterf(Float(drand48()), 0.5) - 1.0),
				                                              y: -logf(1.0 / nextafterf(Float(drand48()), 0.5) - 1.0),
				                                              z: -logf(1.0 / nextafterf(Float(drand48()), 0.5) - 1.0)) * roughnessFactor
				
				transmissionRayDirection = (randomizedOutgoingRayDirection + transmissionRayDirection).normalized
				if transmissionRayDirection * normal > 0
				{
					transmissionRayDirection = -transmissionRayDirection
				}
			}
			
			let base = point + transmissionRayDirection * 0.001
			let ray = Ray3D(base: base, direction: transmissionRayDirection)
			
			transmittedColor = getTransmittedColor(ray: ray, sceneGeometry: sceneGeometry, color: color, maximumRayDepth: maximumRayDepth, previousColor: color * previousColor * transmittance, environmentShader: environmentShader, incoming: incoming)
		}
		else
		{
			transmittedColor = .black()
		}
		
		let reflectedColor: Color
		
		if reflectance > 0.001
		{
			var reflectionRayDirection = (-rayDirection - 2 * (-rayDirection - (normal * -rayDirection) * normal)).normalized
			
			if roughness != 0.0
			{
				let roughnessFactor = roughness * roughness
				let randomizedOutgoingRayDirection = Vector3D(x: -logf(1.0 / nextafterf(Float(drand48()), 0.5) - 1.0),
				                                              y: -logf(1.0 / nextafterf(Float(drand48()), 0.5) - 1.0),
				                                              z: -logf(1.0 / nextafterf(Float(drand48()), 0.5) - 1.0)) * roughnessFactor
				
				reflectionRayDirection = (randomizedOutgoingRayDirection + reflectionRayDirection).normalized
				if reflectionRayDirection * normal < 0
				{
					reflectionRayDirection = -reflectionRayDirection
				}
			}
			
			let reflectedBase = point + reflectionRayDirection * 0.001
			let reflectedRay = Ray3D(base: reflectedBase, direction: reflectionRayDirection)
			
			reflectedColor = getReflectedColor(ray: reflectedRay, sceneGeometry: sceneGeometry, color: color, maximumRayDepth: maximumRayDepth, previousColor: color * previousColor * reflectance, environmentShader: environmentShader, incoming: incoming)
		}
		else
		{
			reflectedColor = .black()
		}
		
		return transmittedColor * transmittance + reflectedColor * reflectance
	}
	
	@inline(__always)
	private func getTransmittedColor(ray: Ray3D, sceneGeometry: TriangleStore, color: Color, maximumRayDepth: Int, previousColor: Color, environmentShader: EnvironmentShader, incoming: Bool) -> Color
	{
		if let nextIntersection = sceneGeometry.nearestIntersectingTriangle(forRay: ray)
		{
			if maximumRayDepth > 0
			{
				let nextColor = nextIntersection.triangle.material.shader.color(
					forTriangle: nextIntersection.triangle,
					at: nextIntersection.barycentricIntersection,
					point: ray.point(for: nextIntersection.ray),
					rayDirection: ray.direction,
					sceneGeometry: sceneGeometry,
					environmentShader: environmentShader,
					previousColor: previousColor,
					maximumRayDepth: maximumRayDepth - 1)
				
				let volume: Color
				
				if incoming && absorptionStrength > 0
				{
					let volumeFactor = min(absorptionStrength * nextIntersection.ray, 1.0)
					volume = (Color.white() * (1.0 - volumeFactor)) + (volumeColor * volumeFactor)
				}
				else
				{
					volume = .white()
				}
				
				return nextColor * color * volume
			}
			else
			{
				return Color(withRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
			}
		}
		else
		{
			return environmentShader.environmentColor(for: ray.direction) * color
		}
	}
	
	@inline(__always)
	private func getReflectedColor(ray: Ray3D, sceneGeometry: TriangleStore, color: Color, maximumRayDepth: Int, previousColor: Color, environmentShader: EnvironmentShader, incoming: Bool) -> Color
	{
		if let nextIntersection = sceneGeometry.nearestIntersectingTriangle(forRay: ray)
		{
			if maximumRayDepth > 0
			{
				let nextColor = nextIntersection.triangle.material.shader.color(
					forTriangle: nextIntersection.triangle,
					at: nextIntersection.barycentricIntersection,
					point: ray.point(for: nextIntersection.ray),
					rayDirection: ray.direction,
					sceneGeometry: sceneGeometry,
					environmentShader: environmentShader,
					previousColor: previousColor,
					maximumRayDepth: maximumRayDepth - 1)
				
				let volume: Color
				
				if !incoming && absorptionStrength > 0
				{
					let volumeFactor = min(absorptionStrength * nextIntersection.ray, 1.0)
					volume = (Color.white() * (1.0 - volumeFactor)) + (volumeColor * volumeFactor)
				}
				else
				{
					volume = .white()
				}
				
				return nextColor * color * volume
			}
			else
			{
				return Color(withRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
			}
		}
		else
		{
			return environmentShader.environmentColor(for: ray.direction) * color
		}
	}
}

extension RefractionShader: CustomStringConvertible
{
	var description: String
	{
		return "RefractionShader (color: \(color), texture: \(texture), index of refraction: \(indexOfRefraction), roughness: \(roughness), depth attenuation color: \(volumeColor), depth attenuation strength: \(absorptionStrength))"
	}
}

class SubsurfaceScatteringShader: Shader
{
	var color: Color
	let texture: Texture?
	var strength: Float
	
	
	init(color: Color, strength: Float)
	{
		self.color = color
		self.texture = nil
		self.strength = strength
	}
	
	func color(forTriangle triangle: Triangle3D,
	           at barycentricIntersectionCoordinates: BarycentricPoint,
	           point: Point3D,
	           rayDirection: Vector3D,
	           sceneGeometry: TriangleStore,
	           environmentShader: EnvironmentShader,
	           previousColor: Color,
	           maximumRayDepth: Int) -> Color
	{
		
		let color = self.textureColor(forTriangle: triangle, withIntersectionCoordinates: barycentricIntersectionCoordinates)
		guard (color * previousColor).brightness > 0.001 else { return .black() }
		
		let normal  = triangle.a.normal * barycentricIntersectionCoordinates.alpha
			+ triangle.b.normal * barycentricIntersectionCoordinates.beta
			+ triangle.c.normal * barycentricIntersectionCoordinates.gamma
		
		var outgoingRayDirection = Vector3D(x: Float(drand48() * 2.0 - 1.0),
		                                    y: Float(drand48() * 2.0 - 1.0),
		                                    z: Float(drand48() * 2.0 - 1.0)).normalized
		if outgoingRayDirection * normal > 0
		{
			outgoingRayDirection = -outgoingRayDirection
		}
		
		var currentColor:Color = .white()
		
		for scatterCount in 1 ... maximumRayDepth
		{
			let base = point + outgoingRayDirection * 0.001
			let ray = Ray3D(base: base, direction: outgoingRayDirection)
			let nextScatterDistance = Float(drand48()) / strength
			if let nextIntersection = sceneGeometry.nearestIntersectingTriangle(forRay: ray), nextIntersection.ray < nextScatterDistance
			{
				let nextColor = nextIntersection.triangle.material.shader.color(
					forTriangle: nextIntersection.triangle,
					at: nextIntersection.barycentricIntersection,
					point: ray.point(for: nextIntersection.ray),
					rayDirection: ray.direction,
					sceneGeometry: sceneGeometry,
					environmentShader: environmentShader,
					previousColor: previousColor,
					maximumRayDepth: maximumRayDepth - scatterCount)
				
				return currentColor * (((1.0 - nextIntersection.ray) * .white()) + (nextIntersection.ray * color)) * nextColor
			}
			
			currentColor = currentColor * (((1.0 - nextScatterDistance * strength) * .white()) + (nextScatterDistance * strength * color))
			
			outgoingRayDirection = Vector3D(x: Float(drand48() * 2.0 - 1.0),
											y: Float(drand48() * 2.0 - 1.0),
											z: Float(drand48() * 2.0 - 1.0)).normalized
		}
		
		return color
	}
}

class AddShader: Shader
{
	var shader1: Shader
	var shader2: Shader
	let color: Color = Color(withRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
	let texture: Texture? = nil
	
	init(with shader1: Shader, and shader2: Shader)
	{
		self.shader1 = shader1
		self.shader2 = shader2
	}
	
	func color(forTriangle triangle: Triangle3D,
	           at barycentricIntersectionCoordinates: BarycentricPoint,
	           point: Point3D,
	           rayDirection: Vector3D,
	           sceneGeometry: TriangleStore,
	           environmentShader: EnvironmentShader,
	           previousColor: Color,
	           maximumRayDepth: Int) -> Color
	{
		let shader1Result = shader1.color(forTriangle: triangle,
		                                  at: barycentricIntersectionCoordinates,
		                                  point: point,
		                                  rayDirection: rayDirection,
		                                  sceneGeometry: sceneGeometry,
		                                  environmentShader: environmentShader,
		                                  previousColor: previousColor,
		                                  maximumRayDepth: maximumRayDepth)
		
		let shader2Result = shader2.color(forTriangle: triangle,
		                                  at: barycentricIntersectionCoordinates,
		                                  point: point,
		                                  rayDirection: rayDirection,
		                                  sceneGeometry: sceneGeometry,
		                                  environmentShader: environmentShader,
		                                  previousColor: previousColor,
		                                  maximumRayDepth: maximumRayDepth)
		
		return shader1Result + shader2Result
	}
}

extension AddShader: CustomStringConvertible
{
	var description: String
	{
		let shader1Description = "\(shader1)".replacingOccurrences(of: "\n", with: "\n\t")
		let shader2Description = "\(shader2)".replacingOccurrences(of: "\n", with: "\n\t")
		return "AddShader:\n(\n\t\(shader1Description)\n\t\(shader2Description)\n)"
	}
}


class MixShader: Shader
{
	var shader1: Shader
	var shader2: Shader
	var balance: Float
	let color: Color = Color(withRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
	let texture: Texture? = nil
	
	init(with shader1: Shader, and shader2: Shader, balance: Float)
	{
		self.shader1 = shader1
		self.shader2 = shader2
		self.balance = balance
	}
	
	func color(forTriangle triangle: Triangle3D,
	           at barycentricIntersectionCoordinates: BarycentricPoint,
	           point: Point3D,
	           rayDirection: Vector3D,
	           sceneGeometry: TriangleStore,
	           environmentShader: EnvironmentShader,
	           previousColor: Color,
	           maximumRayDepth: Int) -> Color
	{
		let shader1Result = shader1.color(forTriangle: triangle,
		                                  at: barycentricIntersectionCoordinates,
		                                  point: point,
		                                  rayDirection: rayDirection,
		                                  sceneGeometry: sceneGeometry,
		                                  environmentShader: environmentShader,
		                                  previousColor: previousColor,
		                                  maximumRayDepth: maximumRayDepth)
		
		let shader2Result = shader2.color(forTriangle: triangle,
		                                  at: barycentricIntersectionCoordinates,
		                                  point: point,
		                                  rayDirection: rayDirection,
		                                  sceneGeometry: sceneGeometry,
		                                  environmentShader: environmentShader,
		                                  previousColor: previousColor,
		                                  maximumRayDepth: maximumRayDepth)
		
		return shader1Result * balance + shader2Result * (1.0 - balance)
		
	}
}

extension MixShader: CustomStringConvertible
{
	var description: String
	{
		let shader1Description = "\(shader1)".replacingOccurrences(of: "\n", with: "\n\t")
		let shader2Description = "\(shader2)".replacingOccurrences(of: "\n", with: "\n\t")
		return "MixShader (mix: \(balance)):\n(\n\t\(shader1Description)\n\t\(shader2Description)\n)"
	}
}

class EnvironmentShader
{
	var color: Color
	var texture: Texture?
	var strength: Float
	
	init(color: Color, texture: Texture? = nil, strength: Float = 1.0)
	{
		self.color = color
		self.texture = texture
		self.strength = strength
	}
	
	func environmentColor(`for` rayDirection: Vector3D) -> Color
	{
		if let texture = self.texture
		{
			let longitude = atanf(rayDirection.y / rayDirection.x) + (rayDirection.x < 0 ? Float.pi : 0)
			let latitude = asinf(rayDirection.z)
			let u = longitude / Float.pi * 0.5
			let v = latitude / Float.pi + 0.5
			return texture.color(for: TextureCoordinate(u: u, v: v), atAngle: 1.5707963268) * strength
		}
		else
		{
			return color * strength
		}
	}
}
