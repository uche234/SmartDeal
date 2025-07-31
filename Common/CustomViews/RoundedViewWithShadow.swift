//
//  RoundedViewWithShadow.swift
//  Dilblitz
//
//  Created by ОК on 14.04.2021.
//

import UIKit

class RoundedViewWithShadow: UIView, ShadowableRoundableView {

    var cornerRadius: CGFloat = 0 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    var shadowColor: UIColor = UIColor.gray {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    var shadowOffsetWidth: CGFloat = 3 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    var shadowOffsetHeight: CGFloat = 3 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    var shadowOpacity: Float = 0.2 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    var shadowRadius: CGFloat = 4 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    private(set) lazy var shadowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        self.layer.insertSublayer(layer, at: 0)
        self.setNeedsLayout()
        return layer
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setCornerRadiusAndShadow()
    }
}

protocol ShadowableRoundableView {
    
    var cornerRadius: CGFloat { get set }
    var shadowColor: UIColor { get set }
    var shadowOffsetWidth: CGFloat { get set }
    var shadowOffsetHeight: CGFloat { get set }
    var shadowOpacity: Float { get set }
    var shadowRadius: CGFloat { get set }
    
    var shadowLayer: CAShapeLayer { get }
    
    func setCornerRadiusAndShadow()
}

extension ShadowableRoundableView where Self: UIView {
    func setCornerRadiusAndShadow() {
        layer.cornerRadius = cornerRadius
        shadowLayer.path = UIBezierPath(roundedRect: bounds,
                                            cornerRadius: cornerRadius ).cgPath
        shadowLayer.fillColor = backgroundColor?.cgColor
        shadowLayer.shadowColor = shadowColor.cgColor
        shadowLayer.shadowPath = shadowLayer.path
        shadowLayer.shadowOffset = CGSize(width: shadowOffsetWidth ,
                                          height: shadowOffsetHeight )
        shadowLayer.shadowOpacity = shadowOpacity
        shadowLayer.shadowRadius = shadowRadius
    }
}
