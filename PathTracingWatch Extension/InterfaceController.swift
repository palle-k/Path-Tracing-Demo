//
//  InterfaceController.swift
//  PathTracingWatch Extension
//
//  Created by Palle Klewitz on 12.08.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController, PathTracerDelegate
{
	@IBOutlet var resultView: WKInterfaceImage!
	
	private var scene: Scene3D!
	private var pathTracer: PathTracer!
	
    override func awake(withContext context: AnyObject?)
	{
        super.awake(withContext: context)
        
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
			//mesh[0].assignMaterial(Material(withShader: DiffuseShader(color: .white()), named: "Default"))
			//mesh[0].assignMaterial(Material(withShader: DefaultShader(color: .white()), named: "Default"))
			
			//mesh[0].assignMaterial(Material(withShader: RefractionShader(color: .white(), indexOfRefraction: 1.45, roughness: 0.005), named: "Glass"))
			//mesh[0].location.z = -0.2
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
			
			let camera = Camera(location: Point3D(x: 0, y: -4, z: 0), rotation: (alpha: 0, beta: 0, gamma: 0), apertureSize: 0.025, focalDistance: 3.25, fieldOfView: 75.0 / 180.0 * Float.pi)
			self.scene = Scene3D(objects: mesh + [object], camera: camera, ambientColor: .black())
			self.pathTracer = PathTracer(withScene: self.scene)
			self.pathTracer.delegate = self
			
			let bounds = WKInterfaceDevice.current().screenBounds
			
			self.pathTracer.traceRays(width: Int(bounds.width), height: Int(bounds.height), rayDepth: 3, tileSize: (width: 12, height: 12), samples: 16)
		}
    }
    
    override func willActivate()
	{
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate()
	{
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

	func pathTracingDidFinish(render: CGImage)
	{
		resultView.setImage(UIImage(cgImage: render))
	}
	
	func pathTracingDidUpdate(render: CGImage, progress: Float)
	{
		resultView.setImage(UIImage(cgImage: render))
	}
}
