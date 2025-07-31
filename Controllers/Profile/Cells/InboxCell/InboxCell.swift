//
//  InboxCell.swift
//  Dilblitz
//
//  Created by ОК on 20.07.2021.
//

import UIKit

class InboxCell: UITableViewCell {
    
    @IBOutlet weak var bgView: RoundedViewWithShadow!
    @IBOutlet weak var mailBgView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    static let cellIdentifier = "InboxCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        bgView.cornerRadius = 15
        bgView.shadowOffsetWidth = 0
        bgView.shadowRadius = 5
        bgView.shadowOpacity = 0.2
        mailBgView.layer.cornerRadius = 10
    }
    
    func configureWith(data: InboxItem) {
        titleLabel.text = data.title
        detailsLabel.text = data.details
    }
    
}
