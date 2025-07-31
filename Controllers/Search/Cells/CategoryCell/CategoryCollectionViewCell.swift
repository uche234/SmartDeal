//
//  CategoryCollectionViewCell.swift
//  Dilblitz
//
//  Created by ОК on 02.05.2021.
//

import UIKit

class CategoryCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var roundBgView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        roundBgView.layer.cornerRadius = 15
    }
    
    func configureWith(data: DealCategory, isSelected: Bool) {
        roundBgView.backgroundColor = UIColor(named: isSelected ? "lightBlueText" : "searchBg")
        imageView.sd_setImage(with: data.imageUrl)
        titleLabel.text = data.name
    }

}
