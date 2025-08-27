//
//  FileSizeCalculatorTests.swift
//  nnuninstallerTests
//
//  Created by Nikolai Nobadi on 8/27/25.
//

import Testing
@testable import nnuninstaller

struct FileSizeCalculatorTests {
    @Test("formats bytes correctly")
    func formatSize_withVariousSizes_formatsCorrectly() {
        let calculator = FileSizeCalculator()
        
        // Test various sizes
        #expect(calculator.formatSize(0) == "Zero KB")
        #expect(calculator.formatSize(1024).contains("1"))
        #expect(calculator.formatSize(1024).contains("KB"))
        #expect(calculator.formatSize(1048576).contains("1"))  // 1 MB
        #expect(calculator.formatSize(1073741824).contains("1"))  // 1 GB
        
        // Test that it includes units
        #expect(calculator.formatSize(5242880).contains("MB"))  // 5 MB
        #expect(calculator.formatSize(10737418240).contains("GB"))  // 10 GB
    }
    
    @Test("calculates size returns zero for non-existent path")
    func calculateSize_withNonExistentPath_returnsZero() {
        let calculator = FileSizeCalculator()
        
        let size = calculator.calculateSize(at: "/non/existent/path/file.txt")
        
        #expect(size == 0)
    }
    
    @Test("handles empty path")
    func calculateSize_withEmptyPath_returnsZero() {
        let calculator = FileSizeCalculator()
        
        let size = calculator.calculateSize(at: "")
        
        #expect(size == 0)
    }
}