import SwiftUI

struct BusinessDashboardView: View {
    @StateObject private var viewModel = BusinessDashboardViewModel()
    @State private var showScanner = false
    @State private var scannerResult: String?

    var body: some View {
        NavigationView {
            List {
                if !viewModel.rules.isEmpty {
                    Section(header: Text("Rules")) {
                        ForEach(viewModel.rules, id: \.documentId) { rule in
                            Text("\(rule.triggerType): \(rule.threshold)")
                        }
                    }
                }
                if !viewModel.pendingDeals.isEmpty {
                    Section(header: Text("Pending Deals")) {
                        ForEach(viewModel.pendingDeals, id: \.documentId) { deal in
                            Text(deal.about)
                        }
                    }
                }
                if !viewModel.approvals.isEmpty {
                    Section(header: Text("Approvals")) {
                        ForEach(viewModel.approvals, id: \.documentId) { deal in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(deal.about)
                                    if let qr = deal.documentId.qrCodeImage() {
                                        Image(uiImage: qr)
                                            .resizable()
                                            .frame(width: 80, height: 80)
                                    }
                                }
                            }
                        }
                    }
                }

                if !viewModel.ruleApprovals.isEmpty {
                    Section(header: Text("Rule Approvals")) {
                        ForEach(viewModel.ruleApprovals, id: \.documentId) { rule in
                            HStack {
                                Text("\(rule.triggerType): \(rule.threshold)")
                                Spacer()
                                Button("Approve") {
                                    viewModel.approve(rule: rule)
                                }
                                Button("Reject") {
                                    viewModel.reject(rule: rule)
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Dashboard")
            .toolbar {
                Button("Scan") {
                    showScanner = true
                }
            }
            .onAppear {
                viewModel.load()
            }
            .sheet(isPresented: $showScanner) {
                QRScannerView { code in
                    scannerResult = code
                    viewModel.redeem(dealId: code)
                }
            }
        }
    }
}

struct BusinessDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        BusinessDashboardView()
    }
}
