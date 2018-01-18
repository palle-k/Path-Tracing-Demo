//
//  ShaderEditorViewController.swift
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

class ShaderEditorViewController: NSViewController
{
	var shader: Shader = defaultShader
	{
		didSet
		{
			self.childViewControllers.flatMap{$0 as? ColorTextureChooserViewController}.forEach
			{
				$0.color = shader.color
				$0.texture = shader.texture
			}
		}
	}
}

class DefaultShaderEditorViewController: ShaderEditorViewController, ColorTextureChooserDelegate
{
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
	}
	
	override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?)
	{
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	override func viewDidAppear()
	{
		self.childViewControllers.flatMap{$0 as? ColorTextureChooserViewController}.forEach
		{
			$0.delegate = self
			$0.color = shader.color
			$0.texture = shader.texture
		}
	}
	
	func colorTextureChooser(chooser: ColorTextureChooserViewController, didChange color: Color)
	{
		(shader as? DefaultShader)?.color = color
	}
	
	func colorTextureChooser(chooser: ColorTextureChooserViewController, didChange texture: Texture?)
	{
		(shader as? DefaultShader)?.texture = texture
	}
}


class DiffuseShaderEditorViewController: ShaderEditorViewController, ColorTextureChooserDelegate
{
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
	}
	
	override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?)
	{
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	override func viewDidAppear()
	{
		self.childViewControllers.flatMap{$0 as? ColorTextureChooserViewController}.forEach
		{
			$0.delegate = self
			$0.color = shader.color
			$0.texture = shader.texture
		}
	}
	
	func colorTextureChooser(chooser: ColorTextureChooserViewController, didChange color: Color)
	{
		(shader as? DiffuseShader)?.color = color
	}
	
	func colorTextureChooser(chooser: ColorTextureChooserViewController, didChange texture: Texture?)
	{
		(shader as? DiffuseShader)?.texture = texture
	}
}

class EmissionShaderEditorViewController: ShaderEditorViewController, ColorTextureChooserDelegate, NSTextFieldDelegate
{
	@IBOutlet weak var txtEmissionStrength: NSTextField!
	
	override var shader: Shader
	{
		didSet
		{
			txtEmissionStrength.floatValue = (shader as? EmissionShader)?.strength ?? 1.0
		}
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
	}
	
	override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?)
	{
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		txtEmissionStrength.delegate = self
	}
	
	override func viewDidAppear()
	{
		self.childViewControllers.flatMap{$0 as? ColorTextureChooserViewController}.forEach
		{
			$0.delegate = self
			$0.color = shader.color
			$0.texture = shader.texture
		}
	}
	
	func colorTextureChooser(chooser: ColorTextureChooserViewController, didChange color: Color)
	{
		(shader as? EmissionShader)?.color = color
	}
	
	func colorTextureChooser(chooser: ColorTextureChooserViewController, didChange texture: Texture?)
	{
		(shader as? EmissionShader)?.texture = texture
	}
	
	override func controlTextDidChange(_ obj: Notification)
	{
		(shader as? EmissionShader)?.strength = txtEmissionStrength.floatValue
	}
}

class ReflectionShaderEditorViewController: ShaderEditorViewController, ColorTextureChooserDelegate, NSTextFieldDelegate
{
	@IBOutlet weak var txtRoughness: NSTextField!
	
	override var shader: Shader
	{
		didSet
		{
			txtRoughness.floatValue = (shader as? ReflectionShader)?.roughness ?? 0.0
		}
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
	}
	
	override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?)
	{
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		txtRoughness.delegate = self
		txtRoughness.floatValue = (shader as? RefractionShader)?.roughness ?? 0.0
	}
	
	override func viewDidAppear()
	{
		self.childViewControllers.flatMap{$0 as? ColorTextureChooserViewController}.forEach
		{
			$0.delegate = self
			$0.color = shader.color
			$0.texture = shader.texture
		}
	}
	
	func colorTextureChooser(chooser: ColorTextureChooserViewController, didChange color: Color)
	{
		(shader as? ReflectionShader)?.color = color
	}
	
	func colorTextureChooser(chooser: ColorTextureChooserViewController, didChange texture: Texture?)
	{
		(shader as? ReflectionShader)?.texture = texture
	}
	
	override func controlTextDidChange(_ obj: Notification)
	{
		(shader as? ReflectionShader)?.roughness = txtRoughness.floatValue
	}
}

class RefractionShaderEditorViewController: ShaderEditorViewController, ColorTextureChooserDelegate, NSTextFieldDelegate
{
	@IBOutlet weak var txtIndexOfRefraction: NSTextField!
	@IBOutlet weak var txtRoughness: NSTextField!
	@IBOutlet weak var cwAttenuationColor: NSColorWell!
	@IBOutlet weak var txtAttenuationStrength: NSTextField!
	
