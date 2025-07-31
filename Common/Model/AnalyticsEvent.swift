import Foundation
import FirebaseFirestore

struct AnalyticsEventKey {
    static let dealId = "dealId"
    static let userId = "userId"
    static let type = "type"
    static let date = "date"
}

enum AnalyticsEventType: String {
    case view
    case redeem
}

struct AnalyticsEvent {
    let documentId: String
    let dealId: String
    let userId: String
    let type: AnalyticsEventType
    let date: Date

    init?( _ document: DocumentSnapshot) {
        guard
            let data = document.data(),
            let dealId = data[AnalyticsEventKey.dealId] as? String,
            let userId = data[AnalyticsEventKey.userId] as? String,
            let typeStr = data[AnalyticsEventKey.type] as? String,
            let timestamp = data[AnalyticsEventKey.date] as? Timestamp,
            let eventType = AnalyticsEventType(rawValue: typeStr)
        else { return nil }

        self.documentId = document.documentID
        self.dealId = dealId
        self.userId = userId
        self.type = eventType
        self.date = timestamp.dateValue()
    }

    var data: [String: Any] {
        [
            AnalyticsEventKey.dealId: dealId,
            AnalyticsEventKey.userId: userId,
            AnalyticsEventKey.type: type.rawValue,
            AnalyticsEventKey.date: Timestamp(date: date)
        ]
    }
}
