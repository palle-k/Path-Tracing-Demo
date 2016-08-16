//
//  SceneEncoding.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 12.08.16.
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

protocol TextureEncoder: NSCoding
{
	
}

protocol TextureDecoder
{
	var decoded: Texture { get }
}

protocol TextureEncoding
{
	var encoded: TextureEncoder { get }
}

class ImageTextureEncoder: NSObject, TextureEncoder, TextureDecoder
{
	private var texture: ImageTexture
	
	init(with texture: ImageTexture)
	{
		self.texture = texture
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		let width = aDecoder.decodeInteger(forKey: "width")
		let height = aDecoder.decodeInteger(forKey: "height")
		var length: Int = 0
		guard let pixelData = aDecoder.decodeBytes(forKey: "pixel_data", returnedLength: &length) else { fatalError("pixel data could not be decoded") }
		guard width * height * 4 == length else { return nil }
		let pixelDataArray = (0..<length).map(pixelData.advanced).map{$0.pointee}
		texture = ImageTexture(with: pixelDataArray, width: width, height: height)
	}
	
	func encode(with aCoder: NSCoder)
	{
		aCoder.encode(texture.width, forKey: "width")
		aCoder.encode(texture.height, forKey: "height")
		aCoder.encodeBytes(texture.pixelData, length: texture.width * texture.height * 4, forKey: "pixel_data")
	}
	
	var decoded: Texture
	{
		return texture
	}
}

extension ImageTexture: TextureEncoding
{
	var encoded: TextureEncoder
	{
		return ImageTextureEncoder(with: self)
	}
}

class CheckerboardTextureEncoder: NSObject, TextureEncoder, TextureDecoder
{
	private var texture: CheckerboardTexture
	
	init(with texture: CheckerboardTexture)
	{
		self.texture = texture
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		let horizontalTiles = aDecoder.decodeInteger(forKey: "horizontal_tiles")
		let verticalTiles = aDecoder.decodeInteger(forKey: "vertical_tiles")
		texture = CheckerboardTexture(horizontalTiles: horizontalTiles, verticalTiles: verticalTiles)
	}
	
	func encode(with aCoder: NSCoder)
	{
		aCoder.encode(texture.horizontalTiles, forKey: "horizontal_tiles")
		aCoder.encode(texture.verticalTiles, forKey: "vertical_tiles")
	}
	
	var decoded: Texture
	{
		return texture
	}
}

extension CheckerboardTexture: TextureEncoding
{
	var encoded: TextureEncoder
	{
		return CheckerboardTextureEncoder(with: self)
	}
}

protocol ShaderEncoder: NSCoding
{
	
}

extension ShaderEncoder
{
	static func encode(color: Color, named name: String, with coder: NSCoder)
	{
		let red = color.red
		let green = color.green
		let blue = color.blue
		let alpha = color.alpha

		coder.encode(red, forKey: "\(name)_red");
		coder.encode(green, forKey: "\(name)_green");
		coder.encode(blue, forKey: "\(name)_blue");
		coder.encode(alpha, forKey: "\(name)_alpha");
	}
	
	static func decodeColor(named name: String, with coder: NSCoder) -> Color
	{
		let red = coder.decodeFloat(forKey: "\(name)_red")
		let green = coder.decodeFloat(forKey: "\(name)_green")
		let blue = coder.decodeFloat(forKey: "\(name)_blue")
		let alpha = coder.decodeFloat(forKey: "\(name)_alpha")
		
		return Color(withRed: red, green: green, blue: blue, alpha: alpha)
	}
}

protocol ShaderEncoding
{
	var encoded: ShaderEncoder { get }
}

protocol ShaderDecoder
{
	var decoded: Shader { get }
}

class DefaultShaderEncoder: NSObject, ShaderDecoder, ShaderEncoder
{
	private let shader: DefaultShader
	
	init(with shader: DefaultShader)
	{
		self.shader = shader
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		let color = self.dynamicType.decodeColor(named: "shader_color", with: aDecoder)
		let texture = aDecoder.decodeObject(forKey: "texture") as? TextureDecoder
		shader = DefaultShader(color: color, texture: texture?.decoded)
	}
	
