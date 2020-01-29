//
//  TestSwim.swift
//  TestImage
//
//  Created by Zhang on 2020/1/29.
//  Copyright © 2020 Zhang. All rights reserved.
//

import Foundation
import Swim


class TestSwim {
    
    class func test() {
        let filePath = Bundle.main.path(forResource:"ming", ofType: "png")!
        let url = URL(fileURLWithPath: filePath)
        
        let image = try! Image<RGBA, Double>(contentsOf: url)
        let ratio = ((Double)(image.width)) / ((Double)(image.height))
        let showWidth: Int = 200
        let showHeight = Int(ceil(Double(showWidth) / ratio))
//        let resizedBL = image.resize(width: showWidth, height: showHeight) // default .bilinear
        let resizedNN = image.resize(width: showWidth, height: showHeight, method: .bilinear)
        
        let newUIImage = resizedNN.uiImage()
        let testimage = image.uiImage()
        
        ViewController.saveImage(newUIImage, named: "swim.png")
    }
    
    
}
