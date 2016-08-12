//
//  SceneEncoding.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 12.08.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Foundation

extension Vector3D
{
	var encoded: Dictionary<String, AnyObject>
	{
		return [
			"vec_x" : "\(x)",
			"vec_y" : "\(y)",
			"vec_z" : "\(z)"
		]
	}
	
	init?(with encodedData: Dictionary<String, AnyObject>)
	{
		guard
			let sx = encodedData["vec_x"] as? String,
			let sy = encodedData["vec_y"] as? String,
			let sz = encodedData["vec_z"] as? String,
			let x = Float(sx),
			let y = Float(sy),
			let z = Float(sz)
		else
		{
			return nil
		}
		self.init(x:x, y:y, z:z)
	}
}

extension TextureCoordinate
{
	var encoded: Dictionary<String, AnyObject>
	{
		return [
			"tex_u" : "\(u)",
			"tex_v" : "\(v)"
		]
	}
	
	init?(with encodedData: Dictionary<String, AnyObject>)
	{
		guard
			let su = encodedData["tex_u"] as? String,
			let sv = encodedData["tex_v"] as? String,
			let u = Float(su),
			let v = Float(sv)
			else
		{
			return nil
		}
		self.init(u: u, v: v)
	}
}

extension Vertex3D
{
	var encoded: Dictionary<String, AnyObject>
	{
		return [
			"vertex_point" : point.encoded,
			"vertex_normal" : normal.encoded,
			"vertex_tex_c" : textureCoordinate.encoded,
		]
	}
	
	init?(with encodedData: Dictionary<String, AnyObject>)
	{
		guard
			let encodedPoint = encodedData["vertex_point"] as? Dictionary<String, AnyObject>,
			let encodedNormal = encodedData["vertex_normal"] as? Dictionary<String, AnyObject>,
			let encodedTextureCoordinate = encodedData["vertex_tex_c"] as? Dictionary<String, AnyObject>,
			let point = Point3D(with: encodedPoint),
			let normal = Vector3D(with: encodedNormal),
			let textureCoordinate = TextureCoordinate(with: encodedTextureCoordinate)
		else
		{
			return nil
		}
		self.init(point: point, normal: normal, textureCoordinate: textureCoordinate)
	}
}

extension Triangle3D
{
	var encoded: Dictionary<String, AnyObject>
	{
		return [:]
	}
	
	init?(with encodedData: Dictionary<String, AnyObject>)
	{
		return nil
	}
}

extension ExplicitTriangleMesh3D
{
	var encoded: Dictionary<String, AnyObject>
	{
		return [:]
	}
	
	init?(with encodedData: Dictionary<String, AnyObject>)
	{
		self.init(triangles:[])
	}
}

extension Camera
{
	var encoded: Dictionary<String, AnyObject>
	{
		return [:]
	}
	
	init?(with encodedData: Dictionary<String, AnyObject>)
	{
		self.init(location: Vector3DZero,
		          rotation: (alpha: 0, beta: 0, gamma: 0),
		          apertureSize: 0,
		          focalDistance: 1,
		          fieldOfView: 1)
	}
}

extension Scene3D
{
	var encoded: Dictionary<String, AnyObject>
	{
		return [:]
	}
	
	init?(with encodedData: Dictionary<String, AnyObject>)
	{
		self.init(objects: [], camera: Camera(location: Vector3DZero, rotation: (alpha: 0, beta: 0, gamma: 0), apertureSize: 0, focalDistance: 1, fieldOfView: 1), ambientColor: .black())
	}
}
