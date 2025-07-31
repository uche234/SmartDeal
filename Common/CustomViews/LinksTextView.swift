//
//  LinksTextView.swift
//  Dilblitz
//
//  Created by OK on 25.01.2025.
//

import UIKit

class LinksTextView: UITextView, UITextViewDelegate {
    
    private var termsHandler: (() -> Void)?
    private var privacyHandler: (() -> Void)?
    
//    init(fullText: String, termsText: String, privacyText: String, termsHandler: @escaping () -> Void, privacyHandler: @escaping () -> Void) {
//        self.termsHandler = termsHandler
//        self.privacyHandler = privacyHandler
//        super.init(frame: .zero, textContainer: nil)
//        configureTextView(fullText: fullText, termsText: termsText, privacyText: privacyText)
//    }
    
    private let blueTextColor = UIColor(named: "mainBlue")!
    private let grayTextColor = UIColor(named: "darkGrayText")!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(fullText: String, termsText: String, privacyText: String, termsHandler: @escaping () -> Void, privacyHandler: @escaping () -> Void) {
        self.termsHandler = termsHandler
        self.privacyHandler = privacyHandler
        isEditable = false
        isScrollEnabled = false
        backgroundColor = .clear
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        delegate = self
        
        let termsRange = (fullText as NSString).range(of: termsText)
        let privacyRange = (fullText as NSString).range(of: privacyText)
        let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 5
                
                let attributedString = NSMutableAttributedString(string: fullText)
                attributedString.addAttribute(.foregroundColor, value: grayTextColor, range: NSRange(location: 0, length: fullText.count))
                attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: fullText.count))
                attributedString.addAttribute(.foregroundColor, value: blueTextColor, range: termsRange)
                attributedString.addAttribute(.foregroundColor, value: blueTextColor, range: privacyRange)
//                attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: termsRange)
//                attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: privacyRange)
                attributedString.addAttribute(.link, value: "terms://link", range: termsRange)
                attributedString.addAttribute(.link, value: "privacy://link", range: privacyRange)
                
                attributedText = attributedString
                linkTextAttributes = [:]
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.absoluteString == "terms://link" {
            termsHandler?()
        } else if URL.absoluteString == "privacy://link" {
            privacyHandler?()
        }
        return false
    }
}
