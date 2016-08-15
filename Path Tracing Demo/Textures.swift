//
//  Textures.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 05.08.16.
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

import Foundation

#if os(iOS)
import UIKit
#elseif os(watchOS)
import UIKit
#elseif os(OSX)
import Cocoa
#endif


struct TextureCoordinate
{
	var u: Float
	var v: Float
}

@inline(__always)
func * (left: TextureCoordinate, right: Float) -> TextureCoordinate
{
	return TextureCoordinate(u: left.u * right, v: left.v * right)
}

@inline(__always)
func * (left: Float, right: TextureCoordinate) -> TextureCoordinate
{
	return right * left
}

func + (left: TextureCoordinate, right: TextureCoordinate) -> TextureCoordinate
{
	return TextureCoordinate(u: left.u + right.u, v: left.v + right.v)
}

protocol Texture
{
	func color(`for` textureCoordinate: TextureCoordinate, atAngle incidentAngle: Float) -> Color
}

class CheckerboardTexture: Texture
{
	var horizontalTiles: Int
	var verticalTiles: Int
	
	init(horizontalTiles: Int, verticalTiles: Int)
	{
		self.horizontalTiles = horizontalTiles
		self.verticalTiles = verticalTiles
	}
	
	func color(for textureCoordinate: TextureCoordinate, atAngle incidentAngle: Float) -> Color
	{
		if fmodf(textureCoordinate.u * Float(horizontalTiles), 2.0) <= 1.0
		{
			return fmodf(textureCoordinate.v * Float(verticalTiles), 2.0) <= 1.0 ? .black() : .white()
		}
		else
		{
			return fmodf(textureCoordinate.v * Float(verticalTiles), 2.0) <= 1.0 ? .white() : .black()
		}
	}
}

extension CheckerboardTexture: CustomStringConvertible
{
	var description: String
	{
		return "CheckerboardTexture (\(horizontalTiles)x\(verticalTiles))"
	}
}

class ImageTexture: Texture
{
	var pixelData: [UInt8]
	var width: Int
	var height: Int
	
	init?(with image: CGImage)
	{
		self.width = image.width
		self.height = image.height
		
		pixelData = [UInt8](repeating: 0, count: width * height * 4)
		guard let ctx = CGContext(
			data: &pixelData,
			width: width,
			height: height,
			bitsPerComponent: 8,
			bytesPerRow: width * 4,
			space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
		else
		{
			return nil
		}
		ctx.draw(in: CGRect(x: 0, y: 0, width: width, height: height), image: image)
	}
	
	init(with data: [UInt8], width: Int, height: Int)
	{
		self.pixelData = data
		self.width = width
		self.height = height
	}
	
	convenience init?(contentsOf fileURL: URL)
	{
		guard let data = try? Data(contentsOf: fileURL) else { return nil }
#if os(iOS)
		guard let image = UIImage(data: data) else { return nil }
		guard let cgImage = image.cgImage else { return nil }
#elseif os(watchOS)
		guard let image = UIImage(data: data) else { return nil }
		guard let cgImage = image.cgImage else { return nil }
#elseif os(OSX)
		guard let image = NSImage(data: data) else { return nil }
		guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
#endif
		self.init(with: cgImage)
	}
	
	@inline(__always)
	private func rangeLimited(_ textureCoordinate: TextureCoordinate) -> TextureCoordinate
	{
		let u = fmodf(fmodf(textureCoordinate.u, 1.0) + 1.0, 1.0)
		let v = fmodf(fmodf(textureCoordinate.v, 1.0) + 1.0, 1.0)
		
		return TextureCoordinate(u: u, v: v)
	}
	
	func color(for textureCoordinate: TextureCoordinate, atAngle incidentAngle: Float) -> Color
	{
		let limited = rangeLimited(textureCoordinate)
		let x = limited.u * Float(width-1)
		let y = limited.v * Float(height-1)
		
		let lx = floorf(x)
		let gx = ceilf(x)
		let ly = floorf(y)
		let gy = ceilf(y)
		
		let flx = x - lx
		let fgx = 1 - flx
		let fly = y - ly
		let fgy = 1 - fly
		
		let indexLL = (Int(lx) + width * Int(ly)) * 4
		let indexGL = (Int(gx) + width * Int(ly)) * 4
		let indexLG = (Int(lx) + width * Int(gy)) * 4
		let indexGG = (Int(gx) + width * Int(gy)) * 4
		
		let colorLL = Color(withRed: self.pixelData[indexLL],
		                    green:   self.pixelData[indexLL+1],
		                    blue:    self.pixelData[indexLL+2],
		                    alpha:   self.pixelData[indexLL+3])
		
		let colorGL = Color(withRed: self.pixelData[indexGL],
		                    green:   self.pixelData[indexGL+1],
		                    blue:    self.pixelData[indexGL+2],
		                    alpha:   self.pixelData[indexGL+3])
		
		let colorLG = Color(withRed: self.pixelData[indexLG],
		                    green:   self.pixelData[indexLG+1],
		                    blue:    self.pixelData[indexLG+2],
		                    alpha:   self.pixelData[indexLG+3])
		
		let colorGG = Color(withRed: self.pixelData[indexGG],
		                    green:   self.pixelData[indexGG+1],
		                    blue:    self.pixelData[indexGG+2],
		                    alpha:   self.pixelData[indexGG+3])
		
		//Bilinear interpolation
		let linearLower = colorLL * flx + colorGL * fgx
		let linearUpper = colorLG * flx + colorGG * fgx
		return linearLower * fly + linearUpper * fgy
	}
}

extension ImageTexture: CustomStringConvertible
{
	var description: String
	{
		return "ImageTexture (w: \(width), h: \(height))"
	}
}


