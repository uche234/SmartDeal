//
//  DealCollectionViewCell.swift
//  Dilblitz
//
//  Created by ОК on 02.05.2021.
//

import UIKit

class DealCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var discountLabel: PaddingLabel!
    @IBOutlet weak var rateView: RateView!
    @IBOutlet weak var contentViewRounded: RoundedViewWithShadow!
    @IBOutlet weak var imageContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var bookmarkButton: UIButton!
    
    var onBookmarkAction: (()->Void)?
    var onOptionsAction: (()->Void)?
    var onRateAction: (()->Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentViewRounded.cornerRadius = 15
        contentViewRounded.shadowOffsetWidth = 0
        contentViewRounded.shadowOpacity = 0.3
        imageView.layer.cornerRadius = 15
        discountLabel.layer.cornerRadius = 0.5 * discountLabel.frame.size.height
        discountLabel.backgroundColor = UIColor.white.withAlphaComponent(0.75)
        rateView.onTouchAction = { [weak self] in
            self?.onRateAction?()
        }
    }
    
    func configureWith(data: DealItem, cellWidth: CGFloat, isBookmarked: Bool) {
//        print("deal id: \(data.documentId), prom: \(data.promotion), descr: \(data.about), location: \(data.location != nil ? data.location!.description : "nil")")
        if let aspect = data.imageAspect, aspect > 0 {
            imageContainerHeight.constant = cellWidth / CGFloat(aspect)
        } else {
            imageContainerHeight.constant = cellWidth / 2
        }
        layoutIfNeeded()
        
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
        bookmarkButton.setImage(UIImage(named: isBookmarked ? "bookmark_filled" : "bookmark"), for: .normal)
    }
    
    static func cellHeightForItem(deal: DealItem, constrainedWidth: CGFloat) -> CGFloat {
        let labelsLeading: CGFloat = 10
        let titleLabelTop: CGFloat = 10
        let titleLabelBottom: CGFloat = 23
        let descriptionLabelBottom: CGFloat = 28
        
        let font = UIFont(name: "Metropolis-Medium", size: 11)!
        var imageHeight: CGFloat = 200
        if let aspect = deal.imageAspect, aspect > 0 {
            imageHeight = constrainedWidth / CGFloat(aspect)
        } else {
            imageHeight = constrainedWidth / 2
        }
        let titleHeight = deal.promotion.height(withConstrainedWidth: constrainedWidth - 2 * labelsLeading, font: font)
        let descriptionHeight = deal.about.height(withConstrainedWidth: constrainedWidth - 2 * labelsLeading, font: font)
        let result = imageHeight + titleLabelTop + titleHeight + titleLabelBottom + descriptionHeight + descriptionLabelBottom
        return result
    }
    
    @IBAction func bookmarkButtonPressed(_ sender: Any) {
        onBookmarkAction?()
    }
    
    @IBAction func optionsButtonPressed(_ sender: Any) {
        onOptionsAction?()
    }
    
}
