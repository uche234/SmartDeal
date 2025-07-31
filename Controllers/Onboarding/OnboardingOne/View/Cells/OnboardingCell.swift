//
//  OnboardingCell.swift
//  Lend
//
//  Created by ОК on 06.01.2021.
//

import UIKit

class OnboardingCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var imageTop: NSLayoutConstraint!
    @IBOutlet weak var imageLeading: NSLayoutConstraint!
    @IBOutlet weak var imageTrailing: NSLayoutConstraint!
    @IBOutlet weak var imageBottom: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func configureWith(data: OnboardingModel) {
        imageView.image = data.image
        titleLabel.text = data.title
        
//        imageTop.constant = data.imageInsets.top
//        imageBottom.constant = data.imageInsets.bottom
        imageLeading.constant = data.imageInsets.left
        imageTrailing.constant = data.imageInsets.right
    }
}
