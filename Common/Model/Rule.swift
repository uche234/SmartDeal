import Foundation
import FirebaseFirestore

struct RuleKey {
    static let triggerType = "triggerType"
    static let threshold = "threshold"
    static let enabled = "enabled"
}

struct Rule {
    let documentId: String
    let triggerType: String
    let threshold: Double
    var isEnabled: Bool

    init?( _ document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }

        self.documentId = document.documentID
        self.triggerType = data[RuleKey.triggerType] as? String ?? ""
        self.threshold = data[RuleKey.threshold] as? Double ?? 0
        self.isEnabled = data[RuleKey.enabled] as? Bool ?? false
    }

    var data: [String: Any] {
        [
            RuleKey.triggerType: triggerType,
            RuleKey.threshold: threshold,
            RuleKey.enabled: isEnabled
        ]
    }
}
