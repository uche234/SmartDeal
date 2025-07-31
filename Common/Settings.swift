//
//  Settings.swift
//  Dilblitz
//
//  Created by ОК on 14.04.2021.
//

import Foundation

fileprivate let key_customerEmail = "key_customerEmail"
fileprivate let key_businessEmail = "key_businessEmail"
fileprivate let key_onboardingWasShown = "key_onboardingWasShown"

class Settings {
    static var shouldOpenBusinessProfile: Bool = false
    
    static var onboardingWasShown: Bool {
        get {
            UserDefaults.standard.bool(forKey: key_onboardingWasShown)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: key_onboardingWasShown)
            UserDefaults.standard.synchronize()
        }
    }
    
    private static var customerEmail: String? {
        get {
            UserDefaults.standard.value(forKey: key_customerEmail) as? String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: key_customerEmail)
            UserDefaults.standard.synchronize()
        }
    }

    private static var businessEmail: String? {
        get {
            UserDefaults.standard.value(forKey: key_businessEmail) as? String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: key_businessEmail)
            UserDefaults.standard.synchronize()
        }
    }
    
    static func setEmail(_ email: String?, isBusinessOwner: Bool) {
        if isBusinessOwner {
            businessEmail = email
        } else {
            customerEmail = email
        }
    }
    
    static func getEmail(isBusinessOwner: Bool) -> String? {
        if isBusinessOwner {
            return businessEmail
        }
        
        return customerEmail
    }
}
