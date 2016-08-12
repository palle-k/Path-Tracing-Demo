//
//  ViewController.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 29.07.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Cocoa

class RenderResultViewController: NSViewController, PathTracerDelegate
{
	@IBOutlet weak var imageView: NSImageView!

	override func viewDidLoad()
	{
		super.viewDidLoad()
		NotificationCenter.default.addObserver(self, selector: #selector(pathTracerUpdated(notification:)), name: "RenderResultViewUpdatePathTracer" as NSNotification.Name, object: nil)
	}

	func pathTracingDidFinish(render: CGImage)
	{
		imageView.image = NSImage(cgImage: render, size: NSSize(width: render.width, height: render.height))
		self.view.window?.title = "1337 HaXx0r rAyyy(lmao)TraC1n6"
	}
	
	func pathTracingDidUpdate(render: CGImage, progress: Float)
	{
		imageView.image = NSImage(cgImage: render, size: NSSize(width: render.width, height: render.height))
		self.view.window?.title = "1337 HaXx0r rAyyy(lmao)TraC1n6 - \(Int(progress * 100))% completed."
	}
	
	func pathTracerUpdated(notification: NSNotification?)
	{
		ApplicationDelegate.pathTracer?.delegate = self
	}
}
