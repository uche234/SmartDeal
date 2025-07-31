//
//  UIViewController.swift
//  Dilblitz
//
//  Created by ОК on 19.04.2021.
//

import UIKit

extension UIViewController {
    
    func showAlert(message: String, title: String = "", options: [String]? = nil, completion: ((String?) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let uOptions = options ?? ["OK"]
        for option in uOptions {
            let action = UIAlertAction(title: option, style: .default) { action in
                completion?(action.title)
            }
            alert.addAction(action)
        }
        
        present(alert, animated: true)
    }
    
    func addActionSheetForiPad(actionSheet: UIAlertController) {
        if let popoverPresentationController = actionSheet.popoverPresentationController {
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverPresentationController.permittedArrowDirections = []
        }
    }
    
    func showReportAndShareOptions(deal: DealItem) {
        let alert = UIAlertController(title: "", message: "Please Select an Option", preferredStyle: .actionSheet)
            
        alert.addAction(UIAlertAction(title: "Report", style: .default , handler:{ [weak self] _ in
            let vc = Storyboard.Report(dealItem: deal).instantiate()
            self?.navigationController?.pushViewController(vc, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Share", style: .default, handler:{ _ in
            print("Share")//todo:
        }))
    
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ _ in }))

        //uncomment for iPad Support
        alert.popoverPresentationController?.sourceView = self.view

        self.present(alert, animated: true, completion: {})
    }
    
    func showRateDeal(_ deal: DealItem, onSendAction: ((String?)->Void)? = nil) {
        let vc = Storyboard.RateDeal(dealItem: deal).instantiate() as! RateDealViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.onSendAction = onSendAction
        present(vc, animated: true)
    }
    
    func open(url: URL, withErrorAlert alertModel: AlertModel? = nil) {
        guard UIApplication.shared.canOpenURL(url) else {
            if let model = alertModel {
                showAlert(message: model.message, title: model.title ?? "")
            }            
            return
        }
        
        UIApplication.shared.open(url)
    }
}
