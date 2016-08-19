//
//  Pathtracing.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 30.07.16.
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
import CoreGraphics
#if !os(watchOS)
import QuartzCore
#endif

#if os(watchOS)
//Workaround for WatchOS, as QuartzCore is not available.
func CACurrentMediaTime() -> Double
{
	//TODO: implement
	return 0.0
}
#endif

private extension Int
{
	func loop<T>(block: (Int) throws -> (T)) rethrows -> [T]
	{
		return try (0 ..< self).map(block)
	}
}

class PathTracer : PathTracingWorkerDelegate
{
	let scene:Scene3D
	
	lazy var triangleStore: TriangleStore =
	{
		return  OctreeTriangleStore(with: self.scene.triangles)
	}()
	
	private var workers: [LocalPathTracingWorker] = []
	private var context: CGContext!
	private(set) var result: CGImage?
	
	weak var delegate: PathTracerDelegate?
	private var managerQueue: DispatchQueue!
	//private var compositingQueue: DispatchQueue!
	private var workerQueue: DispatchQueue!
	private var tiles:[(location: (x: Int, y: Int), size: (width: Int, height: Int))] = []
	private var totalTileCount = 0
	private var height: Int = 0
	private var width: Int = 0
	private var startTime: Double = 0
	
	init(withScene scene: Scene3D)
	{
		self.scene = scene
	}
	
