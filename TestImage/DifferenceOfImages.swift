//
//  DifferenceOfImages.swift
//  TestImage
//
//  Created by Zhang on 2020/1/18.
//  Copyright © 2020 Zhang. All rights reserved.
//

import Foundation
import CoreImage

public class DifferenceOfImages: CIFilter
{
    var inputImage1 : CIImage?  //Initializes input
    var inputImage2 : CIImage?
    var kernel = CIKernel(source:  //The actual custom kernel code
        "kernel vec4 Difference(__sample image1,__sample image2)" +
            "       {                                               " +
            "           float colorR = image1.r - image2.r;         " +
            "           float colorG = image1.g - image2.g;         " +
            "           float colorB = image1.b - image2.b;         " +
            "           return vec4(colorR,colorG,colorB,1);        " +
        "       }                                               "
    )
    var extentFunction: (CGRect, CGRect) -> CGRect = { (a: CGRect, b: CGRect) in return CGRect.zero }


    override public var outputImage: CIImage!
    {
        guard let inputImage1 = inputImage1,
            let inputImage2 = inputImage2,
            let kernel = kernel
            else
        {
            return nil
        }

        //apply to whole image
        let extent = extentFunction(inputImage1.extent,inputImage2.extent)
        //arguments of the kernel
        let arguments = [inputImage1,inputImage2]
        //return the rectangle that defines the part of the image that CI needs to render rect in the output
        return kernel.apply(extent: extent,
                                      roiCallback:
            { (index, rect) in
                return rect

            },
                                      arguments: arguments)

    }

}
