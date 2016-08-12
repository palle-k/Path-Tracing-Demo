//
//  PathTracingView.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 30.07.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Cocoa

class PathTracingView: NSView, PathTracerDelegate, WavefrontModelImporterMaterialDataSource
{
	private var scene: Scene3D!
	private var pathTracer: PathTracer!
	private var modelImporter: WavefrontModelImporter!
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		makeScene()
	}
	
	override init(frame frameRect: NSRect)
	{
		super.init(frame: frameRect)
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
//			var triangles:[Triangle3D] = []
//			
//			//left
//			triangles += [Triangle3D(a: Point3D(x: -1, y: -1, z: -1), b: Point3D(x: -1, y: 1, z: -1), c: Point3D(x: -1, y: -1, z: 1))]
//			triangles += [Triangle3D(a: Point3D(x: -1, y: 1, z: 1), b: Point3D(x: -1, y: 1, z: -1), c: Point3D(x: -1, y: -1, z: 1))]
//			
//			//right
//			triangles += [Triangle3D(a: Point3D(x: 1, y: -1, z: -1), b: Point3D(x: 1, y: 1, z: -1), c: Point3D(x: 1, y: -1, z: 1))]
//			triangles += [Triangle3D(a: Point3D(x: 1, y: 1, z: 1), b: Point3D(x: 1, y: 1, z: -1), c: Point3D(x: 1, y: -1, z: 1))]
//			
//			//top
//			triangles += [Triangle3D(a: Point3D(x: 1, y: -1, z: -1), b: Point3D(x: 1, y: 1, z: -1), c: Point3D(x: -1, y: -1, z: -1))]
//			triangles += [Triangle3D(a: Point3D(x: -1, y: 1, z: -1), b: Point3D(x: 1, y: 1, z: -1), c: Point3D(x: -1, y: -1, z: -1))]
//			
//			//bottom
//			triangles += [Triangle3D(a: Point3D(x: 1, y: -1, z: 1), b: Point3D(x: 1, y: 1, z: 1), c: Point3D(x: -1, y: -1, z: 1))]
//			triangles += [Triangle3D(a: Point3D(x: -1, y: 1, z: 1), b: Point3D(x: 1, y: 1, z: 1), c: Point3D(x: -1, y: -1, z: 1))]
//			
//			//back
//			triangles += [Triangle3D(a: Point3D(x: 1, y: 1, z: 1), b: Point3D(x: 1, y: 1, z: -1), c: Point3D(x: -1, y: 1, z: 1))]
//			triangles += [Triangle3D(a: Point3D(x: -1, y: 1, z: -1), b: Point3D(x: 1, y: 1, z: -1), c: Point3D(x: -1, y: 1, z: 1))]
//			
//			//front
//			triangles += [Triangle3D(a: Point3D(x: 1, y: -1, z: 1), b: Point3D(x: 1, y: -1, z: -1), c: Point3D(x: -1, y: -1, z: 1))]
//			triangles += [Triangle3D(a: Point3D(x: -1, y: -1, z: -1), b: Point3D(x: 1, y: -1, z: -1), c: Point3D(x: -1, y: -1, z: 1))]
//
//			let cube = ExplicitTriangleMesh3D(triangles: triangles)
//			
//			triangles = []
//			
//			triangles += [Triangle3D(a: Point3D(x: 1, y: -1, z: 0), b: Point3D(x: 1, y: 1, z: 0), c: Point3D(x: -1, y: -1, z: 0))]
//			triangles += [Triangle3D(a: Point3D(x: -1, y: 1, z: 0), b: Point3D(x: 1, y: 1, z: 0), c: Point3D(x: -1, y: -1, z: 0))]
//			
//			var floor = ExplicitTriangleMesh3D(triangles: triangles)
//			floor.location = Point3D(x: 0.0, y: 8.0, z: 1.0)
//			floor.scale = 32
//			
//			let lamp1 = Triangle3D(a: Point3D(x: 0, y: -0.5, z:  0.5),
//			                       b: Point3D(x: 0, y:  0.5, z:  0.5),
//			                       c: Point3D(x: 0, y:  0.0, z: -0.5),
//			                      shader: EmissionShader(strength: 15.0,
//			                                             color: Color(withRed: 1.0,
//			                                                          green: 1.0,
//			                                                          blue: 0.0,
//			                                                          alpha: 1.0)))
//			
//			var lampObject1 = ExplicitTriangleMesh3D(triangles: [lamp1])
//			lampObject1.location = Point3D(x: 4, y: -4.1, z: 1.0)
//			lampObject1.scale = 16.0
//			lampObject1.rotation.alpha = Float(M_PI_2)
//			
//			let lamp2 = Triangle3D(a: Point3D(x: 0, y: -0.25, z:  0.5),
//			                       b: Point3D(x: 0, y:  0.25, z:  0.5),
//			                       c: Point3D(x: 0, y: -0.25, z: -0.5),
//			                       shader: EmissionShader(strength: 15.0,
//			                                              color: Color(withRed: 1.0,
//			                                                           green: 0.0,
//			                                                           blue: 1.0,
//			                                                           alpha: 1.0)))
//			
//			var lampObject2 = ExplicitTriangleMesh3D(triangles: [lamp2])
//			lampObject2.location = Point3D(x: 3.0, y: 1.0, z: 1.0)
//			lampObject2.scale = 2.0
//			
//			let objects:[Object3D] = [cube, floor, lampObject1, lampObject2]
			
			let url = URL(fileURLWithPath: "/Users/Palle/Desktop/scene.obj")
			
			self.modelImporter = WavefrontModelImporter()
			self.modelImporter.materialDataSource = self
			
			guard var mesh = try? self.modelImporter.import(from: url) else { fatalError("Mesh could not be imported") }
			
			mesh[0].scale = 8.0
			mesh[1].scale = 8.0
			
			//mesh[0].assignShader(DiffuseShader(color: Color(withRed: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)))
			//mesh[0].assignShader(EmissionShader(strength: 1.0, color: Color(withRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
			//mesh[1].assignShader(ReflectionShader(color: Color(withRed: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)))
			
			//let redRefraction   = RefractionShader(color: Color(withRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), indexOfRefraction: 1.44, roughness: 0.005)
			//let greenRefraction = RefractionShader(color: Color(withRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0), indexOfRefraction: 1.45, roughness: 0.005)
			//let blueRefraction  = RefractionShader(color: Color(withRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0), indexOfRefraction: 1.46, roughness: 0.005)
			
			//let redGreenAddShader = AddShader(with: redRefraction, and: greenRefraction)
				//let dispersionShader = AddShader(with: redGreenAddShader, and: blueRefraction)

			//mesh[0].assignShader(dispersionShader)
//
//			mesh[1].location = Point3D(x: 0, y: -2.5, z: 0)
//			
//			mesh[0].scale = 0.6667
//			mesh[1].scale = 0.5
			
			//mesh[0].assignShader(RefractionShader(color: Color(withRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), indexOfRefraction: 1.45, roughness: 0))
			//mesh[0].assignShader(GlassShader())
			//mesh[0].assignShader(GlassShader(ior: 1.45, roughness: 0.01))
			
//			let ground1 = Triangle3D(a: Vertex3D(point: Point3D(x: -1, y: -1, z: 0),
//			                                     normal: Vector3D(x: 0, y: 0, z: 1),
//			                                     textureCoordinate: TextureCoordinate(u: 0, v: 0)),
//			                         b: Vertex3D(point: Point3D(x: -1, y: 1, z: 0),
//			                                     normal: Vector3D(x: 0, y: 0, z: 1),
//			                                     textureCoordinate: TextureCoordinate(u: 0, v: 1)),
//			                         c: Vertex3D(point: Point3D(x: 1, y: -1, z: 0),
//			                                     normal: Vector3D(x: 0, y: 0, z: 1),
//			                                     textureCoordinate: TextureCoordinate(u: 1, v: 0)))
//			
//			let ground2 = Triangle3D(a: Vertex3D(point: Point3D(x: -1, y: 1, z: 0),
//			                                     normal: Vector3D(x: 0, y: 0, z: 1),
//			                                     textureCoordinate: TextureCoordinate(u: 0, v: 1)),
//			                         b: Vertex3D(point: Point3D(x: 1, y: -1, z: 0),
//			                                     normal: Vector3D(x: 0, y: 0, z: 1),
//			                                     textureCoordinate: TextureCoordinate(u: 1, v: 0)),
//			                         c: Vertex3D(point: Point3D(x: 1, y: 1, z: 0),
//			                                     normal: Vector3D(x: 0, y: 0, z: 1),
//			                                     textureCoordinate: TextureCoordinate(u: 1, v: 1)))
//			
//			var object: Object3D = ExplicitTriangleMesh3D(triangles: [ground1, ground2])
//			object.location.y = 2
//			object.rotation.gamma = Float.pi * 0.5
//			object.scale = 2.0
//			
//			//let texture = ImageTexture(contentsOf: URL(fileURLWithPath: "/Users/Palle/Downloads/checkerboard.png"))
//			let texture = CheckerboardTexture(horizontalTiles: 20, verticalTiles: 20)
//			let emissionShader = EmissionShader(strength: 1, color: Color(withRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), texture: texture)
//			
//			object.assignShader(emissionShader)
			
			let camera = Camera(location: Point3D(x: -14, y: -14, z: 6.7), rotation: (alpha: -0.73627, beta: 0.3, gamma: -0.3), apertureSize: 0.5, focalDistance: 14.5, fieldOfView: 60.0 / 1280.0 * Float.pi)
			self.scene = Scene3D(objects: mesh , camera: camera, ambientColor: Color(withRed: 0.0209043, green: 0.0209043, blue: 0.0209043, alpha: 1.0))
			
			self.pathTracer = PathTracer(withScene: self.scene)
			self.pathTracer.delegate = self
			self.pathTracer.traceRays(width: Int(self.frame.width), height: Int(self.frame.height), rayDepth: 8, samples: 4)
		}
		
		//Swift.print(scene.wavefrontString)
		//Swift.print(scene)

	}
	
	override func draw(_ dirtyRect: NSRect)
	{
		super.draw(dirtyRect)

		guard let image = image else { return }
		guard let ctx = NSGraphicsContext.current()?.cgContext else { return }
		
		ctx.saveGState()
		defer
		{
			ctx.restoreGState()
		}
		
		ctx.translateBy(x: 0, y: CGFloat(image.height))
		ctx.scaleBy(x: 1, y: -1)
		
		ctx.draw(in: self.bounds, image: image)
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
	
	private lazy var materials:[String:Material] =
	{
		var dict:[String: Material] = [:]
		dict["Cube"]		 = Material(withShader: DiffuseShader(color: Color(withRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)), named: "Cube")
		dict["Cube.001"]	 = Material(withShader: EmissionShader(strength: 1.0, color: .white()),								  named: "Cube.001")
		dict["Material.001"] = Material(withShader: EmissionShader(strength: 50.0, color: .white()),							  named: "Material.001")
		dict["Material.002"] = Material(withShader: EmissionShader(strength: 25.0, color: .white()),							  named: "Material.002")
		dict["None"]		 = Material(withShader: DiffuseShader(color: .white()),												  named: "None")
		dict["Untitled"]	 = Material(withShader: EmissionShader(strength: 1.0, color: .white()),								  named: "Untitled")
		
		return dict
	}()
	
	func material(named name: String, in materialLibrary: String) -> Material
	{
		return materials[name] ?? defaultMaterial
		//return DefaultShader(color: .white())
	}
    
}
