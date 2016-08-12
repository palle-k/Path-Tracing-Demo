//
//  Matrix.swift
//  PathTracingTests
//
//  Created by Palle Klewitz on 31.07.16.
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
#if !os(watchOS)
import Accelerate
#endif
	
//MARK: Matrix Declarations

struct Matrix
{
	var rows:[[Float]]
	
	var columns:[[Float]]
	{
		var columns = Array<Array<Float>>(repeating: Array<Float>(repeating: 0.0, count: height), count: width)
		for i in 0 ..< height
		{
			for j in 0 ..< width
			{
				columns[j][i] = rows[i][j]
			}
		}
		return columns
	}
	
	var width:Int
	{
		return rows.first?.count ?? 0
	}
	
	var height:Int
	{
		return rows.count
	}
	
	var determinant: Float
	{
		guard ((3...4) ~= width) && height == 3 else { fatalError("Determinant not yet implemented for matrices (A|b) where A is not a 3x3-matrix.") }
		return rows[0][0] * rows[1][1] * rows[2][2]
			+ rows[0][1] * rows[1][2] * rows[2][0]
			+ rows[0][2] * rows[1][0] * rows[2][1]
			- rows[0][2] * rows[1][1] * rows[2][0]
			- rows[0][0] * rows[1][2] * rows[2][1]
			- rows[0][1] * rows[1][0] * rows[2][2]
	}
	
	var transposed: Matrix
	{
		return Matrix(columns: rows)
	}
	
	init(rows:[[Float]])
	{
//		guard rows.count > 0 && (rows.map{$0.count == rows[0].count}.reduce(true){$0 && $1})
//			else
//		{
//			fatalError("Matrix must be at least 1x1 and all rows must be of equal size")
//		}
		self.rows = rows
	}
	
	init(columns:[[Float]])
	{
		var rows = Array<Array<Float>>(repeating: Array<Float>(repeating: 0.0, count: columns.count), count: columns.first?.count ?? 0)
		for i in 0 ..< columns.count
		{
			for j in 0 ..< (columns.first?.count ?? 0)
			{
				rows[j][i] = columns[i][j]
			}
		}
		self.rows = rows
	}
	
	init(vectors: [Vector3D])
	{
		self.init(columns: vectors.map{[$0.x, $0.y, $0.z]})
	}
	
	init(vectors: Vector3D...)
	{
		self.init(columns: vectors.map{[$0.x, $0.y, $0.z]})
	}
	
	init(data: [Float], width: Int)
	{
		let height = data.count / width
		var rows:[[Float]] = []
		for rowIndex in 0 ..< height
		{
			var row:[Float] = []
			for columnIndex in 0 ..< width
			{
				row += [data[columnIndex+rowIndex*width]]
			}
			rows += [row]
		}
		self.rows = rows
	}
	
	init(data: [Float], height: Int)
	{
		self.init(data: data, width: data.count / height)
	}
	
	init(rotatingWithAlpha alpha: Float, beta: Float, gamma: Float)
	{
		let zRot = Matrix(rows: [[ cosf(alpha), -sinf(alpha),			 0],
		                         [ sinf(alpha),  cosf(alpha),			 0],
		                         [			 0,			   0,			 1]])
		
		let yRot = Matrix(rows: [[  cosf(beta),			   0,	sinf(beta)],
		                         [			 0,			   1,			 0],
		                         [ -sinf(beta),			   0,   cosf(beta)]])
		
		let xRot = Matrix(rows: [[			 1,			   0,			 0],
		                         [			 0,  cosf(gamma), -sinf(gamma)],
		                         [			 0,  sinf(gamma),  cosf(gamma)]])
		self.rows = (zRot * yRot * xRot).rows
	}
	
//	mutating func swapRow(_ row: Int, with otherRow: Int)
//	{
//		(rows[row], rows[otherRow]) = (rows[otherRow], rows[row])
//	}
//	
//	mutating func addRow(_ row: Int, to target: Int, withFactor factor: Float = 1.0)
//	{
//		//rows[target] = rows[target].enumerated().map{$1+self.rows[row][$0]*factor}
//		var result = rows[target]
//		vDSP_vsma(rows[row], 1, [factor], result, 1, &result, 1, vDSP_Length(rows[target].count))
//		rows[target] = result
//	}
//	
//	mutating func multiplyRow(_ row: Int, with factor: Float)
//	{
//		//rows[row] = rows[row].map{$0*factor}
//		var result = rows[row]
//		vDSP_vsmul(result, 1, [factor], &result, 1, vDSP_Length(rows[row].count))
//		rows[row] = result
//	}
	
