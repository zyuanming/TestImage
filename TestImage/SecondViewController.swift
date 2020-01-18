//
//  SecondViewController.swift
//  TestImage
//
//  Created by Zhang on 2019/11/1.
//  Copyright © 2019 Zhang. All rights reserved.
//

import Foundation
import UIKit

class SecondViewController: UIViewController {
    
    var block: (() -> Void)?
    let name: String = "Yuanming"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        block = { [weak self] in
//            guard let strongSelf = self else { return }
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                print("name == \(strongSelf.name)")
//            }
//        }
        
        block = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                print("name == \(self.name)")
            }
        }
        
        
        block?()
    }
    
    
    deinit {
        print("deinit .....")
    }
}
