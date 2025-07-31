//
//  Coordinator.swift
//  Dilblitz
//
//  Created by Oleksiy Kryvtsov on 06.04.2021.
//

import Foundation
import UIKit

class Coordinator {
    
    static weak var rootTabbarController: UITabBarController?
    static var dealToShowOnStart: DealItem?
    
    private(set) static var appRootViewController: UIViewController? {
        get {
            return UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        }
        
        set {
            UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController = newValue
        }
    }
    
    static func redirectToAuth() {
        let storyboard = UIStoryboard(name: "ChooseAccountTypeViewController", bundle: nil)
        appRootViewController = storyboard.instantiateInitialViewController()!
    }
    
    static func navigateTo(storyboard name: String, from controller: UIViewController, modally: Bool = false, animated: Bool = true) {
        if let initialController = UIStoryboard(name: name, bundle: nil).instantiateInitialViewController() {
            navigateTo(initialController, from: controller, modally: modally, animated: animated)
        }
    }
    
    static func navigateTo(_ toController: UIViewController, from controller: UIViewController, modally: Bool = false, fullScreen: Bool = true, animated: Bool = true) {
        if let navigationController = toController.navigationController, !modally {
            push(toController, from: navigationController, animated: animated)
        } else {
            toController.modalTransitionStyle = .crossDissolve
            if fullScreen {
                toController.modalPresentationStyle = .overFullScreen
            }
            presentModally(toController, from: controller, animated: animated)
        }
    }
    
    static func navigateToAuth(from controller: UIViewController, isBusinessOwner: Bool, dismissCompletion: (() -> Void)? = nil, modally: Bool = false, animated: Bool = true) {
        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        let nc = storyboard.instantiateInitialViewController() as! UINavigationController
        let vc = nc.viewControllers.first as! AuthViewController
        vc.isBusinessOwner = isBusinessOwner
        vc.dismissCompletion = dismissCompletion
        Coordinator.navigateTo(nc, from: controller, modally: modally)
    }
    
    static func setRootViewController(_ vc: UIViewController) {
        appRootViewController = vc
    }
    
    private static func presentModally(_ controller: UIViewController, from root: UIViewController, animated: Bool) {
        root.present(controller, animated: animated)
    }
    
    private static func push(_ controller: UIViewController, from root: UINavigationController, animated: Bool) {
        root.pushViewController(controller, animated: animated)
    }
    
    static func instantiateDealDetailsVC() -> DealDetailsViewController {
        let storyboard = UIStoryboard(name: "DealDetails", bundle: nil)
        return storyboard.instantiateInitialViewController() as! DealDetailsViewController
    }
    
    static func instantiateChooseLocationVC() -> ChooseLocationViewController {
        let storyboard = UIStoryboard(name: "ChooseLocation", bundle: nil)
        return storyboard.instantiateInitialViewController() as! ChooseLocationViewController
    }
}
