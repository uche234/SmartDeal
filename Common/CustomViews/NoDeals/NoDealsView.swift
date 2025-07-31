//
//  CustomSegmentedControl.swift
//  Dilblitz
//
//  Created by ОК on 14.04.2021.
//

import UIKit

class NoDealsView: UIView {
    
    @IBOutlet weak var contentView: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("NoDealsView", owner: self, options: nil)
        insertSubview(contentView, at: 0)
        contentView.fixToView(self)
    }
}

