//
//  ShaderChooserViewController.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 09.08.16.
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

private let DefaultShaderViewControllerIdentifier = "DefaultMaterialEditorViewController"
private let DiffuseShaderViewControllerIdentifier = "DiffuseMaterialEditorViewController"
private let EmissionShaderViewControllerIdentifier = "EmissionMaterialEditorViewController"
private let ReflectionShaderViewControllerIdentifier = "ReflectionMaterialEditorViewController"
private let RefractionShaderViewControllerIdentifier = "RefractionMaterialEditorViewController"
private let AddShaderViewControllerIdentifier = "AddMaterialEditorViewController"
private let MixShaderViewControllerIdentifier = "MixMaterialEditorViewController"

private let shaderVCNames = [DefaultShaderViewControllerIdentifier, DiffuseShaderViewControllerIdentifier, EmissionShaderViewControllerIdentifier, ReflectionShaderViewControllerIdentifier, RefractionShaderViewControllerIdentifier, MixShaderViewControllerIdentifier, AddShaderViewControllerIdentifier]

protocol ShaderChooserDelegate: class
{
	func shaderChooserDidChangeShader(chooser: ShaderChooserViewController)
}

class ShaderChooserViewController: NSViewController
{
	var shader: Shader = defaultShader
	{
		didSet
		{
			selectShader()
			loadShaderUI()
		}
	}
	
	@IBOutlet weak var shaderChooser: NSPopUpButton!
	@IBOutlet weak var shaderEditorView: NSView!
	weak var delegate: ShaderChooserDelegate?
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		didChooserShader(self)
	}
    
	@IBAction func didChooserShader(_ sender: AnyObject)
	{
		switch shaderChooser.indexOfSelectedItem
		{
		case 0:
			shader = DefaultShader(color: .white())
			break
		case 1:
			shader = DiffuseShader(color: .white())
			break
		case 2:
			shader = EmissionShader(strength: 1.0, color: .white())
			break
		case 3:
			shader = ReflectionShader(color: .white(), roughness: 0.0)
			break
		case 4:
			shader = RefractionShader(color: .white(), indexOfRefraction: 1.45, roughness: 0.0)
			break
		case 5:
			shader = MixShader(with: DefaultShader(color: .white()), and: DefaultShader(color: .white()), balance: 0.5)
			break
		case 6:
			shader = AddShader(with: DefaultShader(color: .white()), and: DefaultShader(color: .white()))
			break
		default:
			break
		}
		loadShaderUI()
	}
	
	private func selectShader()
	{
		if shader is DefaultShader
		{
			shaderChooser.selectItem(at: 0)
		}
		else if shader is DiffuseShader
		{
			shaderChooser.selectItem(at: 1)
		}
		else if shader is EmissionShader
		{
			shaderChooser.selectItem(at: 2)
		}
		else if shader is ReflectionShader
		{
			shaderChooser.selectItem(at: 3)
		}
		else if shader is RefractionShader
		{
			shaderChooser.selectItem(at: 4)
		}
		else if shader is MixShader
		{
			shaderChooser.selectItem(at: 5)
		}
		else if shader is AddShader
		{
			shaderChooser.selectItem(at: 6)
		}
	}
	
	private func loadShaderUI()
	{
		shaderEditorView.subviews.forEach{$0.removeFromSuperview()}
		childViewControllers.forEach{$0.removeFromParentViewController()}
		let identifier = shaderVCNames[shaderChooser.indexOfSelectedItem]
		
		guard let shaderEditorViewController = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(identifier)) as? ShaderEditorViewController
		else
		{
			fatalError("Shader ViewController cannot be instantiated or does not have matching type.")
		}
		
		shaderEditorViewController.view.frame = shaderEditorView.bounds
		shaderEditorView.addSubview(shaderEditorViewController.view)
		
		shaderEditorView.addConstraint(NSLayoutConstraint(item: shaderEditorView, attribute: .top, relatedBy: .equal, toItem: shaderEditorViewController.view, attribute: .top, multiplier: 1.0, constant: 0.0))
		shaderEditorView.addConstraint(NSLayoutConstraint(item: shaderEditorView, attribute: .bottom, relatedBy: .equal, toItem: shaderEditorViewController.view, attribute: .bottom, multiplier: 1.0, constant: 0.0))
		shaderEditorView.addConstraint(NSLayoutConstraint(item: shaderEditorView, attribute: .left, relatedBy: .equal, toItem: shaderEditorViewController.view, attribute: .left, multiplier: 1.0, constant: 0.0))
		shaderEditorView.addConstraint(NSLayoutConstraint(item: shaderEditorView, attribute: .right, relatedBy: .equal, toItem: shaderEditorViewController.view, attribute: .right, multiplier: 1.0, constant: 0.0))
		
		addChildViewController(shaderEditorViewController)
		
		shaderEditorViewController.shader = shader
		
		delegate?.shaderChooserDidChangeShader(chooser: self)
	}
}
