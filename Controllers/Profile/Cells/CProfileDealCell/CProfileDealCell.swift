//
//  CProfileDealCell.swift
//  Dilblitz
//
//  Created by ОК on 20.07.2021.
//

import UIKit

class CProfileDealCell: UITableViewCell {
    
    @IBOutlet weak var bgView: RoundedViewWithShadow!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var promotionLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    @IBOutlet weak var info1Label: UILabel!
    @IBOutlet weak var info2Label: UILabel!
    
    static let cellIdentifier = "CProfileDealCell"
    var onOptionsAction: (()->Void)?
   
    override func awakeFromNib() {
        super.awakeFromNib()
        
        coverImageView.layer.cornerRadius = 15
        
        bgView.cornerRadius = 15
        bgView.shadowOffsetWidth = 0
        bgView.shadowRadius = 5
        bgView.shadowOpacity = 0.2
    }

    func configureWith(data: DealItem) {
        coverImageView.sd_setImage(with: data.imageUrl)
        promotionLabel.text = data.promotion
        aboutLabel.text = data.about

        if let expDate = data.expirationDate {
            if expDate < Date() {
                info1Label.text = "Expires"
                info2Label.text = expDate.ddmmyyyString
            } else {
                info1Label.text = "Valid until"
                info2Label.text = expDate.ddmmyyyString
            }
        } else {
            info1Label.text = ""
            info2Label.text = "Redeemed"//todo:
        }
    }
    
    @IBAction func optionsButtonPressed(_ sender: Any) {
        onOptionsAction?()
    }
    
}
