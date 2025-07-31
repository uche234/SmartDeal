//
//  ViewController.swift
//  Dilblitz
//
//  Created by Oleksiy Kryvtsov on 06.04.2021.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.continueNavigation()
        }
    }
    
    func continueNavigation() {
        if !Settings.onboardingWasShown {
            Settings.onboardingWasShown = true
            Coordinator.navigateTo(storyboard: "OnboardingOne", from: self)
        } else {
            if let profile = UserManager.shared.profile {
                FirestoreManager.shared.checkAuth { isAuthorized in
                    if profile.type != .guest, let user = FirestoreManager.shared.currentUser, user.providerID == "Firebase", let email = user.email, !user.isEmailVerified {
                        self.navigateToCheckEmail(email: email, isBusinessOwner: profile.isBusinessOwner)
                        return
                    }
                    if isAuthorized {
                        if profile.type != .guest {
                            FirestoreManager.shared.updateLastLoginDate{ _ in }
                        }
                        if profile.isBusinessOwner {
                            Coordinator.navigateTo(BRootTabBarViewController(), from: self, modally: true)
                        } else {
                            Coordinator.navigateTo(CRootTabBarViewController(), from: self, modally: true)
                        }
                        UserManager.shared.fetchToUpdateProfile { _ in }
                    } else {
                        Coordinator.navigateTo(storyboard: "ChooseAccountTypeViewController", from: self, modally: true)
                    }
                }
            } else {
                FirestoreManager.shared.logOut()
                Coordinator.navigateTo(storyboard: "ChooseAccountTypeViewController", from: self, modally: true)
            }
        }
    }
    
    private func navigateToCheckEmail(email: String, isBusinessOwner: Bool) {
        print("ViewController :: navigateToCheckEmail: \(Thread.callStackSymbols)")
        let vc = Storyboard.CheckEmail.instantiate() as! CheckEmailViewController
        vc.email = email
        vc.isBusinessOwner = isBusinessOwner
        Coordinator.navigateTo(vc, from: self, modally: true)
    }
}

