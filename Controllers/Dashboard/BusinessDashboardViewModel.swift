import Foundation
import Combine

class BusinessDashboardViewModel: ObservableObject {
    @Published var rules: [Rule] = []
    @Published var pendingDeals: [DealItem] = []
    @Published var approvals: [DealItem] = []

    func load() {
        FirestoreManager.shared.fetchRules { [weak self] in self?.rules = $0 ?? [] }
        FirestoreManager.shared.fetchPendingDeals { [weak self] in self?.pendingDeals = $0 ?? [] }
        FirestoreManager.shared.fetchApprovals { [weak self] in self?.approvals = $0 ?? [] }
    }

    func redeem(dealId: String) {
        FirestoreManager.shared.redeemApprovedDeal(id: dealId) { _ in }
    }
}
