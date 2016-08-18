//
//  ControlPanelViewController.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 08.08.16.
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

import Cocoa
import QuartzCore

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
	
	@IBOutlet weak var btnStart: NSButton!
	@IBOutlet weak var btnStop: NSButton!
	
	@IBOutlet weak var piSceneImportProgress: NSProgressIndicator!
	
	@IBOutlet weak var cwAmbientColor: NSColorWell!
	
	private var objectLoader: WavefrontModelImporter!
	
	private lazy var importQueue: DispatchQueue = DispatchQueue(label: "pathtracing.meshimport")
	private lazy var importSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
	private var shaderIndex:[String: Shader] = [:]
	
	private var environmentTexture: Texture?
	
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
		
		piSceneImportProgress.isHidden = false
		
		let camera = self.camera
		
		DispatchQueue.global().async
		{
			self.materials = [:]
			self.objectLoader = WavefrontModelImporter()
			self.objectLoader.materialDataSource = self
			self.objectLoader.progress.addObserver(self, forKeyPath: "fractionCompleted", options: [], context: nil)
			guard let objects = try? self.objectLoader.import(from: url) else { return }
			
			ApplicationDelegate.scene = Scene3D(objects: objects, camera: camera, environmentShader: EnvironmentShader(color: .black(), texture: self.environmentTexture))
			
			DispatchQueue.main.async
			{
				self.piSceneImportProgress.stopAnimation(self)
				self.piSceneImportProgress.isHidden = true
			}
		}
	}
	
	@IBAction func startRendering(_ sender: AnyObject)
	{
		ApplicationDelegate.scene?.objects.flatMap{$0.materials}.distinct().forEach{print($0)}
		
		ApplicationDelegate.scene?.camera = self.camera
		
		let color = cwAmbientColor.color
		ApplicationDelegate.scene?.environmentShader.color = Color(withRed: Float(color.redComponent), green: Float(color.greenComponent), blue: Float(color.blueComponent), alpha: Float(color.alphaComponent))
		ApplicationDelegate.scene?.environmentShader.texture = environmentTexture
		
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
		return materials[name]! //force unwrapping, as the code above guarantees non-nil value.
	}
	
	@IBAction func saveScene(_ sender: AnyObject)
	{
		guard let scene = ApplicationDelegate.scene else { return }
		let savePanel = NSSavePanel()
		guard savePanel.runModal() == NSFileHandlingPanelOKButton else { return }
		guard let url = savePanel.url else { return }
		DispatchQueue.global().async
		{
			let materialURL = url.appendingPathExtension("material")
			let materialData = WavefrontModelExporter.exportMaterials(of: scene)
			
			do
			{
				try materialData.write(to: materialURL, options: [.atomic])
			}
			catch
			{
				print(error)
				DispatchQueue.main.async
				{
					let alert = NSAlert(error: error)
					alert.runModal()
				}
			}
		}
	}
	
	@IBAction func saveRender(_ sender: AnyObject)
	{
		guard let image = ApplicationDelegate.pathTracer?.result else { return }
		let savePanel = NSSavePanel()
		savePanel.allowedFileTypes = ["public.png"]
		guard savePanel.runModal() == NSFileHandlingPanelOKButton else { return }
		guard let url = savePanel.url else { return }
		
		DispatchQueue.global().async
		{
			guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil)
			else
			{
				DispatchQueue.main.async
				{
					let alert = NSAlert()
					alert.alertStyle = .critical
					alert.messageText = "Image could not be saved."
					alert.informativeText = "Image destination could not be created."
					alert.runModal()
				}
				return
			}
			CGImageDestinationAddImage(destination, image, nil)
			guard CGImageDestinationFinalize(destination)
			else
			{
				DispatchQueue.main.async
				{
					let alert = NSAlert()
					alert.alertStyle = .critical
					alert.messageText = "Image could not be saved."
					alert.informativeText = "Image destination could not be finalized."
					alert.runModal()
				}
				return
			}
		}
	}
	
	private var lastReport = 0.0
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
	{
		let time = CACurrentMediaTime()
		guard time - lastReport > 0.016 else { return }
		lastReport = time

		DispatchQueue.main.async
		{
			guard let keyPath = keyPath else { return }

			switch keyPath
			{
			case "fractionCompleted":
				guard let progress = object as? Progress else { break }
				self.piSceneImportProgress.minValue = 0.0
				self.piSceneImportProgress.maxValue = 1.0
				self.piSceneImportProgress.doubleValue = progress.fractionCompleted
				break
			default:
				break
			}
		}
	}
	
	@IBAction func chooseEnvironmentTexture(_ sender: AnyObject)
	{
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.canChooseDirectories = false
		openPanel.allowsMultipleSelection = false
		guard openPanel.runModal() == NSFileHandlingPanelOKButton else { return }
		guard let url = openPanel.url else { return }
		guard let imageTexture = ImageTexture(contentsOf: url) else { return }
		ApplicationDelegate.scene?.environmentShader.texture = imageTexture
		environmentTexture = imageTexture
	}
	
}
