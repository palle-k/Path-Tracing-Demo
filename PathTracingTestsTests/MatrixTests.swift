//
//  PathTracingTestsTests.swift
//  PathTracingTestsTests
//
//  Created by Palle Klewitz on 31.07.16.
//  Copyright © 2016 Palle Klewitz. All rights reserved.
//

import XCTest

class MatrixTests: XCTestCase
{
    
    override func setUp()
	{
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown()
	{
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func testMatrixTranspose()
	{
		let matA = Matrix(rows: [[1,2,0],[0,1,1]])
		let matB = Matrix(rows: [[1,5,0],[0,2,1],[1,4,1]])
		let matC = Matrix(rows: [[2,1],[0,0],[1,0],[1,-1]])
		let matD = Matrix(columns:[[1,2,0,-1]])
		let matE = Matrix(rows: [[1,-1,0]])
		let matF = Matrix(rows: [[3]])
		
		let matAT = matA.transposed
		let matBT = matB.transposed
		let matCT = matC.transposed
		let matDT = matD.transposed
		let matET = matE.transposed
		let matFT = matF.transposed
		
		XCTAssertEqual(matAT.rows, [[1,0],[2,1],[0,1]])
		XCTAssertEqual(matBT.rows, [[1,0,1],[5,2,4],[0,1,1]])
		XCTAssertEqual(matCT.rows, [[2,0,1,1],[1,0,0,-1]])
		XCTAssertEqual(matDT.rows, [[1,2,0,-1]])
		XCTAssertEqual(matET.rows, [[1],[-1],[0]])
		XCTAssertEqual(matFT.rows, [[3]])
	}
	
	func testMatrixMultiplication()
	{
		let matA = Matrix(rows: [[1,2,0],[0,1,1]])
		let matB = Matrix(rows: [[1,5,0],[0,2,1],[1,4,1]])
		let matC = Matrix(rows: [[2,1],[0,0],[1,0],[1,-1]])
		let matD = Matrix(columns:[[1,2,0,-1]])
		let matE = Matrix(rows: [[1,-1,0]])
		let matF = Matrix(rows: [[3]])
		
		let matAB = matA * matB
		XCTAssertEqual(matAB.rows, [[1,9,2],[1,6,2]])
		
		let matCA = matC * matA
		XCTAssertEqual(matCA.rows, [[2,5,1],[0,0,0],[1,2,0],[1,1,-1]])
		
		let matDE = matD * matE
		XCTAssertEqual(matDE.rows, [[1,-1,0],[2,-2,0,],[0,0,0],[-1,1,0]])
		
		let matDF = matD * matF
		XCTAssertEqual(matDF.rows, [[3],[6],[0],[-3]])
		
		let matEB = matE * matB
		XCTAssertEqual(matEB.rows, [[1,3,-1]])
		
		let matFE = matF * matE
		XCTAssertEqual(matFE.rows, [[3,-3,0]])
	}
	
	func testMatrixVectorMultiplication()
	{
		let vecA = Vector3D(x: 1, y: 2, z: 3)
		let res1 = Matrix3x3Identity * vecA
		XCTAssertEqual(vecA, res1)
	}
    
}
