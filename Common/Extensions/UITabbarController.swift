//
//  UITabbarController.swift
//  Dilblitz
//
//  Created by OK on 08.04.2025.
//

import UIKit

extension UITabBarController: @retroactive UIGestureRecognizerDelegate {
    func presentDeal(_ deal: DealItem) {
        let vc = Coordinator.instantiateDealDetailsVC()
        vc.deal = deal
        Coordinator.navigateTo(vc, from: self, modally: true, animated: true)
    }
}
