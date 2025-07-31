//
//  Constants.swift
//  Dilblitz
//
//  Created by ОК on 19.04.2021.
//

import Foundation

struct Constants {
    
    static let defaultRegionRadiusMeters: Double = 16000
    
    struct Link {
        static let dilblitz = "https://www.dilblitz.com"
        static let terms = "https://dilblitz.com/tbc"
        static let privacy = "https://dilblitz.com/privacy-policy"
    }
    
    struct Email {
        static let support = "info@dilblitz.com"
    }
    
    struct Error {
        static let emailInputError = "Email is not valid"
        static let emailAlreadyInUse = "Email already in use"
        static let passwordInputError = "Password is too short. 6 chars minimum"
        static let wrongPassword = "Wrong Password"
        static let passwordIsNotTheSame = "Password is not the same"//todo: check text
        static let unexpectedError = "Unexpected error please try again"
        static let userNotFound = "User not found"
        static let networkError = "Network error"//todo: check text
        static let sendEmailError = "Can't send email. Check settings, please."//todo: check text
        static let emptyReportError = "Please, write the report"
    }
}
