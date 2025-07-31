//
//  Profile.swift
//  Dilblitz
//
//  Created by ОК on 19.04.2021.
//

import Foundation
import FirebaseFirestore

struct ProfileKey {
    static let email = "email"
    static let firstname = "firstname"
    static let surname = "surname"
    static let avatar = "avatar"
    static let category = "category"
    static let businessName = "businessName"
    static let birthDate = "birthDate"
    static let creationDate = "creationDate"
    static let lastLoginDate = "lastLoginDate"
    static let gender = "gender"
    static let businessAddress = "businessAddress"
    static let businessLocation = "businessLocation"
    static let isOnlineStore = "isOnlineStore"
    static let userId = "userId"
    static let lastLocation = "lastLocation"
    static let preferences = "preferences"
    static let interests = "interests"
    static let preferredBusinessTypes = "preferredBusinessTypes"
}

enum ProfileType: Codable {
    case guest, customer, business
    
    var name: String? {
        switch self {
        case .customer:
            return COLLECTION_CUSTOMERS
        case .business:
            return COLLECTION_BUSINESS
        default:
            return nil
        }
    }
    
    var alter: ProfileType {
        switch self {
        case .customer:
            return .business
        case .business:
            return .customer
        case .guest:
            return .guest
        }
    }
}

struct Preferences: Codable {
    var interests: [String] = []
    var preferredBusinessTypes: [String] = []
}

struct Profile: Codable {
    let uid: String
    let email: String
    var firstname: String = ""
    var surname: String = ""
    var type: ProfileType
    var avatarUrl: URL?
    var preferences: Preferences = Preferences()


    //for Business Owner
    var category: String = ""
    var businessName: String = ""
    var birthDate: Date?
    var gender: Gender?
    var businessAddress: String = ""
    var businessLocation: DBLocation? = nil
    var isOnlineStore: Bool = false
    var creationDate: Date
    
    var isBusinessOwner: Bool {
        return type == .business
    }
    
    var displayName: String {
        return "\(firstname) \(surname)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    init?(type: ProfileType, document: DocumentSnapshot?) {
        guard
            let document = document,
            let data = document.data(),
            let email = data[ProfileKey.email] as? String,
            let creationDate = data[ProfileKey.creationDate] as? Timestamp
        else { return nil }
        
        self.uid = document.documentID
        self.email = email
        self.firstname = data[ProfileKey.firstname] as? String ?? ""
        self.surname = data[ProfileKey.surname] as? String ?? ""
        self.type = type
        if let ts = data[ProfileKey.birthDate] as? Timestamp {
            self.birthDate = ts.dateValue()
        } else {
            self.birthDate = nil
        }
        
        self.gender = Gender(rawValue: data[ProfileKey.gender] as? String ?? "")
        self.avatarUrl = URL(string: data[ProfileKey.avatar] as? String ?? "")
        self.creationDate = creationDate.dateValue()

        if let prefData = data[ProfileKey.preferences] as? [String: Any] {
            self.preferences.interests = prefData[ProfileKey.interests] as? [String] ?? []
            self.preferences.preferredBusinessTypes = prefData[ProfileKey.preferredBusinessTypes] as? [String] ?? []
        }

        //For Business Owener
        self.category = data[ProfileKey.category] as? String ?? ""
        self.category = data[ProfileKey.category] as? String ?? ""
        self.businessName = data[ProfileKey.businessName] as? String ?? ""
        self.businessAddress = data[ProfileKey.businessAddress] as? String ?? ""
        if let geo = data[ProfileKey.businessLocation] as? GeoPoint {
            self.businessLocation = DBLocation(latitude: geo.latitude, longitude: geo.longitude)
        }
        
        self.isOnlineStore = data[ProfileKey.isOnlineStore] as? Bool ?? false
    }
    
    init(type: ProfileType, uid: String, email: String, firstname: String, surname: String) {
        self.uid = uid
        self.email = email
        self.firstname = firstname
        self.surname = surname
        self.type = type
        self.avatarUrl = nil
        self.creationDate = Date()
    }
    
    static func zeroCustomer() -> Profile {
        return Profile(type: .customer, uid: "", email: "", firstname: "", surname: "")
    }
    
    static func zeroBusinessOwner() -> Profile {
        return Profile(type: .business, uid: "", email: "", firstname: "", surname: "")
    }
    
    static func guestProfile(id: String) -> Profile {
        return Profile(type: .guest, uid: id, email: "", firstname: "Guest", surname: "")
    }
}
