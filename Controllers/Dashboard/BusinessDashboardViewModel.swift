import Foundation
import Combine

class BusinessDashboardViewModel: ObservableObject {
    @Published var rules: [Rule] = []
    @Published var pendingDeals: [DealItem] = []
    @Published var approvals: [DealItem] = []
    @Published var ruleApprovals: [RuleApproval] = []

    func load() {
        FirestoreManager.shared.fetchRules { [weak self] in self?.rules = $0 ?? [] }
        FirestoreManager.shared.fetchPendingDeals { [weak self] in self?.pendingDeals = $0 ?? [] }
        FirestoreManager.shared.fetchApprovals { [weak self] in self?.approvals = $0 ?? [] }
        FirestoreManager.shared.fetchRuleApprovals { [weak self] in self?.ruleApprovals = $0 ?? [] }
    }

    func redeem(dealId: String) {
        FirestoreManager.shared.redeemApprovedDeal(id: dealId) { _ in }
    }

    func approve(rule: RuleApproval) {
        FirestoreManager.shared.approveRule(rule) { [weak self] _ in
            self?.ruleApprovals.removeAll { $0.documentId == rule.documentId }
            FirestoreManager.shared.fetchRules { [weak self] in self?.rules = $0 ?? [] }
        }
    }

    func reject(rule: RuleApproval) {
        FirestoreManager.shared.rejectRule(rule) { [weak self] _ in
            self?.ruleApprovals.removeAll { $0.documentId == rule.documentId }
        }
    }
}
