//
//  AppDelegate.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 29.07.16.
//  Copyright © 2016 - 2018 Palle Klewitz.
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
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RenderResultViewUpdatePathTracer"), object: nil)
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
	return NSApplication.shared.delegate! as! AppDelegate
}
