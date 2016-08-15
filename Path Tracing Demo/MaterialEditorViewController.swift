//
//  MaterialEditorViewController.swift
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

import AppKit
import Cocoa

class MaterialEditorViewController: NSViewController
{
	@IBOutlet weak var materialList: NSTableView!
	@IBOutlet weak var shaderContainerView: NSView!
	
	private lazy var materials:[Material] = ApplicationDelegate.scene?.objects.flatMap{$0.materials}.distinct().sorted{$0.name < $1.name} ?? []
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		materialList.delegate = self
		materialList.dataSource = self
		NotificationCenter.default.addObserver(self, selector: #selector(reload(notification:)), name: "RenderResultViewUpdatePathTracer" as NSNotification.Name, object: nil)
	}
	
	override func viewDidAppear()
	{
		childViewControllers.flatMap{$0 as? ShaderChooserViewController}.forEach{$0.delegate = self}
	}
	
	func reload(notification: NSNotification?)
	{
		materials = ApplicationDelegate.scene?.objects.flatMap{$0.materials}.distinct().sorted{$0.name < $1.name} ?? []
		self.materialList.reloadData()
	}
}

extension MaterialEditorViewController: NSTableViewDataSource
{
	func numberOfRows(in tableView: NSTableView) -> Int
	{
		return materials.count
	}
}

extension MaterialEditorViewController: NSTableViewDelegate
{
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
	{
		var cell = tableView.make(withIdentifier: "MaterialCell", owner: self)
		if cell == nil
		{
			cell = NSTextField(frame: NSRect(x: 0, y: 0, width: tableView.frame.width, height: 27))
			cell?.identifier = "MaterialCell"
			if let textCell = cell as? NSTextField
			{
				textCell.isEditable = false
				textCell.isSelectable = false
				textCell.isBezeled = false
				textCell.drawsBackground = false
			}
		}
		(cell as? NSTextField)?.stringValue = materials[row].name
		return cell
	}
	
	func tableViewSelectionDidChange(_ notification: Notification)
	{
		let selectedIndex = materialList.selectedRow
		guard selectedIndex >= 0 else { return }
		guard let shaderChooserViewController = (childViewControllers.flatMap{$0 as? ShaderChooserViewController}.first) else { return }
		shaderChooserViewController.shader = materials[selectedIndex].shader
	}
}

extension MaterialEditorViewController: ShaderChooserDelegate
{
	func shaderChooserDidChangeShader(chooser: ShaderChooserViewController)
	{
		let selectedIndex = materialList.selectedRow
		guard selectedIndex >= 0 else { return }
		materials[selectedIndex].shader = chooser.shader
	}
}
