/*
 
 Copyright (c) <2020>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 */

import Foundation

/**
 
 */
open class AnyImageHDU : AnyHDU {
    
    public convenience init<ByteFormat: FITSByte>(width: Int, height: Int, vectors: [ByteFormat]...){
        self.init()
        
        self.header(HDUKeyword.BITPIX, value: ByteFormat.bitpix, comment: "\(ByteFormat.bitpix) Bit")
        self.header(HDUKeyword.NAXIS, value: vectors.count == 1 ? 2 : 3, comment: "Two dimensional picture")
        self.header("NAXIS\(1)", value: width, comment: "Width")
        self.header("NAXIS\(2)", value: height, comment: "Height")
        if vectors.count > 1 {
            self.header("NAXIS\(3)", value: vectors.count, comment: "Channels")
        }
            
        var new = Data()
        vectors.forEach { vector in
            // and don't foret the bigEndian here or data is screwed (Fixing issue #14)
            let data = vector.bigEndian.withUnsafeBytes { ptr in
                Data(buffer: ptr.bindMemory(to: ByteFormat.self))
            }
            new.append(data)
        }
        self.dataUnit = new
    }
    
    /**
     Sets the content of the data unit to the data from the vectors via memory copy
     */
    public func set<ByteFormat: FITSByte>(width: Int, height: Int, vectors: [ByteFormat]...){
        
        self.header(HDUKeyword.BITPIX, value: ByteFormat.bitpix, comment: "\(ByteFormat.bitpix) Bit")
        self.header(HDUKeyword.NAXIS, value: 3, comment: "Two dimensional picture")
        self.header("NAXIS\(1)", value: width, comment: "Width")
        self.header("NAXIS\(2)", value: height, comment: "Height")
        self.header("NAXIS\(3)", value: vectors.count, comment: "Channels")
        
        var new = Data()
        vectors.forEach { vector in
            // and don't foret the bigEndian here or data is screwed (Fixing issue #14)
            let data = vector.bigEndian.withUnsafeBytes { ptr in
                Data(buffer: ptr.bindMemory(to: ByteFormat.self))
            }
            new.append(data)
        }
        self.dataUnit = new
    }
    
    /**
     Sets the content of the data unit to the data from the vectors via memory copy
     */
    public func set(dimensions: Int..., dataLayout: BITPIX, data: Data){
        
        self.header(HDUKeyword.BITPIX, value: dataLayout, comment: "\(dataLayout) bit")
        self.header(HDUKeyword.NAXIS, value: dimensions.count, comment: "No. of dimensions")
        for dim in 1..<dimensions.count+1 {
            self.header("NAXIS\(dim)", value: dimensions[dim], comment: "Size of \(dim). dimension ")
        }
        
        self.dataUnit = data
    }
    
    /**
     Appends the data from the  vector to the data unit via memory copy
     */
    public func add<ByteFormat: FITSByte>(vector: [ByteFormat]) throws {
        
        guard self.bitpix == ByteFormat.bitpix else {
            throw FitsFail.validationFailed("BITPIX \(ByteFormat.bitpix) incompatible with \(self.bitpix.debugDescription)")
        }
        
        guard vector.count == headerUnit.dataSize else {
            throw FitsFail.validationFailed("Vector size \(vector.count) incompatible with image dimensions")
        }
        
        let channels = self.naxis(3) ?? 0
        self.header("NAXIS\(3)", value: channels + 1, comment: nil)
        
        if var data = self.dataUnit as? Data {
            // append to data unit
            // and don't foret the bigEndian here or data is screwed (Fixing issue #14)
            vector.bigEndian.withUnsafeBytes { ptr in
                data.append(ptr.bindMemory(to: ByteFormat.self))
            }
        } else {
            // set data unit
            // and don't foret the bigEndian here or data is screwed (Fixing issue #14)
            self.dataUnit = vector.bigEndian.withUnsafeBytes{ ptr in
                Data(buffer: ptr.bindMemory(to: ByteFormat.self))
            }
            
        }
    }
}

extension AnyImageHDU {
    
    /**
     Sets the content of the data unit to the data at the given pointer
     */
    public func set<ByteFormat: FITSByte>(width: Int, height: Int, ptr: UnsafeBufferPointer<ByteFormat>){
        
        if var data = self.dataUnit as? Data {
            data.append(ptr)
        } else {
            self.dataUnit = Data(buffer: ptr)
        }
        
    }
}
