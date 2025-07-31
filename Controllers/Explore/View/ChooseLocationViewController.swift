//
//  ChooseLocationViewController.swift
//  Dilblitz
//
//  Created by OK on 08.04.2025.
//

import UIKit

class ChooseLocationViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var addressInputView: AddressInputView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var detectLocationView: UIView!
    
    private let animationDuration: TimeInterval = 0.1
    private var isManuallySetLocation = LocationTrakingManager.shared.manualySetLocation != nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(locationDidChangedNotification), name: .locationDidChanged, object: nil)
    }
    
    private func setupUI() {
        saveButton.layer.cornerRadius = 0.5 * saveButton.bounds.height
        
        addressInputView.onlineStoreCheckbox.isHidden = true
        addressInputView.onlineStoreCheckbox.isUserInteractionEnabled = false
        addressInputView.textFieldTitle = "Location"
        addressInputView.textFieldPlaceholder = "Add your location"
        addressInputView.setState(.location(address: LocationTrakingManager.shared.lastLocation?.address ?? ""))
        addressInputView.delegate = self
        
        detectLocationView.layer.cornerRadius = 0.5 * detectLocationView.bounds.height
        detectLocationView.layer.borderWidth = 1
        detectLocationView.layer.borderColor = UIColor(named: "mainBlue")!.cgColor
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(detectLocationPressed))
        detectLocationView.addGestureRecognizer(tapGesture)
    }
    
    @objc func locationDidChangedNotification(notification: Notification) {
        scrollView.stopActivityAnimating()
        if let location = LocationTrakingManager.shared.lastLocation {
            addressInputView.setState(.location(address: location.address))
            dismiss(animated: true)
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        let address = addressInputView.textFiledText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else { return }
        
        scrollView.startActivityAnimating()
        LocationTrakingManager.shared.getLocationFromAddress(address) { [weak self] location in
            guard let self = self else { return }
            
            self.scrollView.stopActivityAnimating()
            if let location = location {
                let data = LocationWithAddress(location: location, address: address)
                LocationTrakingManager.shared.manualySetLocation = data
                LocationTrakingManager.shared.lastLocation = data
                self.dismiss(animated: true)
            }
        }
    }
    
    @objc func detectLocationPressed() {
        LocationTrakingManager.shared.manualySetLocation = nil
        scrollView.startActivityAnimating()
        LocationTrakingManager.shared.startTrakingLocation()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .locationDidChanged, object: nil)
    }
}

extension ChooseLocationViewController: AddressInputViewDelegate {
    func addressInputViewDidUpdateHeight(_ sender: AddressInputView) {
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addressInputView(_ sender: AddressInputView, didChangeEditing isEditing: Bool) {
        if isEditing {
            let y = sender.frame.minY + bgView.frame.minY
            scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: false)
        }
    }
    
    func addressInputView(_ sender: AddressInputView, didChangeIsOnlineStore isOnlineStore: Bool) {
    }
}
