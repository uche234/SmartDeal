//
//  NotificationItem.swift
//  Dilblitz
//
//  Created by ОК on 20.07.2021.
//

import Foundation
import FirebaseFirestore

struct NotificationItemKey {
    static let userId = "userId"
    static let name = "name"
    static let text = "text"
    static let imageUrl = "image"
    static let date = "date"
    static let read = "read"
    static let dealId = "dealId"
}

struct NotificationItem {
    let documentId: String
    let imageUrl: URL?
    let name: String
    let text: String
    let date: Date
    let dealId: String?
    var read: Bool
    
    init?(_ document: DocumentSnapshot) {
        guard
            let data = document.data(),
            let timestamp = data[NotificationItemKey.date] as? Timestamp
        else { return nil }
        
        self.documentId = document.documentID
        self.name = data[NotificationItemKey.name] as? String ?? ""
        self.text = data[NotificationItemKey.text] as? String ?? ""
        self.imageUrl = URL(string: data[NotificationItemKey.imageUrl] as? String ?? "")
        self.date = timestamp.dateValue()
        self.dealId = data[NotificationItemKey.dealId] as? String
        self.read = data[NotificationItemKey.read] as? Bool ?? false
    }
}
