//
//  InputView.swift
//  Dilblitz
//
//  Created by ОК on 14.04.2021.
//

import UIKit

protocol InputViewDelegate: NSObjectProtocol {
    func inputView(_ sender: InputView, didChangeText text: String)
}

class InputView: UIView {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var placeholderLabel: UILabel!
    
    var placeholder: String = "" {
        didSet {
            updateUI()
        }
    }
    
    var textFieldText: String {
        set {
            textField.text = newValue
            updateUI()
        }
        get {
            return textField.text ?? ""
        }
    }
    
    var icon: UIImage? = nil {
        didSet {
            iconImageView.image = icon
        }
    }
    
    var isSecureTextEntry: Bool {
        set {
            textField.isSecureTextEntry = newValue
        }
        get {
            return textField.isSecureTextEntry
        }
    }
    
    weak var delegate: InputViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("InputView", owner: self, options: nil)
        insertSubview(contentView, at: 0)
        contentView.fixToView(self)
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(named: "graySeparator")?.cgColor
        layer.cornerRadius = 0.5 * bounds.height
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        updateUI()
    }
    
    func updateUI() {
        if (textField.text ?? "").isEmpty {
            placeholderLabel.isHidden = false
            placeholderLabel.text = placeholder
        } else {
            placeholderLabel.isHidden = true
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        delegate?.inputView(self, didChangeText: textField.text ?? "")
    }
}

extension InputView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        placeholderLabel.isHidden = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateUI()
    }
}
