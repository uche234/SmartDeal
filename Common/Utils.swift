//
//  Utils.swift
//  Dilblitz
//
//  Created by ОК on 14.04.2021.
//

import UIKit

struct Utils {
    static var window: UIWindow? {
        return UIApplication.shared.windows.first
    }
    
    static var safeAreaInsets: UIEdgeInsets {
        return window?.safeAreaInsets ?? .zero
    }
    
    static var topViewController: UIViewController? {
        guard let rootViewController = window?.rootViewController else { return nil }
        
        if let presentedVC = rootViewController.presentedViewController {
            return presentedVC
        }
        
        return rootViewController
    }
    
    static func minAgeDate(years: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = -years
        let maxDate = Calendar.current.date(byAdding: dateComponents, to: Date())
        return maxDate ?? Date()
    }
}

