//
//  AppDelegate.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 29.07.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
	var scene: Scene3D?
	{
		didSet
		{
			guard let scene = self.scene else { return }
			self.pathTracer = PathTracer(withScene: scene)
			DispatchQueue.main.async
			{
				NotificationCenter.default.post(name: "RenderResultViewUpdatePathTracer" as NSNotification.Name, object: nil)
			}
		}
	}
	
	var pathTracer: PathTracer?
	
	func applicationDidFinishLaunching(_ aNotification: Notification)
	{

	}

	func applicationWillTerminate(_ aNotification: Notification)
	{
		
	}
}

class UnifiedTitleBarWindowController: NSWindowController
{
	override func windowDidLoad()
	{
		super.windowDidLoad()
		self.window?.titlebarAppearsTransparent = true
	}
}

var ApplicationDelegate: AppDelegate
{
	return NSApplication.shared().delegate! as! AppDelegate
}
