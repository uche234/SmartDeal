//
//  InputRateView.swift
//  Dilblitz
//
//  Created by OK on 18.01.2022.
//

import UIKit

class InputRateView: UIView {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet var starButtons: [UIButton]!
    
    var rate: Int = 0 {
        didSet {
            if rate <= 0 {
                selectedIndex = nil
            } else {
                selectedIndex = min(rate - 1, starButtons.count - 1)
            }
            updateUI()
        }
    }
    
    var onRateSelected: ((Int)->Void)?
    private var selectedIndex: Int?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("InputRateView", owner: self, options: nil)
        insertSubview(contentView, at: 0)
        contentView.fixToView(self)
        updateUI()
    }
    
    func updateUI() {
        if let selectedIndex = selectedIndex {
            for (index, item) in starButtons.enumerated() {
                let imageName = index <= selectedIndex ? "star_blue" : "star_gray"
                item.setImage(UIImage(named: imageName), for: .normal)
            }
        } else {
            starButtons.forEach {
                $0.setImage(UIImage(named: "star_gray"), for: .normal)
            }
        }
    }
    
    @IBAction func starButtonPressed(_ sender: UIButton) {
        guard let index = starButtons.firstIndex(of: sender) else { return }
        
        rate = index + 1
        updateUI()
        onRateSelected?(rate)
    }
}