	func solve3x3() -> (x: Float, y: Float, z: Float)?
	{
		let det = determinant
		guard determinant != 0 else { return nil }

		// solve using Cramer's rule (only works for quadratic matrices)
		// implemented only for 3x3 matrices (with right side included)
		
		let det1 = rows[0][3] * rows[1][1] * rows[2][2]
			+ rows[0][1] * rows[1][2] * rows[2][3]
			+ rows[0][2] * rows[1][3] * rows[2][1]
			- rows[0][2] * rows[1][1] * rows[2][3]
			- rows[0][3] * rows[1][2] * rows[2][1]
			- rows[0][1] * rows[1][3] * rows[2][2]
		
		let det2 = rows[0][0] * rows[1][3] * rows[2][2]
			+ rows[0][3] * rows[1][2] * rows[2][0]
			+ rows[0][2] * rows[1][0] * rows[2][3]
			- rows[0][2] * rows[1][3] * rows[2][0]
			- rows[0][0] * rows[1][2] * rows[2][3]
			- rows[0][3] * rows[1][0] * rows[2][2]
		
		let det3 = rows[0][0] * rows[1][1] * rows[2][3]
			+ rows[0][1] * rows[1][3] * rows[2][0]
			+ rows[0][3] * rows[1][0] * rows[2][1]
			- rows[0][3] * rows[1][1] * rows[2][0]
			- rows[0][0] * rows[1][3] * rows[2][1]
			- rows[0][1] * rows[1][0] * rows[2][3]
		
		return (x: det1 / det, y: det2 / det, z: det3 / det)
	}
}

extension Matrix : CustomStringConvertible
{
	var description: String
	{
		return rows
			.map
			{
				$0.map{String(format: "%5.2f", $0)}
					.joined(separator: ", ")
			}
			.map{"|\($0)|"}
			.joined(separator: "\n")
	}
	
}

extension Matrix : Equatable { }

let Matrix3x3Identity = Matrix(rows: [[1,0,0],[0,1,0],[0,0,1]])

//MARK: Operators

func == (left: Matrix, right: Matrix) -> Bool
{
	return left.rows == right.rows
}

#if os(watchOS)
func * (left: Matrix, right: Matrix) -> Matrix
{
	assert(left.width == right.height)
	var resultBuffer = Array<[Float]>(repeating: Array<Float>(repeating: 0, count: right.width), count: left.height)
	
	for row in 0 ..< left.height
	{
		for column in 0 ..< right.width
		{
			var sum: Float = 0
			for i in 0 ..< left.width
			{
				sum += left.rows[row][i] * right.columns[column][i]
			}
			resultBuffer[row][column] = sum
		}
	}
	
	return Matrix(rows: resultBuffer)
}
#else
func * (left: Matrix, right: Matrix) -> Matrix
{
	assert(left.width == right.height)
	var resultBuffer = Array<Float>(repeating: 0, count: left.height * right.width)
	
	vDSP_mmul(left.rows.flatMap{$0}, 1, right.rows.flatMap{$0}, 1, &resultBuffer, 1, vDSP_Length(left.height), vDSP_Length(right.width), vDSP_Length(left.width))
	
	return Matrix(data: resultBuffer, width: right.width)
}
#endif

func * (left: Matrix, right: Vector3D) -> Vector3D
{
	//print("Transforming Vector: \(right) using:\n\(left)")
	if left.width == 3 && left.height == 3
	{
		let resultX = left.rows[0][0] * right.x + left.rows[0][1] * right.y + left.rows[0][2] * right.z
		let resultY = left.rows[1][0] * right.x + left.rows[1][1] * right.y + left.rows[1][2] * right.z
		let resultZ = left.rows[2][0] * right.x + left.rows[2][1] * right.y + left.rows[2][2] * right.z
		let result = Vector3D(x: resultX, y: resultY, z: resultZ)
		//print("Result: \(result)")
		return result
	}
	else if left.width == 4 && left.height == 4
	{
		let resultX = left.rows[0][0] * right.x + left.rows[0][1] * right.y + left.rows[0][2] * right.z + left.rows[0][3]
		let resultY = left.rows[1][0] * right.x + left.rows[1][1] * right.y + left.rows[1][2] * right.z + left.rows[1][3]
		let resultZ = left.rows[2][0] * right.x + left.rows[2][1] * right.y + left.rows[2][2] * right.z + left.rows[2][3]
		let resultW = left.rows[3][0] * right.x + left.rows[3][1] * right.y + left.rows[3][2] * right.z + left.rows[3][3]
		let result = Vector3D(x: resultX / resultW, y: resultY / resultW, z: resultZ / resultW)
		//print("Result: \(result)")
		return result
	}
	fatalError("Incompatible matrix size.")
}
