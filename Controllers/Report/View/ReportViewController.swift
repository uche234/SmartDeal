//
//  ReportViewController.swift
//  Dilblitz
//
//  Created by OK on 18.01.2022.
//

import UIKit

class ReportViewController: UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    
    var deal: DealItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        sendButton.layer.cornerRadius = 0.5 * sendButton.bounds.height
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor(named: "graySeparator")!.cgColor
        textView.layer.cornerRadius = 10
        textView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sendButtonPressed(_ sender: Any) {
        guard
            let text = textView.text,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            showAlert(message: Constants.Error.emptyReportError)
            return
        }
        
        contentView.startActivityAnimating()
        FirestoreManager.shared.addReport(dealId: deal.documentId, text: text) { [weak self] error in
            guard let self = self else { return }
            
            self.contentView.stopActivityAnimating()
            if let error = error {
                self.showAlert(message: error)
            } else {
                //todo: //check text
                self.showAlert(message: "Report was sent") { _ in
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}

extension ReportViewController: UITextViewDelegate {
    
}
