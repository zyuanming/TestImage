//
//  ViewController.swift
//  TestImage
//
//  Created by Zhang on 2019/10/9.
//  Copyright © 2019 Zhang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        

        let filePath = Bundle.main.path(forResource:"originalUIImage_1", ofType: "png")!
        let url = URL(fileURLWithPath: filePath)


        let originalUIImage = UIImage(contentsOfFile: filePath)!
        imageView = UIImageView(image: originalUIImage)
        imageView.backgroundColor = UIColor.blue
        imageView.frame = CGRect(x: 100, y: 200, width: 300, height: 400)
        view.addSubview(imageView)
        
        let originalCIImage = CIImage(contentsOf: url)!
//        self.imageView.image = UIImage(ciImage:originalCIImage)
        let imageWidth = originalUIImage.size.width
        let imageHeight = originalUIImage.size.height
        let aspectRatio = Double(originalUIImage.size.width) / Double(originalUIImage.size.height)
        let scaledCIImage = scaleFilter(originalCIImage, aspectRatio:1, scale:0.2)
        let scaledImage = UIImage(ciImage: scaledCIImage)
        self.imageView.image = scaledImage

        
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.contentMode = .scaleAspectFit
//        imageView.widthAnchor.constraint(equalToConstant: 300).isActive = true
//        imageView.heightAnchor.constraint(equalToConstant: 400).isActive = true
//
//        view.addSubview(imageView)
//        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//
//
//        addRunLoopObserver()
        
        
//        let imageSource = CGImageSourceCreateWithURL(url, nil)!
//        let options: [NSString:Any] = [kCGImageSourceThumbnailMaxPixelSize:400,
//                                       kCGImageSourceCreateThumbnailFromImageAlways:true]
//
//        if let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) {
//            let imageView = UIImageView(image: UIImage(cgImage: scaledImage))
//
//            imageView.translatesAutoresizingMaskIntoConstraints = false
//            imageView.contentMode = .scaleAspectFit
//            imageView.widthAnchor.constraint(equalToConstant: 300).isActive = true
//            imageView.heightAnchor.constraint(equalToConstant: 400).isActive = true
//
//            view.addSubview(imageView)
//            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//        }
        
        
        
//
//        print(UIColor.red)
//        print(UIColor.green)
//        UIColor.swizzleDesription()
//        print("\nswizzled\n")
//        print(UIColor.red)
//        print(UIColor.red)
//        UIColor.swizzleDesription()
//        print("\nTrying to swizzle again\n")
//        print(UIColor.red)
//        print(UIColor.red)
//
//
//
//        ViewController.exchangeMethod()
//        let vc = ViewController()
//        vc.test1()
        
        
        
        
    }
    
    func scaleFilter(_ input:CIImage, aspectRatio : Double, scale : Double) -> CIImage {
        let scaleFilter = CIFilter(name:"CILanczosScaleTransform")!
        scaleFilter.setValue(input, forKey: kCIInputImageKey)
        scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
        scaleFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
        return scaleFilter.outputImage!
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    class func exchangeMethod() {
        let vc = ViewController()
        let aClass: AnyClass = object_getClass(vc)!
        
        let originalMethod = class_getInstanceMethod(aClass, #selector(test1))
        let swizzledMethod = class_getInstanceMethod(aClass, #selector(test2))
        
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    @objc dynamic func test1() {
        print("test1")
    }
    
    @objc dynamic func test2() {
        print("test2")
    }

    private func addRunLoopObserver() {
        do {
            let semaphore = DispatchSemaphore.init(value: 0)
            let block = { (ob: CFRunLoopObserver?, ac: CFRunLoopActivity) in
                semaphore.signal()
                return
            }
            let ob = try createRunloopObserver(block: block)

            CFRunLoopAddObserver(CFRunLoopGetCurrent(), ob, .defaultMode)
            
            DispatchQueue.global().async {
                while true {
                    
                    let result = semaphore.wait(timeout: DispatchTime.now() + .nanoseconds(13))
                    
                    if result == .timedOut {
                        // 监测到卡顿
                    }
                }
            }
        }
        catch RunLoopError.canNotCreate {
            print("runloop 观察者创建失败")
        }
        catch {}
    }
    
    
    private func createRunloopObserver(block: @escaping (CFRunLoopObserver?, CFRunLoopActivity) -> Void) throws -> CFRunLoopObserver {

        /*
         *
         allocator: 分配空间给新的对象。默认情况下使用NULL或者kCFAllocatorDefault。

         activities: 设置Runloop的运行阶段的标志，当运行到此阶段时，CFRunLoopObserver会被调用。

             public struct CFRunLoopActivity : OptionSet {
                 public init(rawValue: CFOptionFlags)
                 public static var entry             //进入工作
                 public static var beforeTimers      //即将处理Timers事件
                 public static var beforeSources     //即将处理Source事件
                 public static var beforeWaiting     //即将休眠
                 public static var afterWaiting      //被唤醒
                 public static var exit              //退出RunLoop
                 public static var allActivities     //监听所有事件
             }

         repeats: CFRunLoopObserver是否循环调用

         order: CFRunLoopObserver的优先级，正常情况下使用0。

         block: 这个block有两个参数：observer：正在运行的run loop observe。activity：runloop当前的运行阶段。返回值：新的CFRunLoopObserver对象。
         */
        let ob = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.allActivities.rawValue, true, 0, block)
        guard let observer = ob else {
            throw RunLoopError.canNotCreate
        }
        return observer
    }

}



enum RunLoopError: Error {
    case canNotCreate
}



public extension UIColor {
    @objc func colorDescription() -> String {
        return "Printing rainbow colours."
    }
    private static let swizzleDesriptionImplementation: Void = {
        let instance: UIColor = UIColor.red
        let aClass: AnyClass! = object_getClass(instance)
        let originalMethod = class_getInstanceMethod(aClass, #selector(description))
        let swizzledMethod = class_getInstanceMethod(aClass, #selector(colorDescription))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            // switch implementation..
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()
    
    static func swizzleDesription() {
        _ = self.swizzleDesriptionImplementation
    }
}


class Testobject: NSObject {
    
    class func exchangeMethod() {
        let vc = Testobject()
        let aClass: AnyClass = object_getClass(vc)!
        
        let originalMethod = class_getInstanceMethod(aClass, #selector(test1))
        let swizzledMethod = class_getInstanceMethod(aClass, #selector(test2))
        
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    @objc dynamic func test1() {
        print("test1")
    }
    
    @objc dynamic func test2() {
        print("test2")
    }
    
    
}
