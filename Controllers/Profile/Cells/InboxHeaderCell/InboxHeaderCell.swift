//
//  InboxHeaderCell.swift
//  Dilblitz
//
//  Created by ОК on 20.07.2021.
//

import UIKit

class InboxHeaderCell: UITableViewCell {
    
    @IBOutlet weak var messagesCountLabel: UILabel!
    static let cellIdentifier = "InboxHeaderCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureWith(messagesCount: Int) {
        messagesCountLabel.text = messagesCount == 1 ? "1 NEW MESSAGE" : "\(messagesCount) NEW MESSAGES"
    }
    
}