	func encode(with aCoder: NSCoder)
	{
		self.dynamicType.encode(color: shader.color, named: "shader_color", with: aCoder)
		aCoder.encode((shader.texture as? TextureEncoding)?.encoded, forKey: "texture")
	}
	
	var decoded: Shader
	{
		return shader
	}
}

extension DefaultShader: ShaderEncoding
{
	var encoded: ShaderEncoder
	{
		return DefaultShaderEncoder(with: self)
	}
}

class DiffuseShaderEncoder: NSObject, ShaderDecoder, ShaderEncoder
{
	private let shader: DiffuseShader
	
	init(with shader: DiffuseShader)
	{
		self.shader = shader
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		let color = self.dynamicType.decodeColor(named: "shader_color", with: aDecoder)
		let texture = aDecoder.decodeObject(forKey: "texture") as? TextureDecoder
		shader = DiffuseShader(color: color, texture: texture?.decoded)
	}
	
	func encode(with aCoder: NSCoder)
	{
		self.dynamicType.encode(color: shader.color, named: "shader_color", with: aCoder)
		aCoder.encode((shader.texture as? TextureEncoding)?.encoded, forKey: "texture")
	}
	
	var decoded: Shader
	{
		return shader
	}
}

extension DiffuseShader: ShaderEncoding
{
	var encoded: ShaderEncoder
	{
		return DiffuseShaderEncoder(with: self)
	}
}

class EmissionShaderEncoder: NSObject, ShaderDecoder, ShaderEncoder
{
	private let shader: EmissionShader
	
	init(with shader: EmissionShader)
	{
		self.shader = shader
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		let color = self.dynamicType.decodeColor(named: "shader_color", with: aDecoder)
		let texture = aDecoder.decodeObject(forKey: "texture") as? TextureDecoder
		let strength = aDecoder.decodeFloat(forKey: "strength")
		shader = EmissionShader(strength: strength, color: color, texture: texture?.decoded)
	}
	
	func encode(with aCoder: NSCoder)
	{
		self.dynamicType.encode(color: shader.color, named: "shader_color", with: aCoder)
		aCoder.encode((shader.texture as? TextureEncoding)?.encoded, forKey: "texture")
		aCoder.encode(shader.strength, forKey: "strength")
	}
	
	var decoded: Shader
	{
		return shader
	}
}

extension EmissionShader: ShaderEncoding
{
	var encoded: ShaderEncoder
	{
		return EmissionShaderEncoder(with: self)
	}
}

class ReflectionShaderEncoder: NSObject, ShaderDecoder, ShaderEncoder
{
	private let shader: ReflectionShader
	
	init(with shader: ReflectionShader)
	{
		self.shader = shader
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		let color = self.dynamicType.decodeColor(named: "shader_color", with: aDecoder)
		let texture = aDecoder.decodeObject(forKey: "texture") as? TextureDecoder
		let roughness = aDecoder.decodeFloat(forKey: "roughness")
		shader = ReflectionShader(color: color, roughness: roughness, texture: texture?.decoded)
	}
	
	func encode(with aCoder: NSCoder)
	{
		self.dynamicType.encode(color: shader.color, named: "shader_color", with: aCoder)
		aCoder.encode((shader.texture as? TextureEncoding)?.encoded, forKey: "texture")
		aCoder.encode(shader.roughness, forKey: "roughness")
	}
	
	var decoded: Shader
	{
		return shader
	}
}

extension ReflectionShader: ShaderEncoding
{
	var encoded: ShaderEncoder
	{
		return ReflectionShaderEncoder(with: self)
	}
}

class RefractionShaderEncoder: NSObject, ShaderDecoder, ShaderEncoder
{
	private let shader: RefractionShader
	
