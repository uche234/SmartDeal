//
//  CustomSegmentedControl.swift
//  Dilblitz
//
//  Created by ОК on 14.04.2021.
//

import UIKit

class CustomSegmentedControl: UIView {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var selectorView: UIView!
    @IBOutlet weak var selectorViewLeading: NSLayoutConstraint!
    
    
    var items: [String] = [] {
        didSet {
            setupStack()
            updateUI()
        }
    }
    
    private var buttons: [UIButton] = []
    var onIndexSelected: ((Int)->Void)?
    var selectedIndex: Int = 0
    private var didSetupConstraints = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("CustomSegmentedControl", owner: self, options: nil)
        insertSubview(contentView, at: 0)
        contentView.fixToView(self)
        
        updateUI()
    }
    
    private func setupStack() {
        
        guard !items.isEmpty else { return }
        
        for (index, item) in items.enumerated() {
            let button = UIButton(type: .custom)
            button.tag = index
            button.titleLabel?.font = UIFont(name:"Metropolis-Medium", size: 16)
            button.setTitle(item, for: .normal)
            button.addTarget(self, action: #selector(didTapItemButton), for: .touchUpInside)
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
    }
    
    override func updateConstraints() {
        updateSelectorConstraings()

        super.updateConstraints()
    }
    
    func updateSelectorConstraings() {
        guard !items.isEmpty else { return }
        
        let itemWidth = bounds.width / CGFloat(items.count)
        selectorViewLeading.constant = itemWidth * CGFloat(selectedIndex) + (itemWidth - selectorView.bounds.width) / 2.0
    }

    func updateUI() {
        for item in buttons {
            if item.tag == selectedIndex {
                item.setTitleColor(UIColor(named: "mainBlue"), for: .normal)
            } else {
                item.setTitleColor(UIColor(named: "grayText"), for: .normal)
            }
        }
        updateSelectorConstraings()
    }
    
    @objc func didTapItemButton(_ sender: UIButton) {
        selectedIndex = sender.tag
        updateUI()
        onIndexSelected?(selectedIndex)
    }
}