	override var shader: Shader
	{
		didSet
		{
			txtIndexOfRefraction.floatValue = (shader as? RefractionShader)?.indexOfRefraction ?? 1.0
			txtRoughness.floatValue = (shader as? RefractionShader)?.roughness ?? 0.0
			txtAttenuationStrength.floatValue = (shader as? RefractionShader)?.absorptionStrength ?? 0.0
			
			if let attenuationColor = (shader as? RefractionShader)?.volumeColor
			{
				cwAttenuationColor.color = NSColor(calibratedRed: CGFloat(attenuationColor.red),
												   green:		  CGFloat(attenuationColor.green),
												   blue:		  CGFloat(attenuationColor.blue),
				                                   alpha:		  CGFloat(attenuationColor.alpha))
			}
		}
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
	}
	
	override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?)
	{
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		txtIndexOfRefraction.delegate = self
		txtRoughness.delegate = self
		txtAttenuationStrength.delegate = self
		txtIndexOfRefraction.floatValue = (shader as? RefractionShader)?.indexOfRefraction ?? 1.0
		txtRoughness.floatValue = (shader as? RefractionShader)?.roughness ?? 0.0
	}
	
	override func viewDidAppear()
	{
		self.childViewControllers.flatMap{$0 as? ColorTextureChooserViewController}.forEach
		{
			$0.delegate = self
			$0.color = shader.color
			$0.texture = shader.texture
		}
	}
	
	func colorTextureChooser(chooser: ColorTextureChooserViewController, didChange color: Color)
	{
		(shader as? RefractionShader)?.color = color
	}
	
	func colorTextureChooser(chooser: ColorTextureChooserViewController, didChange texture: Texture?)
	{
		(shader as? RefractionShader)?.texture = texture
	}
	
	override func controlTextDidChange(_ obj: Notification)
	{
		(shader as? RefractionShader)?.indexOfRefraction = txtIndexOfRefraction.floatValue
		(shader as? RefractionShader)?.roughness = txtRoughness.floatValue
		(shader as? RefractionShader)?.absorptionStrength = txtAttenuationStrength.floatValue
	}
	
	@IBAction func didChangeAttenuationColor(_ sender: AnyObject)
	{
		let color = cwAttenuationColor.color
		
		let r = Float(color.redComponent)
		let g = Float(color.greenComponent)
		let b = Float(color.blueComponent)
		let a = Float(color.alphaComponent)
		
		guard let currentAttenuationColor = (shader as? RefractionShader)?.volumeColor else { return }
		guard currentAttenuationColor.red != r ||
			currentAttenuationColor.green != g ||
			currentAttenuationColor.blue  != b ||
			currentAttenuationColor.alpha != a
		else
		{
			return
		}
		(shader as? RefractionShader)?.volumeColor = Color(withRed: r, green: g, blue: b, alpha: a)
	}
}

class SubsurfaceScatteringShaderViewController: ShaderEditorViewController, NSTextFieldDelegate
{
	
}

class AddShaderEditorViewController: ShaderEditorViewController, ShaderChooserDelegate
{
	override func viewDidAppear()
	{
		self.childViewControllers.flatMap{$0 as? ShaderChooserViewController}.enumerated().forEach
		{
			$0.element.delegate = self
			if $0.offset == 0
			{
				$0.element.shader = (self.shader as? AddShader)?.shader1 ?? $0.element.shader
			}
			else
			{
				$0.element.shader = (self.shader as? AddShader)?.shader2 ?? $0.element.shader
			}
		}

	}
	
	func shaderChooserDidChangeShader(chooser: ShaderChooserViewController)
	{
		guard let index = self.childViewControllers.index(of: chooser) else { return }
		guard let addShader = (shader as? AddShader) else { return }
		if index == 0
		{
			addShader.shader1 = chooser.shader
		}
		else
		{
			addShader.shader2 = chooser.shader
		}
	}
}

class MixShaderEditorViewController: ShaderEditorViewController, ShaderChooserDelegate, NSTextFieldDelegate
{
	@IBOutlet weak var txtBalance: NSTextField!
	
	override func viewDidAppear()
	{
		txtBalance.floatValue = (shader as? MixShader)?.balance ?? 0.0
		txtBalance.delegate = self
		self.childViewControllers.flatMap{$0 as? ShaderChooserViewController}.enumerated().forEach
		{
			$0.element.delegate = self
			if $0.offset == 0
			{
				$0.element.shader = (self.shader as? MixShader)?.shader1 ?? $0.element.shader
			}
			else
			{
				$0.element.shader = (self.shader as? MixShader)?.shader2 ?? $0.element.shader
			}
		}
		
	}
	
	func shaderChooserDidChangeShader(chooser: ShaderChooserViewController)
	{
		guard let index = self.childViewControllers.index(of: chooser) else { return }
		guard let mixShader = (shader as? MixShader) else { return }
		if index == 0
		{
			mixShader.shader1 = chooser.shader
		}
		else
		{
			mixShader.shader2 = chooser.shader
		}
	}
	
	override func controlTextDidChange(_ obj: Notification)
	{
		(shader as? MixShader)?.balance = txtBalance.floatValue
	}
}


