//
//  ChooseAccountTypeViewController.swift
//  Dilblitz
//
//  Created by ОК on 14.04.2021.
//

import UIKit

class ChooseAccountTypeViewController: UIViewController {
    
    @IBOutlet weak var customerView: RoundedViewWithShadow!
    @IBOutlet weak var ownerView: RoundedViewWithShadow!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupRoundedView(customerView)
        setupRoundedView(ownerView)
    }
    
    private func setupRoundedView(_ rView: RoundedViewWithShadow) {
        rView.cornerRadius = 15
        rView.shadowOffsetWidth = 0
        rView.shadowOpacity = 0.2
    }
    
    @IBAction func customerButtonPressed(_ sender: Any) {
        Coordinator.navigateToAuth(from: self, isBusinessOwner: false, modally: true)
    }
    
    @IBAction func owerButtonPressed(_ sender: Any) {
        Coordinator.navigateToAuth(from: self, isBusinessOwner: true, modally: true)
    }
}
