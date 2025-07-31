//
//  CSectionHeaderCell.swift
//  Dilblitz
//
//  Created by ОК on 20.07.2021.
//

import UIKit

class CSectionHeaderCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    static let cellIdentifier = "CSectionHeaderCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureWith(data: String) {
        titleLabel.text = data
    }
}
