//
//  CNotificationCell.swift
//  Dilblitz
//
//  Created by ОК on 20.07.2021.
//

import UIKit

class CNotificationCell: UITableViewCell {
    
    @IBOutlet weak var bgView: RoundedViewWithShadow!
    @IBOutlet weak var mailBgView: UIView!
    @IBOutlet weak var tagImageView: UIImageView!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        bgView.cornerRadius = 15
        bgView.shadowOffsetWidth = 0
        bgView.shadowRadius = 5
        bgView.shadowOpacity = 0.2
        mailBgView.layer.cornerRadius = 10
    }

    func configureWith(data: NotificationItem) {
        if let imageUrl = data.imageUrl {
            tagImageView.isHidden = true
            coverImageView.isHidden = false
            coverImageView.sd_setImage(with: imageUrl)
        } else {
            tagImageView.isHidden = false
            coverImageView.isHidden = true
        }
        
        nameLabel.text = data.name
        dateLabel.text = data.date.timeAgoSinceNow
        infoLabel.text = data.text
    }
    
}

