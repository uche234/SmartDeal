//
//  DealItem.swift
//  Dilblitz
//
//  Created by ОК on 20.04.2021.
//

import Foundation
import FirebaseFirestore

struct DealItemKey {
    static let userId = "userId"
    static let businessName = "businessName"
    static let imageUrl = "imageUrl"
    static let imageAspect = "imageAspect"
    static let description = "description"
    static let price = "price"
    static let discount = "discount"
    static let isOnlineStore = "isOnlineStore"
    static let promotion = "promotion"
    static let expirationDate = "expirationDate"
    static let geo = "geo"
    static let categories = "categories"
    static let address = "address"
    static let rating = "rating"
    static let purchased = "purchased"
    static let creationDate = "creationDate"
    static let dealId = "dealId"
    static let quantity = "quantity"
    static let approved = "approved"
    static let redeemed = "redeemed"
}

struct DealItem {
    let documentId: String
    let userId: String
    let businessName: String?
    let imageUrl: URL?
    let imageAspect: Double?
    let location: DBLocation?
    let about: String
    let price: Double
    let quantity: Int?
    let discount: Double
    let creationDate: Date?
    let expirationDate: Date?
    let isOnlineStore: Bool
    let promotion: String
    var rate: Double = 0
    let photoUrls: [URL] = []
    let categories: [String]
    let address: String
    let purchasedCount: Int
    let approved: Bool
    let redeemed: Bool
    
    var isExpired: Bool {
        if let expDate = expirationDate {
            return expDate < Date()
        }
        
        return false
    }
    
    var newPrice: Double {
        return DealItem.newPrice(for: price, discount: discount)
    }
    
    static func newPrice(for price: Double, discount: Double) -> Double {
        let result = price - price * discount / 100
        return result.maxTwoFructionDigitsRounded
    }
    
    init?(_ document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        guard let userId = data[DealItemKey.userId] as? String else { return nil }
         
        self.documentId = document.documentID
        self.userId = userId
        self.businessName = data[DealItemKey.businessName] as? String
        let strUrl = data[DealItemKey.imageUrl] as? String ?? ""
        self.imageUrl = URL(string: strUrl)
        self.imageAspect = data[DealItemKey.imageAspect] as? Double
        let geo = data[DealItemKey.geo] as? GeoPoint
        self.location = (geo == nil) ? nil : DBLocation(latitude: geo!.latitude, longitude: geo!.longitude)
        self.about = data[DealItemKey.description] as? String ?? ""
        self.price = data[DealItemKey.price] as? Double ?? 0.0
        self.quantity = data[DealItemKey.quantity] as? Int
        self.discount = data[DealItemKey.discount] as? Double ?? 0.0
        self.creationDate = (data[DealItemKey.creationDate] as? Timestamp)?.dateValue()
        let expDateTS = data[DealItemKey.expirationDate] as? Timestamp
        self.expirationDate = expDateTS?.dateValue()
        self.isOnlineStore = data[DealItemKey.isOnlineStore] as? Bool ?? false
        self.promotion = data[DealItemKey.promotion] as? String ?? ""
        self.categories = data[DealItemKey.categories] as? [String] ?? []
        self.address = data[DealItemKey.address] as? String ?? ""
        self.rate = data[DealItemKey.rating] as? Double ?? 0.0
        self.purchasedCount = data[DealItemKey.purchased] as? Int ?? 0
        self.approved = data[DealItemKey.approved] as? Bool ?? true
        self.redeemed = data[DealItemKey.redeemed] as? Bool ?? false
    }
}
