//
//  PathTracingViewer.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 04.08.16.
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

import UIKit

class PathTracingViewer: UIView, PathTracerDelegate
{
	private var scene: Scene3D!
	private var pathTracer: PathTracer!
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		makeScene()
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		makeScene()
	}
	
	
	var image:CGImage? = nil
	
	
	private func makeScene()
	{
		//
		//		let cube = ExplicitTriangleMesh3D(triangles: triangles)
		//		//cube.location = Point3D(x: 3.0, y: 8.0, z: 0.0)
		//		var cubes = Array<Object3D>(repeating: cube, count: 5)
		//		cubes[0].location = Point3D(x: 3.0, y: 8.0, z: 0.0)
		//		cubes[1].location = Point3D(x: 3.0, y: 10.0, z: 0.0)
		//		cubes[2].location = Point3D(x: 0.0, y: 14.0, z: 0.0)
		//		cubes[3].location = Point3D(x: -2.0, y: 6.0, z: 0.0)
		//		cubes[4].location = Point3D(x: -1.0, y: 8.0, z: 0.0)
		//		cubes[0].rotation.alpha = 1
		//		cubes[1].rotation.alpha = 0
		//		cubes[2].rotation.alpha = -1
		//		cubes[3].rotation.alpha = 0
		//		cubes[4].rotation.alpha = 3.14159265359 * 0.5
		//		cubes[0].rotation.beta = 1
		//		cubes[1].rotation.beta = 1
		//		cubes[2].rotation.beta = 1
		//		cubes[3].rotation.beta = 1
		//		cubes[4].rotation.beta = 1
		//		cubes[0].rotation.gamma = -1
		//		cubes[1].rotation.gamma = -1
		//		cubes[2].rotation.gamma = -1
		//		cubes[3].rotation.gamma = -1
		//		cubes[4].rotation.gamma = -1
		//
		//		triangles = []
		//
		//		triangles += [Triangle3D(a: Point3D(x: 1, y: -1, z: 0), b: Point3D(x: 1, y: 1, z: 0), c: Point3D(x: -1, y: -1, z: 0))]
		//		triangles += [Triangle3D(a: Point3D(x: -1, y: 1, z: 0), b: Point3D(x: 1, y: 1, z: 0), c: Point3D(x: -1, y: -1, z: 0))]
		//
		//		var floor = ExplicitTriangleMesh3D(triangles: triangles)
		//		floor.location = Point3D(x: 0.0, y: 8.0, z: 1.0)
		//		floor.scale = 32
		//
		//		scene = Scene3D(objects: cubes + [floor], camera: (location: Vector3DZero, orientation: Vector3DUnitY))
		
		DispatchQueue.global().async
		{
			
			guard let url = Bundle.main.url(forResource: "mesh2", withExtension: "obj") else { return }
			let importer = WavefrontModelImporter()
			guard var mesh = try? importer.import(from: url) else { fatalError("Mesh could not be imported") }
			
			let redRefraction   = RefractionShader(color: Color(withRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), indexOfRefraction: 1.44, roughness: 0.005)
			let greenRefraction = RefractionShader(color: Color(withRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0), indexOfRefraction: 1.45, roughness: 0.005)
			let blueRefraction  = RefractionShader(color: Color(withRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0), indexOfRefraction: 1.46, roughness: 0.005)
			
			let redGreenAddShader = AddShader(with: redRefraction, and: greenRefraction)
			let dispersionShader = AddShader(with: redGreenAddShader, and: blueRefraction)
			
			mesh[0].assignMaterial(Material(withShader: dispersionShader, named: "DispersionGlass"))
			
			//mesh[0].assignMaterial(Material(withShader: RefractionShader(color: .white(), indexOfRefraction: 1.45, roughness: 0.005), named: "Glass"))
			mesh[0].location.z = -0.2
			//mesh[0].assignMaterial(defaultMaterial)
			
			let ground1 = Triangle3D(a: Vertex3D(point: Point3D(x: -1, y: -1, z: 0),
												 normal: Vector3D(x: 0, y: 0, z: 1),
												 textureCoordinate: TextureCoordinate(u: 0, v: 0)),
									 b: Vertex3D(point: Point3D(x: -1, y: 1, z: 0),
												 normal: Vector3D(x: 0, y: 0, z: 1),
												 textureCoordinate: TextureCoordinate(u: 0, v: 1)),
									 c: Vertex3D(point: Point3D(x: 1, y: -1, z: 0),
												 normal: Vector3D(x: 0, y: 0, z: 1),
												 textureCoordinate: TextureCoordinate(u: 1, v: 0)))

			let ground2 = Triangle3D(a: Vertex3D(point: Point3D(x: -1, y: 1, z: 0),
												 normal: Vector3D(x: 0, y: 0, z: 1),
												 textureCoordinate: TextureCoordinate(u: 0, v: 1)),
									 b: Vertex3D(point: Point3D(x: 1, y: -1, z: 0),
												 normal: Vector3D(x: 0, y: 0, z: 1),
												 textureCoordinate: TextureCoordinate(u: 1, v: 0)),
									 c: Vertex3D(point: Point3D(x: 1, y: 1, z: 0),
												 normal: Vector3D(x: 0, y: 0, z: 1),
												 textureCoordinate: TextureCoordinate(u: 1, v: 1)))

			var object: Object3D = ExplicitTriangleMesh3D(triangles: [ground1, ground2])
			object.location.y = 2
			object.rotation.gamma = Float.pi * 0.5
			object.scale = 2.0
			
			let texture = CheckerboardTexture(horizontalTiles: 20, verticalTiles: 20)
			let emissionShader = EmissionShader(strength: 1, color: Color(withRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), texture: texture)

			object.assignMaterial(Material(withShader: emissionShader, named: "Background"))
			
			let camera = Camera(location: Point3D(x: 0, y: -4, z: 0), rotation: (alpha: 0, beta: Float.pi, gamma: 0), apertureSize: 0.025, focalDistance: 3.25, fieldOfView: 60.0 / 180.0 * Float.pi)
			self.scene = Scene3D(objects: mesh + [object], camera: camera, ambientColor: .black())
			
			self.pathTracer = PathTracer(withScene: self.scene)
			self.pathTracer.delegate = self
			print(self.frame)
			self.pathTracer.traceRays(width: Int(self.frame.width), height: Int(self.frame.height), rayDepth: 8, samples: 8)
		}
		
		//Swift.print(scene.wavefrontString)
		//Swift.print(scene)
		
	}

	override func draw(_ rect: CGRect)
	{
		super.draw(rect)
		
		guard let image = image else { return }
		UIGraphicsGetCurrentContext()?.draw(in: self.bounds, image: image)
	}
	
	func pathTracingDidUpdate(render: CGImage, progress: Float)
	{
		self.image = render
		self.setNeedsDisplay(self.bounds)
	}
	
	func pathTracingDidFinish(render: CGImage)
	{
		self.image = render
		self.setNeedsDisplay(self.bounds)
	}
	
}
