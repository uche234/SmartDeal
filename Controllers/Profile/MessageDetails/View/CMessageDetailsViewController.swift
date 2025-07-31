//
//  CMessageDetailsViewController.swift
//  Dilblitz
//
//  Created by ОК on 19.12.2021.
//

import UIKit

class CMessageDetailsViewController: UIViewController {
    
    @IBOutlet weak var profileView: ProfileView!
    @IBOutlet weak var bgView: RoundedViewWithShadow!
    
    @IBOutlet weak var messageLabel: UILabel!
    
    var inboxItem: InboxItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    func setupUI() {
        bgView.cornerRadius = 15
        bgView.shadowOffsetWidth = 0
        bgView.shadowRadius = 6
        bgView.shadowOpacity = 0.3
        messageLabel.text = inboxItem.details
        var profile = Profile.zeroBusinessOwner()//todo
        profile.firstname = inboxItem.title//TODO: //check ???
        profileView.configureWith(profile: profile)
        profileView.editImageButton.isHidden = true
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
