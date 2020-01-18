//
//  ResampleFilter.swift
//  TestImage
//
//  Created by Zhang on 2020/1/18.
//  Copyright © 2020 Zhang. All rights reserved.
//

import Foundation
import CoreImage

public class ResampleFilter: CIFilter {
    var inputImage : CIImage?
    var inputScaleX: CGFloat = 1
    var inputScaleY: CGFloat = 1
    let warpKernel = CIWarpKernel(source:
        "kernel vec2 resample(float inputScaleX, float inputScaleY)" +
            "   {                                                      " +
            "       float y = (destCoord().y / inputScaleY);           " +
            "       float x = (destCoord().x / inputScaleX);           " +
            "       return vec2(x,y);                                  " +
            "   }                                                      "
    )

    override public var outputImage: CIImage! {
        if let inputImage = inputImage, let kernel = warpKernel {
            let arguments = [inputScaleX, inputScaleY]

            let extent = CGRect(origin: inputImage.extent.origin,
                                size: CGSize(width: inputImage.extent.width*inputScaleX,
                                    height: inputImage.extent.height*inputScaleY))

            return kernel.apply(extent: extent, roiCallback: { (index, rect) -> CGRect in
                let sampleX = rect.origin.x / self.inputScaleX
                let sampleY = rect.origin.y / self.inputScaleY
                let sampleWidth = rect.width / self.inputScaleX
                let sampleHeight = rect.height / self.inputScaleY
                
                let sampleRect = CGRect(x: sampleX, y: sampleY, width: sampleWidth, height: sampleHeight)
                
                return sampleRect
            }, image: inputImage, arguments: arguments)

        }
        return nil
    }
}
