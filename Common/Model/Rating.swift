//
//  Rating.swift
//  Dilblitz
//
//  Created by OK on 18.01.2022.
//

import Foundation
import FirebaseFirestore

struct RatingKey {
    static let dealId = "dealId"
    static let customerId = "customerId"
    static let rating = "rating"
}

struct Rating {
    let value: Int
    
    init?(_ document: DocumentSnapshot) {
        guard
            let data = document.data(),
            let value = data[RatingKey.rating] as? Int
        else { return nil }
                
        self.value = value
    }
}