	init(with shader: RefractionShader)
	{
		self.shader = shader
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		let color = self.dynamicType.decodeColor(named: "shader_color", with: aDecoder)
		let texture = aDecoder.decodeObject(forKey: "texture") as? TextureDecoder
		let roughness = aDecoder.decodeFloat(forKey: "roughness")
		let ior = aDecoder.decodeFloat(forKey: "ior")
		
		let volumeColor: Color
		
		if aDecoder.containsValue(forKey: "volume_color_red")
		{
			volumeColor = self.dynamicType.decodeColor(named: "volume_color", with: aDecoder)
		}
		else
		{
			volumeColor = .white()
		}
		
		let absorptionStrength: Float
		
		if aDecoder.containsValue(forKey: "absorption_strength")
		{
			absorptionStrength = aDecoder.decodeFloat(forKey: "absorption_strength")
		}
		else
		{
			absorptionStrength = 0
		}
		
		shader = RefractionShader(color: color, texture: texture?.decoded, indexOfRefraction: ior, roughness: roughness, volumeColor: volumeColor, absorptionStrength: absorptionStrength)
	}
	
	func encode(with aCoder: NSCoder)
	{
		self.dynamicType.encode(color: shader.color, named: "shader_color", with: aCoder)
		aCoder.encode((shader.texture as? TextureEncoding)?.encoded, forKey: "texture")
		aCoder.encode(shader.roughness, forKey: "roughness")
		aCoder.encode(shader.indexOfRefraction, forKey: "ior")
		self.dynamicType.encode(color: shader.volumeColor, named: "volume_color", with: aCoder)
		aCoder.encode(shader.absorptionStrength, forKey: "absorption_strength")
	}
	
	var decoded: Shader
	{
		return shader
	}
}

extension RefractionShader: ShaderEncoding
{
	var encoded: ShaderEncoder
	{
		return RefractionShaderEncoder(with: self)
	}
}

class MixShaderEncoder: NSObject, ShaderDecoder, ShaderEncoder
{
	private let shader: MixShader
	
	init(with shader: MixShader)
	{
		self.shader = shader
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		let balance = aDecoder.decodeFloat(forKey: "balance")
		let shader1 = aDecoder.decodeObject(forKey: "shader_1") as? ShaderDecoder
		let shader2 = aDecoder.decodeObject(forKey: "shader_2") as? ShaderDecoder
		
		shader = MixShader(with: shader1?.decoded ?? DefaultShader(color: .white()), and: shader2?.decoded ?? DefaultShader(color: .white()), balance: balance)
	}
	
	func encode(with aCoder: NSCoder)
	{
		aCoder.encode(shader.balance, forKey: "balance")
		aCoder.encode((shader.shader1 as? ShaderEncoding)?.encoded, forKey: "shader_1")
		aCoder.encode((shader.shader2 as? ShaderEncoding)?.encoded, forKey: "shader_2")
	}
	
	var decoded: Shader
	{
		return shader
	}
}

extension MixShader: ShaderEncoding
{
	var encoded: ShaderEncoder
	{
		return MixShaderEncoder(with: self)
	}
}

class AddShaderEncoder: NSObject, ShaderDecoder, ShaderEncoder
{
	private let shader: AddShader
	
	init(with shader: AddShader)
	{
		self.shader = shader
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		guard
			let shader1 = aDecoder.decodeObject(forKey: "shader_1") as? ShaderDecoder,
			let shader2 = aDecoder.decodeObject(forKey: "shader_2") as? ShaderDecoder
			else
		{
			fatalError("cannot decode shader")
		}
		shader = AddShader(with: shader1.decoded, and: shader2.decoded)
	}
	
	func encode(with aCoder: NSCoder)
	{
		aCoder.encode((shader.shader1 as? ShaderEncoding)?.encoded, forKey: "shader_1")
		aCoder.encode((shader.shader2 as? ShaderEncoding)?.encoded, forKey: "shader_2")
	}
	
	var decoded: Shader
	{
		return shader
	}
}

extension AddShader: ShaderEncoding
{
	var encoded: ShaderEncoder
	{
		return AddShaderEncoder(with: self)
	}
}
