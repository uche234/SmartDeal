//
//  DealCategory.swift
//  Dilblitz
//
//  Created by ОК on 02.05.2021.
//

import Foundation
import FirebaseFirestore

struct DealCategoryKey {
    static let imageUrl = "imageUrl"
    static let name = "name"
    static let index = "index"
}

struct DealCategory: Codable {
    let documentId: String
    let imageUrl: URL?
    let name: String
    let index: Int?
    
    init(_ document: QueryDocumentSnapshot) {
        let data = document.data()
        self.documentId = document.documentID
        self.imageUrl = URL(string: data[DealCategoryKey.imageUrl] as? String ?? "")
        self.name = data[DealCategoryKey.name] as? String ?? ""
        self.index = data[DealCategoryKey.index] as? Int
    }
}

enum Gender: String, CaseIterable, Codable {
    case male, female
    
    var name: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        }
    }
}
