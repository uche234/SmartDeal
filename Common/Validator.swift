//
//  Validator.swift
//  Dilblitz
//
//  Created by ОК on 19.04.2021.
//

import Foundation

class Validator {
    
    static func isEmailValid(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    static func isPasswordValid(_ password: String) -> Bool {
        return password.trimmingCharacters(in: .whitespacesAndNewlines).count >= 6
    }
}