	/**
	
	Renders an image of a scene using path tracing.
	The image will have given width and height.
	
	The ray depth determines, how many bounces will be rendered per ray.
	Higher numbers increase realism but also increase render time.
	
	The tile size determines, how many pixels will be rendered by a single worker at once.
	Bigger tiles reduce overhead but results will not be available as fast.
	
	The number of workers can be used to control CPU utilization.
	One worker will only operate on a single thread, so if the system has 4 cores, 
	4 workers will provide maximum utilization.
	
	The number of samples determines, how often the same ray will be casted.
	If rough or diffuse materials are used, higher numbers will reduce noise,
	which will increase rendering time linearly.
	
	- parameter width: Width of the image, which will be rendered, in pixels
	- parameter height: Height of the image, which will be rendered, in pixels
	
	- parameter tileSize: Size of an area rendered by a single worker at once. Defaults to 32x32.
	
	- parameter workerCount: Number of workers rendering the image. 
	Defaults to the number of available (logical) CPU cores on the machine.
	
	- parameter samples: Samples per (sub-)pixel
	
	*/
	func traceRays(width: Int,
	               height: Int,
	               rayDepth: Int = 16,
	               tileSize: (width: Int, height: Int) = (width: 32, height: 32),
	               workerCount: Int = ProcessInfo.processInfo.processorCount,
	               samples: Int = 1)
	{
		guard (workers.reduce(true){$0 && $1.idle}) else { fatalError("PathTracer not idle") }
		
		managerQueue = DispatchQueue(label: "pathtracer.tracerays.manager")
		//compositingQueue = DispatchQueue(label: "pathtracer.tracerays.compositor")
		workerQueue = DispatchQueue(label: "pathtracing.tracerays.workers", attributes: .concurrent)
		managerQueue.async
		{
			self.workers = (0 ..< workerCount).map
			{ index in
				LocalPathTracingWorker(
					queue: self.workerQueue,
					totalSize: (width: width, height: height),
					rayDepth: rayDepth,
					triangles: self.triangleStore,
					samples: samples,
					camera: self.scene.camera,
					environmentShader: self.scene.environmentShader)
			}
			
			self.workers.forEach{$0.delegate = self}
			let horizontalTileCount = Int(ceil(Float(width / tileSize.width)))
			let verticalTileCount = Int(ceil(Float(height / tileSize.height))) + 1
			
			self.width = width
			self.height = height
			
			self.totalTileCount = horizontalTileCount * verticalTileCount
			
			let tileIndices =  horizontalTileCount
				.loop{ x in verticalTileCount.loop{ y in (x, y)}}
				.flatMap{$0}
			
			self.tiles = tileIndices
				.sorted
				{ (a, b) in
					let distAX = Float(a.0 - horizontalTileCount / 2 + 1)
					let distAY = Float(a.1 - verticalTileCount / 2)
					let distBX = Float(b.0 - horizontalTileCount / 2)
					let distBY = Float(b.1 - verticalTileCount / 2)
					let distA = sqrtf(distAX * distAX + distAY * distAY)
					let distB = sqrtf(distBX * distBX + distBY * distBY)
					return distA < distB
				}
				.map{ xy in (location: (x: xy.0 * tileSize.width, y: (xy.1 + 1) * tileSize.height), size: (width: tileSize.width, heigth: tileSize.height))}
			
			self.context = CGContext(
				data: nil,
				width: width,
				height: height,
				bitsPerComponent: 8,
				bytesPerRow: width * 4,
				space: CGColorSpaceCreateDeviceRGB(),
				bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
			
			self.startTime = CACurrentMediaTime()
			self.workers.forEach{$0.render(region: self.tiles.removeFirst())}
		}
	}
	
	fileprivate final func worker(worker: LocalPathTracingWorker, didFinish region: (location: (x: Int, y: Int), size: (width: Int, height: Int)), result: [UInt16])
	{
		managerQueue.async
		{
			if !self.tiles.isEmpty
			{
				worker.render(region: self.tiles.removeFirst())
			}
			else if (self.workers.reduce(true){$0 && $1.idle})
			{
				self.workers = []
			}
			let rect = CGRect(
				x: region.location.x,
				y: self.height - region.location.y,
				width: region.size.width,
				height: region.size.height)
			
			var mutableResult = result
			
			let ctx = CGContext(
				data: &mutableResult,
				width: region.size.width,
				height: region.size.height,
				bitsPerComponent: 16,
				bytesPerRow: region.size.width * 4 * 2,
				space: CGColorSpaceCreateDeviceRGB(),
				bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
			guard let regionImage = ctx?.makeImage() else { fatalError("Image could not be created") }
			
			self.context.draw(regionImage, in: rect)
			
			guard let image = self.context.makeImage() else { return }
			
			if self.tiles.isEmpty && (self.workers.reduce(true){$0 && $1.idle})
			{
				let time = CACurrentMediaTime()
				print("Finished rendering. Duration: \(Float(time - self.startTime))s")
				DispatchQueue.main.async
				{
					self.result = image
					self.delegate?.pathTracingDidFinish(render: image)
				}
			}
			else
			{
				let progress = 1.0 - Float(self.tiles.count) / Float(self.totalTileCount)
				DispatchQueue.main.async
				{
					self.result = image
					self.delegate?.pathTracingDidUpdate(render: image, progress: progress)
				}
			}
		}
	}
	
	fileprivate func worker(worker: LocalPathTracingWorker, didPerformUpdateOf region: (location: (x: Int, y: Int), size: (width: Int, height: Int)), result: [UInt16])
	{
		managerQueue.async
		{
			var mutableResult = result
			
			let ctx = CGContext(
				data: &mutableResult,
				width: region.size.width,
				height: region.size.height,
				bitsPerComponent: 16,
				bytesPerRow: region.size.width * 4 * 2,
				space: CGColorSpaceCreateDeviceRGB(),
				bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
			guard let regionImage = ctx?.makeImage() else { fatalError("Image could not be created") }
			
			let rect = CGRect(
				x: region.location.x,
				y: self.height - region.location.y,
				width: region.size.width,
				height: region.size.height)
			
			self.context.draw(regionImage, in: rect)
			
			guard let image = self.context.makeImage() else { return }
			
			let progress = 1.0 - Float(self.tiles.count) / Float(self.totalTileCount)
			DispatchQueue.main.async
			{
				self.result = image
				self.delegate?.pathTracingDidUpdate(render: image, progress: progress)
			}
		}
	}
	
	func stop()
	{
		tiles.removeAll()
		workers.forEach{$0.stopRendering()}
	}
}

protocol PathTracerDelegate : class
{
	func pathTracingDidUpdate(render: CGImage, progress: Float)
	func pathTracingDidFinish(render: CGImage)
}

protocol PathTracingWorker
{
	func load(triangles: TriangleStore, rayDepth: Int, camera: Camera, ambientColor: Color)
	
	func render(region: (location: (x: Int, y: Int), size: (width: Int, height: Int)))
	
	func stopRendering()
}

private class LocalPathTracingWorker
{
	private let queue: DispatchQueue
	private let totalSize: (width: Int, height: Int)
	private let triangles:TriangleStore
	weak var delegate: PathTracingWorkerDelegate?
	private(set) var idle: Bool = true
	private let samples: Int
	private let camera: Camera
	private let rayDepth: Int
	private var shouldStop: Bool = false
	private var environmentShader: EnvironmentShader
	
	init(queue: DispatchQueue,
	     totalSize: (width: Int, height: Int),
	     rayDepth: Int,
	     triangles: TriangleStore,
	     samples: Int,
	     camera: Camera,
	     environmentShader: EnvironmentShader)
	{
		self.queue = queue
		self.totalSize = totalSize
		self.triangles = triangles
		self.rayDepth = rayDepth
		self.samples = samples
		self.camera = camera
		self.environmentShader = environmentShader
	}
	
	fileprivate final func render(region: (location: (x: Int, y: Int), size: (width: Int, height: Int)))
	{
		idle = false
		queue.async
		{
			var lastReportTime = CACurrentMediaTime()
			
			var data = [UInt16](repeating: 0, count: region.size.width * region.size.height * 4)
			let horizontalScaleFactor = 1.0 / Float(self.totalSize.height) * Float(self.totalSize.width)
			
			let fovScalingFactor = tanf(self.camera.fieldOfView * 0.5)
			
			let rotationMatrix = Matrix(rotatingWithAlpha: self.camera.rotation.alpha, beta: self.camera.rotation.beta, gamma: self.camera.rotation.gamma)
			
			for y in region.location.y ..< (region.location.y + region.size.height)
			{
				for x in region.location.x ..< (region.location.x + region.size.width)
				{
					let index = ((y - region.location.y) * region.size.width + (x - region.location.x)) * 4
					
					var color:Color = .black()
					for _ in 0 ..< self.samples
					{
						let angle = Float(drand48()) * 2.0 * Float(M_PI)
						let radius = sqrtf(Float(drand48()))
						
						let baseOffsetX = (cosf(angle) * radius) * self.camera.apertureSize
						let baseOffsetY = (sinf(angle) * radius) * self.camera.apertureSize
						let rayOffsetX = baseOffsetX / self.camera.focalDistance
						let rayOffsetY = baseOffsetY / self.camera.focalDistance
						let offsetX = Float(-x) + Float(drand48()) - 0.5
						let offsetY = Float(y) + Float(drand48())  - 0.5
						let rayDirectionX = (offsetX / Float(self.totalSize.width) + 0.5) * horizontalScaleFactor * fovScalingFactor - rayOffsetX
						let rayDirectionY = (offsetY / Float(self.totalSize.height) - 0.5) * fovScalingFactor - rayOffsetY
						
						let rayBase = rotationMatrix * Vector3D(x: baseOffsetX, y: 0, z: baseOffsetY) + self.camera.location
						let rayDirection = rotationMatrix * Vector3D(x: rayDirectionX, y: 1, z: rayDirectionY).normalized
						let ray = Ray3D(base: rayBase,
						                direction: rayDirection)
						
						let closestIntersection = self.triangles.nearestIntersectingTriangle(forRay: ray)
						
						if let intersection = closestIntersection
						{
							let sampleColor = intersection.triangle.material.shader.color(
								forTriangle: intersection.triangle,
								at: intersection.barycentricIntersection,
								point: ray.point(for: intersection.ray),
								rayDirection: ray.direction,
								sceneGeometry: self.triangles,
								environmentShader: self.environmentShader,
								previousColor: .white(),
								maximumRayDepth: self.rayDepth)
							
							color.red += sampleColor.red
							color.green += sampleColor.green
							color.blue += sampleColor.blue
							color.alpha += sampleColor.alpha
						}
						else
						{
							let sampleColor = self.environmentShader.environmentColor(for: ray.direction)
							
							color.red += sampleColor.red
							color.green += sampleColor.green
							color.blue += sampleColor.blue
							color.alpha += sampleColor.alpha
						}
					}
					
					//TODO: Implement Alpha blending
					color = color * (1.0 / Float(self.samples))
					
					data[index]     = color.red16.bigEndian
					data[index + 1] = color.green16.bigEndian
					data[index + 2] = color.blue16.bigEndian
					data[index + 3] = UInt16.max.bigEndian
				}
				if self.shouldStop
				{
					self.shouldStop = false
					self.idle = true
					return
				}
				if CACurrentMediaTime() - lastReportTime >= 2.0
				{
					lastReportTime = CACurrentMediaTime()
					self.delegate?.worker(worker: self, didPerformUpdateOf: region, result: data)
				}
			}
			
			self.idle = true
			self.delegate?.worker(worker: self, didFinish: region, result: data)
		}
	}
	
	func stopRendering()
	{
		shouldStop = true
	}
}

private protocol PathTracingWorkerDelegate : class
{
	func worker(worker: LocalPathTracingWorker, didFinish region: (location: (x: Int, y: Int), size: (width: Int, height: Int)), result: [UInt16])
	func worker(worker: LocalPathTracingWorker, didPerformUpdateOf region: (location: (x: Int, y: Int), size: (width: Int, height: Int)), result: [UInt16])
}
