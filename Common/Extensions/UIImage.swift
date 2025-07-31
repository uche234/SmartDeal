//
//  UIImage.swift
//  Dilblitz
//
//  Created by ОК on 02.05.2021.
//

import UIKit

extension UIImage {
    func imageWithColor(color1: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color1.setFill()

        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)

        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    func updateSizeAndImageOrientionUpSide(maxSize: CGFloat? = nil, scale: CGFloat = 1) -> UIImage? {
        var newSize = self.size
        let originalMaxSize = max(newSize.width, newSize.height)
        if let maxSize = maxSize, originalMaxSize > maxSize {
            let scale = maxSize / originalMaxSize
            newSize.width = newSize.width * scale
            newSize.height = newSize.height * scale
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        if let normalizedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return normalizedImage
        }
        UIGraphicsEndImageContext()
        return nil
    }
}
