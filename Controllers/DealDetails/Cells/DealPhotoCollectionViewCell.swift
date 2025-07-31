//
//  DealPhotoCollectionViewCell.swift
//  Dilblitz
//
//  Created by ОК on 02.05.2021.
//

import UIKit
import SDWebImage

class DealPhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        imageView.layer.cornerRadius = 12
    }
    
    func configureWith(imageUrl: URL) {
        imageView.sd_setImage(with: imageUrl)
    }

}
