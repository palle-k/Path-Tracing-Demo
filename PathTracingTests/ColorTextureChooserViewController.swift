//
//  ColorTextureChooserViewController.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 09.08.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import Cocoa

protocol ColorTextureChooserDelegate: class
{
	func colorTextureChooser(chooser: ColorTextureChooserViewController, didChange color: Color)
	func colorTextureChooser(chooser: ColorTextureChooserViewController, didChange texture: Texture?)
}

class ColorTextureChooserViewController: NSViewController
{
	var color: Color = .white()
	{
		didSet
		{
			colorWell.color = NSColor(calibratedRed: CGFloat(color.red),
			                          green:		 CGFloat(color.green),
			                          blue:			 CGFloat(color.blue),
			                          alpha:		 CGFloat(color.alpha))
		}
	}
	var texture: Texture? = nil
	
	@IBOutlet weak var colorWell: NSColorWell!
	@IBOutlet weak var textureTypeChooser: NSPopUpButton!
	
	weak var delegate: ColorTextureChooserDelegate? = nil
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
    }
	
	@IBAction func didChangeColor(_ sender: AnyObject)
	{
		let color = colorWell.color
		
		let r = Float(color.redComponent)
		let g = Float(color.greenComponent)
		let b = Float(color.blueComponent)
		let a = Float(color.alphaComponent)
		
		guard r != self.color.red || g != self.color.green || b != self.color.blue || a != self.color.alpha else { return }
		
		self.color = Color(withRed: r, green: g, blue: b, alpha: a)
		delegate?.colorTextureChooser(chooser: self, didChange: self.color)
	}
	
	@IBAction func didChangeTextureType(_ sender: AnyObject)
	{
		switch textureTypeChooser.indexOfSelectedItem
		{
		case 0:
			texture = nil
			delegate?.colorTextureChooser(chooser: self, didChange: nil)
			break
		case 1:
			texture = CheckerboardTexture(horizontalTiles: 20, verticalTiles: 20)
			delegate?.colorTextureChooser(chooser: self, didChange: texture)
			break
		case 2:
			let openPanel = NSOpenPanel()
			openPanel.canChooseFiles = true
			openPanel.canChooseDirectories = false
			openPanel.allowsMultipleSelection = false
			guard openPanel.runModal() == NSFileHandlingPanelOKButton else { break }
			guard let url = openPanel.url else { break }
			guard let imageTexture = ImageTexture(contentsOf: url) else { break }
			texture = imageTexture
			delegate?.colorTextureChooser(chooser: self, didChange: texture)
			break
		default:
			break
		}
	}
}
