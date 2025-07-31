//
//  Double.swift
//  Dilblitz
//
//  Created by OK on 27.01.2025.
//

import Foundation

extension Double {
    var maxTwoFructionDigitsRounded: Double {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 1
        formatter.numberStyle = .decimal
        
        if let formattedValue = formatter.string(from: NSNumber(value: self)) {
            return Double(formattedValue) ?? self
        }
        return self
    }
}
