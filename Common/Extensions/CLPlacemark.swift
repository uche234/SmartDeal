//
//  CLPlacemark.swift
//  Dilblitz
//
//  Created by ОК on 26.05.2021.
//

import Foundation
import CoreLocation

extension CLPlacemark {
    
    var compactAddress: String? {
            if let name = name {
                var result = name

                if let street = thoroughfare {
                    if !result.contains(street) {
                        result += ", \(street)"
                    }
                }

                if let city = locality {
                    result += ", \(city)"
                }

                return result
            }

            return nil
        }

}
