//
//  MeshImport.swift
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

private extension String
{
	var trimmed: String
	{
		return self.trimmingCharacters(in: CharacterSet.whitespaces)
	}
}

class WavefrontModelImporter: NSObject, ProgressReporting
{
	weak var materialDataSource: WavefrontModelImporterMaterialDataSource?
	
	var progress: Progress = Progress()
	
	func `import`(from url: URL) throws -> [Object3D]
	{
		let data = try Data(contentsOf: url)
		
		
		
		let materialURL = url.deletingLastPathComponent()
			.appendingPathComponent(
				url.lastPathComponent
					.components(separatedBy: ".")
					.dropLast()
					.joined(separator: "."))
			.appendingPathExtension("material")
		print(materialURL)
		
		let materials:[String: Material]
		
		if
			let materialData = try? Data(contentsOf: materialURL, options: []),
		    let encodedMaterials = NSKeyedUnarchiver.unarchiveObject(with: materialData) as? NSDictionary
		{
			var mutableMaterials:[String: Material] = [:]
			for key in (encodedMaterials.allKeys.flatMap{$0 as? String})
			{
				guard let shader = (encodedMaterials[key] as? ShaderDecoder)?.decoded else { continue }
				mutableMaterials[key] = Material(withShader: shader, named: key)
			}
			materials = mutableMaterials
		}
		else
		{
			materials = [:]
		}
		
		guard let dataString = String(data: data, encoding: String.Encoding.utf8) else { throw NSError(domain: "com.PK.pathtracingtests.wavefront.import", code: 1, userInfo: [:]) }

		var points:[Point3D] = []
		var normals:[Vector3D] = []
		var textureCoordinates:[TextureCoordinate] = []
		var faces:[Triangle3D] = []
		var objects:[Object3D] = []
		var currentMaterialLibrary: String? = nil
		var currentMaterial: Material? = nil
		var currentObjectName: String? = nil
		
		var processedCount = 0
		let lines = dataString.components(separatedBy: CharacterSet.newlines).map{$0.trimmed}.filter{!$0.isEmpty}.filter{$0[$0.startIndex] != "#"}
		
		progress.totalUnitCount = Int64(lines.count)
		progress.completedUnitCount = 0
		
		for line in lines
		{
			let lineComponents = line.components(separatedBy: CharacterSet.whitespaces)
			
			if lineComponents[0] == "v"
			{
				guard lineComponents.count >= 4 else { continue }
				let coordinates = lineComponents[1 ... 3].flatMap(Float.init)
				guard coordinates.count == 3 else { continue }
				points.append(Point3D(x: coordinates[0], y: coordinates[1], z: coordinates[2]))
			}
			else if lineComponents[0] == "vn"
			{
				guard lineComponents.count >= 4 else { continue }
				let coordinates = lineComponents[1 ... 3].flatMap(Float.init)
				guard coordinates.count == 3 else { continue }
				normals.append(Vector3D(x: coordinates[0], y: coordinates[1], z: coordinates[2]))
			}
			else if lineComponents[0] == "vt"
			{
				guard lineComponents.count >= 3 else { continue }
				let coordinates = lineComponents[1 ... 2].flatMap(Float.init)
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
				if let material = materials[lineComponents[1]]
				{
					currentMaterial = material
				}
				else
				{
					currentMaterial = materialDataSource?.material(named: lineComponents[1], in: materialLibrary)
				}
			}
			
			processedCount += 1
			progress.completedUnitCount = Int64(processedCount)
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

class WavefrontModelExporter
{
	class func export(scene: Scene3D) -> (wavefrontData: Data, materialData: Data)
	{
		var dataString = "# Path Tracing Demo by PK\n"
		
		var offset = 0
		
		for object in scene.objects
		{
			dataString.append("o \(object.name)\n")
			
			let triangles = object.transformed
			
			let vertices = triangles
				.flatMap{[$0.a, $0.b, $0.c]}
			
			let vertexLocationString = vertices.map{$0.point}
				.map{"v \($0.x) \($0.y) \($0.z)"}
				.joined(separator: "\n")
			
			let vertexNormalString = vertices.map{$0.normal}
				.map{"vn \($0.x) \($0.y) \($0.z)"}
				.joined(separator: "\n")
			
			let vertexTextureCoordinateString = vertices.map{$0.textureCoordinate}
				.map{"vt \($0.u) \($0.v)"}
				.joined(separator: "\n")
			
			dataString.append(vertexLocationString)
			dataString.append("\n")
			dataString.append(vertexNormalString)
			dataString.append("\n")
			dataString.append(vertexTextureCoordinateString)
			dataString.append("\n")
			
			var currentMaterial = ""
			
			for (index, triangle) in triangles.enumerated()
			{
				if currentMaterial != triangle.material.name
				{
					currentMaterial = triangle.material.name
					dataString.append("usemtl \(currentMaterial)\n")
					dataString.append("s 1")
				}
				let first = index * 3 + offset
				let second = first + 1
				let third = second + 1
				dataString.append("f \(first)/\(first)/\(first) \(second)/\(second)/\(second) \(third)/\(third)/\(third)\n")
			}
			
			offset += triangles.count * 3
		}
		
		let materials = scene.objects.flatMap{$0.materials}.distinct()
		
		let materialShaders = NSMutableDictionary()
		
		for material in materials
		{
			materialShaders[material.name] = (material.shader as? ShaderEncoding)?.encoded
		}
		
		let encodedShaders:Data
		encodedShaders = NSKeyedArchiver.archivedData(withRootObject: materialShaders)
		
		guard let wavefrontData = dataString.data(using: .ascii) else { fatalError("unable to encode data string") }
		return (wavefrontData: wavefrontData, materialData: encodedShaders)
	}
	
	class func exportMaterials(of scene: Scene3D) -> Data
	{
		let materials = scene.objects.flatMap{$0.materials}.distinct()
		
		let materialShaders = NSMutableDictionary()
		
		for material in materials
		{
			materialShaders[material.name] = (material.shader as? ShaderEncoding)?.encoded
		}
		
		let encodedShaders:Data
		encodedShaders = NSKeyedArchiver.archivedData(withRootObject: materialShaders)
		
		return encodedShaders
	}
}


