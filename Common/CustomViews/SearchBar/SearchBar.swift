//
//  SearchBar.swift
//  Dilblitz
//
//  Created by ОК on 06.05.2021.
//

import UIKit

class SearchBar: UIView {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var searchPlaceholderLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var filtersButton: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("SearchBar", owner: self, options: nil)
        insertSubview(contentView, at: 0)
        contentView.fixToView(self)
        clipsToBounds = true
        layer.cornerRadius = 0.5 * bounds.height
        textField.delegate = self
        filtersButton.isHidden = true
        updateUI()
    }
    
    var onSearch: ((String)->Void)?
    var onStartEditing: (()->Void)?
    var onEndEditing: (()->Void)?
    
    var searchText: String {
        get {
            textField.text ?? ""
        }
        set {
            textField.text = newValue
            updateUI()
        }
    }
    
    private func updateUI() {
        if !textField.isFirstResponder, searchText.isEmpty {
            searchPlaceholderLabel.isHidden = false
        } else {
            searchPlaceholderLabel.isHidden = true
        }
    }
}

extension SearchBar: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let text: NSString = (textField.text ?? "") as NSString
        let resultString = text.replacingCharacters(in: range, with: string)
        onSearch?(resultString)
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateUI()
        onStartEditing?()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateUI()
        onEndEditing?()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
