//
//  ControlPanelViewController.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 08.08.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Cocoa

class ControlPanelViewController: NSViewController, WavefrontModelImporterMaterialDataSource
{
	@IBOutlet weak var txtCameraX: NSTextField!
	@IBOutlet weak var txtCameraY: NSTextField!
	@IBOutlet weak var txtCameraZ: NSTextField!
	@IBOutlet weak var txtCameraAlpha: NSTextField!
	@IBOutlet weak var txtCameraBeta: NSTextField!
	@IBOutlet weak var txtCameraGamma: NSTextField!
	@IBOutlet weak var txtCameraApertureSize: NSTextField!
	@IBOutlet weak var txtCameraFocalLength: NSTextField!
	@IBOutlet weak var txtCameraFov: NSTextField!

	@IBOutlet weak var txtPathTracingSamples: NSTextField!
	@IBOutlet weak var txtPathTracingRecursionDepth: NSTextField!
	
	@IBOutlet weak var txtRenderWidth: NSTextField!
	@IBOutlet weak var txtRenderHeight: NSTextField!
	
	@IBOutlet weak var cbxPathTracingUsePreview: NSButton!
	
	@IBOutlet weak var btnStart: NSButton!
	@IBOutlet weak var btnStop: NSButton!
	
	@IBOutlet weak var piSceneImportProgress: NSProgressIndicator!
	
	@IBOutlet weak var cwAmbientColor: NSColorWell!
	
	private var objectLoader: WavefrontModelImporter!
	
	private lazy var importQueue: DispatchQueue = DispatchQueue(label: "pathtracing.meshimport")
	private lazy var importSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
	private var shaderIndex:[String: Shader] = [:]
	
	private var camera: Camera
	{
		let x = txtCameraX.floatValue
		let y = txtCameraY.floatValue
		let z = txtCameraZ.floatValue
		let alpha = txtCameraAlpha.floatValue
		let beta = txtCameraBeta.floatValue
		let gamma = txtCameraGamma.floatValue
		let apertureSize: Float = txtCameraApertureSize.floatValue
		let focalDistance: Float = txtCameraFocalLength.floatValue
		let fieldOfView: Float = txtCameraFov.floatValue
		
		return Camera(location: Point3D(x: x, y: y, z: z),
		              rotation: (alpha: alpha, beta: beta, gamma: gamma),
		              apertureSize: apertureSize,
		              focalDistance: focalDistance,
		              fieldOfView: fieldOfView)
	}
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
    }
    
	@IBAction func importScene(_ sender: AnyObject)
	{
		let openPanel = NSOpenPanel()
		openPanel.allowsMultipleSelection = false
		openPanel.canChooseDirectories = false
		openPanel.canChooseFiles = true
		
		guard openPanel.runModal() == NSFileHandlingPanelOKButton else { return }
		guard let url = openPanel.url else { return }
		
		piSceneImportProgress.startAnimation(self)
		
		DispatchQueue.global().async
		{
			self.materials = [:]
			self.objectLoader = WavefrontModelImporter()
			self.objectLoader.materialDataSource = self
			
			guard let objects = try? self.objectLoader.import(from: url) else { return }
			
			ApplicationDelegate.scene = Scene3D(objects: objects, camera: self.camera, ambientColor: Color(withRed: 0.0209043, green: 0.0209043, blue: 0.0209043, alpha: 1.0))
			
			DispatchQueue.main.async
			{
				self.piSceneImportProgress.stopAnimation(self)
			}
		}
	}
	
	@IBAction func startRendering(_ sender: AnyObject)
	{
		ApplicationDelegate.scene?.objects.flatMap{$0.materials}.distinct().forEach{print($0)}
		
		ApplicationDelegate.scene?.camera = self.camera
		
		let color = cwAmbientColor.color
		ApplicationDelegate.scene?.ambientColor = Color(withRed: Float(color.redComponent), green: Float(color.greenComponent), blue: Float(color.blueComponent), alpha: Float(color.alphaComponent))
		
		ApplicationDelegate.pathTracer?.traceRays(width: txtRenderWidth.integerValue,
		                                          height: txtRenderHeight.integerValue,
		                                          rayDepth: txtPathTracingRecursionDepth.integerValue,
		                                          samples: txtPathTracingSamples.integerValue)
	}
	
	@IBAction func stopRendering(_ sender: AnyObject)
	{
		ApplicationDelegate.pathTracer?.stop()
	}
	
	private var materials:[String:Material] = [:]
	
	func material(named name: String, in materialLibrary: String) -> Material
	{
		if materials[name] == nil
		{
			materials[name] = Material(withShader: DefaultShader(color: .white()), named: name)
		}
		return materials[name]!
	}
}
