//
//  LocationWithAddress.swift
//  Dilblitz
//
//  Created by OK on 03.02.2022.
//

import Foundation

struct LocationWithAddress: Codable, Equatable {
    let location: DBLocation
    let address: String
}
