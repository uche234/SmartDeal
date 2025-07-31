//
//  RateDealViewController.swift
//  Dilblitz
//
//  Created by OK on 18.01.2022.
//

import UIKit

class RateDealViewController: UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputRateView: InputRateView!
    
    var deal: DealItem!
    var onSendAction: ((String?)->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        contentView.layer.cornerRadius = 10
        sendButton.layer.cornerRadius = 0.5 * sendButton.bounds.height
        titleLabel.text = ""
        loadData()
    }
    
    func loadData() {
        contentView.startActivityAnimating()
        FirestoreManager.shared.fetchDealRating(dealId: deal.documentId) { [weak self] rating in
            guard let self = self else { return }
            
            self.contentView.stopActivityAnimating()
            self.inputRateView.rate = rating ?? 0
            if rating == nil {
                self.titleLabel.text = "Rate the deal"
            } else {
                self.titleLabel.text = "Do you want to change your rating?"
            }
        }
    }
    
    @IBAction func sendButtonPressed(_ sender: Any) {
        contentView.startActivityAnimating()
        FirestoreManager.shared.updateDealRating(inputRateView.rate, dealId: deal.documentId) { [weak self] error in
            guard let self = self else { return }
            
            self.contentView.stopActivityAnimating()
            
            self.onSendAction?(error)
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func touchOutButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
