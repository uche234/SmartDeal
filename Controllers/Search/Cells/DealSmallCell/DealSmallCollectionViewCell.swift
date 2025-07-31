//
//  DealSmallCollectionViewCell.swift
//  Dilblitz
//
//  Created by ОК on 06.05.2021.
//

import UIKit

class DealSmallCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var contentViewRounded: RoundedViewWithShadow!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var discountLabel: PaddingLabel!
    @IBOutlet weak var rateView: RateView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentViewRounded.cornerRadius = 15
        contentViewRounded.shadowOffsetWidth = 0
        contentViewRounded.shadowOpacity = 0.3
        imageView.layer.cornerRadius = 15
        discountLabel.layer.cornerRadius = 0.5 * discountLabel.frame.size.height
        discountLabel.backgroundColor = UIColor.white.withAlphaComponent(0.75)
    }
    
    func configureWith(data: DealItem) {
        imageView.sd_setImage(with: data.imageUrl)
        titleLabel.text = data.promotion
        descriptionLabel.text = data.about
        rateView.rate = Float(data.rate)
        if data.discount > 0 {
            discountLabel.isHidden = false
            discountLabel.text = "\(Int(data.discount))% off"
            discountLabel.layer.cornerRadius = 0.5 * discountLabel.frame.size.height
            discountLabel.clipsToBounds = true
        } else {
            discountLabel.isHidden = true
            discountLabel.text = ""
        }
    }
}
