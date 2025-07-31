//
//  UIStoryboard.swift
//  Dilblitz
//
//  Created by ОК on 20.05.2021.
//

import UIKit

extension UIStoryboard {
    static func instantiateViewController(name: String) -> UIViewController {
        let storyboard = UIStoryboard(name: name, bundle: nil)
        return storyboard.instantiateInitialViewController()!
    }
    
    enum Name {
        
    }
}

