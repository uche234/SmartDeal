//
//  CNotificationsViewController.swift
//  Dilblitz
//
//  Created by ОК on 20.07.2021.
//

import UIKit

class CNotificationsViewController: UIViewController {
    
    @IBOutlet weak var getNotifiredSwitch: UISwitch!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var clearAllButton: UIButton!
    
    var tableData: [NotificationItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard UserManager.shared.profile != nil else {
            Coordinator.redirectToAuth()
            return
        }
        
        let offColor = UIColor(named: "searchBg")
        getNotifiredSwitch.layer.cornerRadius = 0.5 * getNotifiredSwitch.bounds.height
        getNotifiredSwitch.tintColor = offColor
        getNotifiredSwitch.backgroundColor = offColor
        setupTableView()
        setClearAllButtonHidden(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getNotifiredSwitch.isOn = MessagingManager.shared.isSubscribed
        NotificationCenter.default.addObserver(self, selector: #selector(pushNotificationsIsSubscribedChanged), name: .pushNotificationsIsSubscribedChanged, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super .viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .pushNotificationsIsSubscribedChanged, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadData()
    }
    
    private func setupTableView() {
        tableView.contentInset = UIEdgeInsets(top: 53, left: 0, bottom: 8, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "CNotificationCell", bundle: nil), forCellReuseIdentifier: "CNotificationCell")
    }
    
    func loadData() {
        if tableData.isEmpty {
            view.startActivityAnimating()
        }
        FirestoreManager.shared.fetchNotifications { [weak self] data in
            guard let self = self else { return }
            
            self.view.stopActivityAnimating()
            self.tableData = data ?? []
            self.tableView.reloadData()
            self.setAllRead()
            self.setClearAllButtonHidden(self.tableData.isEmpty)
        }
    }
    
    private func setClearAllButtonHidden(_ value: Bool) {
        clearAllButton.isHidden = value
        clearAllButton.isUserInteractionEnabled = !value
    }
    
    private func setAllRead() {
        navigationController?.tabBarItem?.badgeValue = nil
        
        let notReadItems = tableData.filter{ $0.read == false }
        FirestoreManager.shared.setNotificationsAsRead(notReadItems){ _ in }
    }
    
    private func showDealDeatails(_ deal: DealItem) {
        let vc = Coordinator.instantiateDealDetailsVC()
        vc.deal = deal
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func deleteNotification(sender: CNotificationCell) {
        guard let indexPath = tableView.indexPath(for: sender) else { return }
        
        let item = tableData[indexPath.row]
        view.startActivityAnimating()
        FirestoreManager.shared.deleteNotification(id: item.documentId) { [weak self] error in
            guard let self = self else { return }
            
            self.view.stopActivityAnimating()
            guard error == nil else {
                self.showAlert(message: error!)
                return
            }
            
            self.tableData.remove(at: indexPath.row)
            self.tableView.reloadData()
            if self.tableData.isEmpty {
                self.setClearAllButtonHidden(true)
            }
        }
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            MessagingManager.shared.subscribeForNotifications { success in
                if !success {
                    sender.isOn = false
                }
            }
        } else {
            MessagingManager.shared.unSubscribeForNotifications()
        }
    }
    
    @objc func pushNotificationsIsSubscribedChanged(_ notification: Notification) {
        getNotifiredSwitch.isOn = MessagingManager.shared.isSubscribed
    }
    
    @IBAction func clearAllButtonPressed(_ sender: UIButton) {
        let idsToDelete = tableData.map { $0.documentId }
        tableData = []
        tableView.reloadData()
        setClearAllButtonHidden(true)
        FirestoreManager.shared.deleteNotifications(ids: idsToDelete) { _ in }
    }
}

extension CNotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CNotificationCell", for: indexPath) as! CNotificationCell
        cell.configureWith(data: tableData[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.startActivityAnimating()
        tableView.deselectRow(at: indexPath, animated: true)
        guard let dealId = tableData[indexPath.row].dealId else { return }
        
        FirestoreManager.shared.fetchDeal(id: dealId) { [weak self] deal, error in
            self?.view.stopActivityAnimating()
            if let deal = deal {
                self?.showDealDeatails(deal)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { (action, view, handler) in
            if let cell = self.tableView.cellForRow(at: indexPath) as? CNotificationCell {
                self.deleteNotification(sender: cell)
            }
        }
        deleteAction.backgroundColor = .white
        deleteAction.image = UIImage(named: "delete round_t")?.updateSizeAndImageOrientionUpSide(maxSize: 44, scale: UIScreen.main.scale)
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
}

