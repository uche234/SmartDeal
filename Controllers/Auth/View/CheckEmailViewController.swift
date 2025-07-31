//
//  CheckEmailViewController.swift
//  Dilblitz
//
//  Created by OK on 04.01.2025.
//

import UIKit

class CheckEmailViewController: UIViewController {

    @IBOutlet weak var useLinkLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var topBar: UIView!
    
    var email = ""
    var isBusinessOwner = false
    var isSendVerifyError = false
    private let errorText = "Unexpected error. Try again later"
    var isEmailVerified: Bool {
        return FirestoreManager.shared.currentUser?.isEmailVerified ?? false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let nc = navigationController {
            nc.interactivePopGestureRecognizer?.isEnabled = false
        }

        continueButton.layer.cornerRadius = 0.5 * continueButton.bounds.height
        useLinkLabel.text = "Use the link we sent to \(email)"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isEmailVerified {
            sendVerifyEmail()
        }
    }
    
    private func sendVerifyEmail() {
        FirestoreManager.shared.verifyEmail { [weak self] error in
            guard let self = self else { return }
            
            if error != nil {
                print("#### verifyEmail error = \(error!)")
                self.isSendVerifyError = true
                self.showAlert(message: errorText)
            } else {
                self.isSendVerifyError = false
            }
        }
    }
    
    private func navigateToAuthorizedRoot() {
        if isBusinessOwner {
            Coordinator.setRootViewController(BRootTabBarViewController())
        } else {
            Coordinator.setRootViewController(CRootTabBarViewController())
        }
    }
    
    private func checkEmail() {
        guard !isSendVerifyError else {
            sendVerifyEmail()
            showAlert(message: errorText)
            return
        }
        
        guard let user = FirestoreManager.shared.currentUser else {
            return
        }
        
        user.reload { [weak self] error in
            if let error = error {
                print("#### user.reload error = \(error)")
            }
            if user.isEmailVerified {
                self?.navigateToAuthorizedRoot()
            } else {
                //TODO: show alert
                print("#### isEmailVerified = FALSE")
            }
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        FirestoreManager.shared.logOut()
        if let nc = navigationController {
            nc.popViewController(animated: true)
        } else {
            Coordinator.redirectToAuth()
        }
    }
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        checkEmail()
    }
    
}
