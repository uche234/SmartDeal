//
//  RateView.swift
//  Dilblitz
//
//  Created by ОК on 21.04.2021.
//

import UIKit

class RateView: UIView {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressViewWidth: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var unselectedStackView: UIStackView!
    @IBOutlet weak var containerHeight: NSLayoutConstraint!
    
    var onTouchAction: (()->Void)?
    
    var height: CGFloat = 10 {
        didSet {
            containerHeight.constant = height
        }
    }
    
    var progressMaxWidth: CGFloat {
        return unselectedStackView.bounds.width
    }
    let maxRate: CGFloat = 5
    var rate: Float = 0 {
        didSet {
            progressViewWidth.constant = progressMaxWidth * CGFloat(rate) / maxRate
            let rounded = Float(round(10*rate)/10)
            titleLabel.text = String(format: "%.1f", rounded)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("RateView", owner: self, options: nil)
        insertSubview(contentView, at: 0)
        contentView.fixToView(self)
    }
    
    @IBAction func touchButtonPressed(_ sender: Any) {
        onTouchAction?()
    }
    
}
