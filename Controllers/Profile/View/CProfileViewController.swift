//
//  CProfileViewController.swift
//  Dilblitz
//
//  Created by ОК on 20.07.2021.
//

import UIKit

class CProfileViewController: UIViewController {
    
    @IBOutlet weak var profileContainer: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var purchaseCountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var savedDealsButton: UIButton!
    @IBOutlet weak var watchListButton: UIButton!
    @IBOutlet weak var inboxListButton: UIButton!
    @IBOutlet weak var loginViewContainer: UIView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var tableViewTop: NSLayoutConstraint!
    
    let SAVED_DEALS = "SAVED DEALS"
    let WATCH_LIST = "WATCH LIST"
    let INBOX = "INBOX"
    var inboxItems: [InboxItem] = []
    
    var tableData: [Any] = []
    
    var profile: Profile {
        UserManager.shared.profile ?? Profile.zeroCustomer()
    }
    
    var savedDeals: [DealItem] = []
    var watchList: [DealItem] = []
    var purchasedDeals: [DealItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        profileContainer.layer.cornerRadius = 15
        avatarImageView.layer.cornerRadius = 0.5 * avatarImageView.bounds.height
        avatarImageView.layer.borderWidth = 1
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        setupTableData()
        setupTableView()
        inboxListButton.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
        loadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loginButton.layer.cornerRadius = 0.5 * loginButton.bounds.height
    }
    
    private func setupTableData() {
        var _tableData: [Any] = []
//        if !purchasedDeals.isEmpty { by reuest to remove purchased list
//            _tableData.append("MY PURCHASES")
//            _tableData += purchasedDeals
//        }
        if !savedDeals.isEmpty {
            savedDealsButton.isHidden = false
            _tableData.append(SAVED_DEALS)
            _tableData += savedDeals
        } else {
            savedDealsButton.isHidden = true
        }
//        if !watchList.isEmpty {
//            watchListButton.isHidden = false
//            _tableData += [WATCH_LIST]
//            _tableData += watchList
//        } else {
            watchListButton.isHidden = true
//        }
       
        //_tableData += [INBOX]
        //_tableData += inboxItems
                                 
        tableData = _tableData
        tableView.reloadData()
    }
    
    private func setupTableView() {
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: CSectionHeaderCell.cellIdentifier, bundle: nil), forCellReuseIdentifier: CSectionHeaderCell.cellIdentifier)
        tableView.register(UINib(nibName: CProfileDealCell.cellIdentifier, bundle: nil), forCellReuseIdentifier: CProfileDealCell.cellIdentifier)
        tableView.register(UINib(nibName: InboxHeaderCell.cellIdentifier, bundle: nil), forCellReuseIdentifier: InboxHeaderCell.cellIdentifier)
        tableView.register(UINib(nibName: InboxCell.cellIdentifier, bundle: nil), forCellReuseIdentifier: InboxCell.cellIdentifier)
    }
    
    func loadData() {
        UserManager.shared.updateBookmarks { [weak self] in
            FirestoreManager.shared.fetchDeals(ids: UserManager.shared.bookmarks) { [weak self] data in
                guard let self = self else { return }
                
                var _savedDeals: [DealItem] = []
//                var _watchList: [DealItem] = []
                
                for dataItem in data {
//                    if dataItem.isExpired {
                        _savedDeals.append(dataItem)
//                    } 
//                    else {
//                        _watchList.append(dataItem)
//                    }
                }
                
                self.savedDeals = self.sortDealsByCreationDate(_savedDeals)
//                self.watchList = self.sortDealsByCreationDate(_watchList)
                self.setupTableData()
            }
        }
        
        FirestoreManager.shared.fetchPurchasedDeals { [weak self] data in
            guard let self = self else { return }
            
            if let data = data {
                purchasedDeals = self.sortDealsByExpirationDate(data)
                setupTableData()
                purchaseCountLabel.text = purchasedDeals.isEmpty ? "" : "\(purchasedDeals.count) Deals Purchased"
            }
        }
    }
    
    func updateUI() {
        loginViewContainer.isHidden = profile.type != .guest 
        tableViewTop.constant = profile.type == .guest ? loginViewContainer.bounds.height : 0
        displayNameLabel.text = profile.displayName
        purchaseCountLabel.text = purchasedDeals.isEmpty ? "" : "\(purchasedDeals.count) Deals Purchased"
        avatarImageView.sd_setImage(with: profile.avatarUrl)
    }
    
    private func sortDealsByCreationDate(_ sourse: [DealItem]) -> [DealItem] {
        sourse.sorted(by: { ($0.creationDate ?? Date(timeIntervalSince1970: 0)) > ($1.creationDate ?? Date(timeIntervalSince1970: 0)) })
    }
    
    private func sortDealsByExpirationDate(_ sourse: [DealItem]) -> [DealItem] {
        sourse.sorted(by: { ($0.expirationDate ?? Date(timeIntervalSince1970: 0)) > ($1.expirationDate ?? Date(timeIntervalSince1970: 0)) })
    }

    @IBAction func editButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "CEditProfile", bundle: nil)
        let vc = storyboard.instantiateInitialViewController() as! CEditProfileViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func savedDealsButtonPressed(_ sender: Any) {
        guard let index = tableData.firstIndex(where: { ($0 as? String) == SAVED_DEALS }) else { return }
        
        tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
    }
    
    @IBAction func watchListButtonPressed(_ sender: Any) {
        guard let index = tableData.firstIndex(where: { ($0 as? String) == WATCH_LIST }) else { return }
        
        tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
    }
    
    @IBAction func inboxButtonPressed(_ sender: Any) {
        guard let index = tableData.firstIndex(where: { ($0 as? String) == INBOX }) else { return }
        
        tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
    }
    
    @IBAction func didTapLoginButton(_ sender: Any) {
        Coordinator.navigateToAuth(from: self, isBusinessOwner: false, modally: true)
    }
}

extension CProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let stringValue = tableData[indexPath.row] as? String {
            if stringValue == INBOX {
                let cell = tableView.dequeueReusableCell(withIdentifier: InboxHeaderCell.cellIdentifier, for: indexPath) as! InboxHeaderCell
                cell.configureWith(messagesCount: inboxItems.count)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: CSectionHeaderCell.cellIdentifier, for: indexPath) as! CSectionHeaderCell
                cell.configureWith(data: stringValue)
                return cell
            }
        }
        
        if let deal = tableData[indexPath.row] as? DealItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: CProfileDealCell.cellIdentifier, for: indexPath) as! CProfileDealCell
            cell.configureWith(data: deal)
            cell.onOptionsAction = { [weak self] in
                self?.showReportAndShareOptions(deal: deal)
            }
            return cell
        }
        
        if let inboxItem = tableData[indexPath.row] as? InboxItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: InboxCell.cellIdentifier, for: indexPath) as! InboxCell
            cell.configureWith(data: inboxItem)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let inboxItem = tableData[indexPath.row] as? InboxItem {
            let storyboard = UIStoryboard(name: "CMessageDetails", bundle: nil)
            let vc = storyboard.instantiateInitialViewController() as! CMessageDetailsViewController
            vc.inboxItem = inboxItem
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
