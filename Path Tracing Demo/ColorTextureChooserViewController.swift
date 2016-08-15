//
//  ColorTextureChooserViewController.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 09.08.16.
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
	{
		didSet
		{
			if let texture = self.texture
			{
				if texture is ImageTexture
				{
					textureTypeChooser.selectItem(at: 2)
				}
				else if texture is CheckerboardTexture
				{
					textureTypeChooser.selectItem(at: 1)
				}
			}
			else
			{
				textureTypeChooser.selectItem(at: 0)
			}
		}
	}
	
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
