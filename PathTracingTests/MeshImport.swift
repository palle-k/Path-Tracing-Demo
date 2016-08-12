//
//  MeshImport.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 31.07.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Foundation

private extension String
{
	var trimmed: String
	{
		return self.trimmingCharacters(in: CharacterSet.whitespaces)
	}
}

class WavefrontModelImporter
{
	weak var materialDataSource: WavefrontModelImporterMaterialDataSource?
	
	func `import`(from url: URL) throws -> [Object3D]
	{
		let data = try Data(contentsOf: url)
		guard let dataString = String(data: data, encoding: String.Encoding.utf8) else { throw NSError(domain: "com.PK.pathtracingtests.wavefront.import", code: 1, userInfo: [:]) }

		var points:[Point3D] = []
		var normals:[Vector3D] = []
		var textureCoordinates:[TextureCoordinate] = []
		var faces:[Triangle3D] = []
		var objects:[Object3D] = []
		var currentMaterialLibrary: String? = nil
		var currentMaterial: Material? = nil
		var currentObjectName: String? = nil
		
		for line in (dataString.components(separatedBy: CharacterSet.newlines).map{$0.trimmed}.filter{!$0.isEmpty}.filter{$0[$0.startIndex] != "#"})
		{
			let lineComponents = line.components(separatedBy: CharacterSet.whitespaces)
			
			if lineComponents[0] == "v"
			{
				guard lineComponents.count >= 4 else { continue }
				let coordinates = lineComponents[1 ... 3].flatMap{Float($0)}
				guard coordinates.count == 3 else { continue }
				points.append(Point3D(x: coordinates[0], y: coordinates[1], z: coordinates[2]))
			}
			else if lineComponents[0] == "vn"
			{
				guard lineComponents.count >= 4 else { continue }
				let coordinates = lineComponents[1 ... 3].flatMap{Float($0)}
				guard coordinates.count == 3 else { continue }
				normals.append(Vector3D(x: coordinates[0], y: coordinates[1], z: coordinates[2]))
			}
			else if lineComponents[0] == "vt"
			{
				guard lineComponents.count >= 3 else { continue }
				let coordinates = lineComponents[1 ... 2].flatMap{Float($0)}
				guard coordinates.count == 2 else { continue }
				textureCoordinates.append(TextureCoordinate(u: coordinates[0], v: coordinates[1]))
			}
			else if lineComponents[0] == "f"
			{
				let vertexStrings = lineComponents[1 ..< lineComponents.count]
				guard vertexStrings.count >= 3 else { continue }
				var vertexData:[(point: Point3D, normal: Vector3D?, texture: TextureCoordinate?)] = []
				for vertex in vertexStrings
				{
					let vertexComponents = vertex.components(separatedBy: "/").flatMap{Int($0)}
					
					let point: Point3D
					let normal: Vector3D?
					let textureCoordinate: TextureCoordinate?
					
					if vertexComponents.count == 3
					{
						point = points[vertexComponents[0]-1]
						textureCoordinate = textureCoordinates[vertexComponents[1]-1]
						normal = normals[vertexComponents[2]-1]
					}
					else if vertexComponents.count == 2
					{
						if vertex.contains("//")
						{
							point = points[vertexComponents[0]-1]
							normal = normals[vertexComponents[1]-1]
							textureCoordinate = nil
						}
						else
						{
							point = points[vertexComponents[0]-1]
							normal = nil
							textureCoordinate = textureCoordinates[vertexComponents[2]-1]
						}
					}
					else
					{
						point = points[vertexComponents[0]-1]
						normal = nil
						textureCoordinate = nil
					}
					vertexData.append((point: point, normal: normal, texture: textureCoordinate))
				}
				
				//TODO: Triangulation
				
				let vertexA = Vertex3D(point: vertexData[0].point,
				                       normal: vertexData[0].normal ?? ((vertexData[1].point - vertexData[0].point) ⨯ (vertexData[2].point - vertexData[0].point)),
				                       textureCoordinate: vertexData[0].texture ?? TextureCoordinate(u: 0, v: 0))
				let vertexB = Vertex3D(point: vertexData[1].point,
				                       normal: vertexData[1].normal ?? ((vertexData[2].point - vertexData[1].point) ⨯ (vertexData[0].point - vertexData[1].point)),
				                       textureCoordinate: vertexData[1].texture ?? TextureCoordinate(u: 1, v: 0))
				let vertexC = Vertex3D(point: vertexData[2].point,
				                       normal: vertexData[2].normal ?? ((vertexData[1].point - vertexData[2].point) ⨯ (vertexData[0].point - vertexData[2].point)),
				                       textureCoordinate: vertexData[2].texture ?? TextureCoordinate(u: 0, v: 1))
				
				let triangle: Triangle3D
				if let material = currentMaterial
				{
					triangle = Triangle3D(a: vertexA, b: vertexB, c: vertexC, material: material)
				}
				else
				{
					triangle = Triangle3D(a: vertexA, b: vertexB, c: vertexC)
				}
				faces.append(triangle)
			}
			else if lineComponents[0] == "o"
			{
				if lineComponents.count >= 2
				{
					currentObjectName = lineComponents[1]
				}
				
				guard !faces.isEmpty else { continue }
				
				var object = ExplicitTriangleMesh3D(triangles: faces)
				if let objectName = currentObjectName
				{
					object.name = objectName
				}
				objects.append(object)
				faces = []
			}
			else if lineComponents[0] == "mtllib"
			{
				guard lineComponents.count >= 2 else { continue }
				currentMaterialLibrary = lineComponents[1]
			}
			else if lineComponents[0] == "usemtl"
			{
				guard let materialLibrary = currentMaterialLibrary,
					lineComponents.count >= 2
				else
				{
					continue
				}
				currentMaterial = materialDataSource?.material(named: lineComponents[1], in: materialLibrary)
			}
		}
		if !faces.isEmpty
		{
			var object = ExplicitTriangleMesh3D(triangles: faces)
			if let objectName = currentObjectName
			{
				object.name = objectName
			}
			objects.append(object)
		}
		
		return objects
	}
}

protocol WavefrontModelImporterMaterialDataSource: class
{
	func material(named name: String, `in` materialLibrary: String) -> Material
}
