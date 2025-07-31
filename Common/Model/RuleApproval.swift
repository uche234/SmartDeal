import Foundation
import FirebaseFirestore

struct RuleApprovalKey {
    static let triggerType = "triggerType"
    static let threshold = "threshold"
    static let approved = "approved"
}

struct RuleApproval {
    let documentId: String
    let triggerType: String
    let threshold: Double
    var approved: Bool

    init?(_ document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        self.documentId = document.documentID
        self.triggerType = data[RuleApprovalKey.triggerType] as? String ?? ""
        self.threshold = data[RuleApprovalKey.threshold] as? Double ?? 0
        self.approved = data[RuleApprovalKey.approved] as? Bool ?? false
    }

    var data: [String: Any] {
        [
            RuleApprovalKey.triggerType: triggerType,
            RuleApprovalKey.threshold: threshold,
            RuleApprovalKey.approved: approved
        ]
    }
}
