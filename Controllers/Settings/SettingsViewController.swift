//
//  SettingsViewController.swift
//  Dilblitz
//
//  Created by OK on 07.03.2025.
//

import UIKit
import MessageUI

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    
    let tableData: [SettingsItem] = SettingsItem.allCases
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "SettingsCell", bundle: nil), forCellReuseIdentifier: SettingsCell.cellIdentifier)
    }
    
    private func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
               let mail = MFMailComposeViewController()
               mail.mailComposeDelegate = self
            mail.setToRecipients([Constants.Email.support])
               mail.setMessageBody("", isHTML: false)
               present(mail, animated: true)
           } else {
               showAlert(message: Constants.Error.sendEmailError)
           }
    }
    
    private func websiteOpen() {
        if let url = URL(string: Constants.Link.dilblitz) {
            open(url: url)
        }
    }

    private func openPreferences() {
        let vc = PreferencesViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func logout() {
        guard !loadingView.isAnimating else { return }
    
        MessagingManager.shared.updateManualyIsSubscribed(false) { _ in
            FirestoreManager.shared.logOut()
            Coordinator.redirectToAuth()
        }
    }
    
    private func deleteAccount() {
        guard !loadingView.isAnimating else { return }
    
        showAlert(message: "This action cannot be undone. Do you want to proceed?", options: ["Yes", "No"]) { action in
            if action == "Yes" {
                self.loadingView.startAnimating()
                MessagingManager.shared.updateManualyIsSubscribed(false) { _ in
                    FirestoreManager.shared.deleteAccount { error in
                        DispatchQueue.main.async { [weak self] in
                            self?.loadingView.stopAnimating()
                            if let error = error {
                                self?.showAlert(message: error, options: ["Ok"]) { action in
                                    self?.navigateToAuth()
                                }
                            } else {
                                self?.navigateToAuth()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func navigateToAuth() {
        Coordinator.redirectToAuth()
    }
}


extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsCell.cellIdentifier, for: indexPath) as! SettingsCell
        let item = tableData[indexPath.row]
        cell.nameLabel.text = item.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = tableData[indexPath.row]
        switch item {
        case .sendEmail:
            sendEmail()
        case .website:
            websiteOpen()
        case .preferences:
            openPreferences()
        case .logout:
            logout()
        case .deleteAccount:
            deleteAccount()
        }
    }
}


extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

enum SettingsItem: CaseIterable {
    case sendEmail, website, preferences, logout, deleteAccount
    
    var title: String {
        switch self {
        case .sendEmail:
            return "Send Email"
        case .website:
            return "Website"
        case .preferences:
            return "Preferences"
        case .logout:
            return "Logout"
        case .deleteAccount:
            return "Delete account"
        }
    }
}
