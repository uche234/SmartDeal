//
//  UIView.swift
//  Dilblitz
//
//  Created by ОК on 14.04.2021.
//

import UIKit

let activityViewTag = 475647
extension UIView {
    
    var isActivityAnimating: Bool {
        self.viewWithTag(activityViewTag) != nil
    }
    
    func startActivityAnimating() {
        guard self.viewWithTag(activityViewTag) == nil else { return }
        
        let activityColor = UIColor.darkGray
        let bgColor: UIColor = .clear
        let backgroundView = UIView()
        backgroundView.frame = CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.backgroundColor = bgColor
        backgroundView.tag = activityViewTag
        backgroundView.isUserInteractionEnabled = true
        
        var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
        activityIndicator = UIActivityIndicatorView(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
        activityIndicator.center = backgroundView.center
        activityIndicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .medium
        activityIndicator.color = activityColor
        activityIndicator.startAnimating()
        
        backgroundView.addSubview(activityIndicator)
        
        self.addSubview(backgroundView)
    }
    
    func stopActivityAnimating() {
        if let background = viewWithTag(activityViewTag){
            background.removeFromSuperview()
        }
    }
    
    func fixToView(_ container: UIView!) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let attributes: [NSLayoutConstraint.Attribute] = [.leading, .trailing, .top, .bottom]
        for attribute in attributes {
            NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: container, attribute: attribute, multiplier: 1.0, constant: 0).isActive = true
        }
    }
    
}
