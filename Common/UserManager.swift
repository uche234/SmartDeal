//
//  UserManager.swift
//  Dilblitz
//
//  Created by ОК on 19.04.2021.
//

import Foundation
import FirebaseAuth

class UserManager {
    private let key_profile = "key_profile"
    static let shared: UserManager = UserManager()
    
    var profile: Profile? {
        get {
            let savedProfileData = UserDefaults.standard.object(forKey: key_profile) as? Data ?? Data()
            return try? JSONDecoder().decode(Profile.self, from: savedProfileData)
        }
        set {
            let encoded = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.setValue(encoded, forKey: key_profile)
            UserDefaults.standard.synchronize()
        }
    }
    
    var bookmarks: [String] = []//deal id
    
    func resetUserData() {
        profile = nil
    }
    
    var currentLocation: DBLocation?
    var dealsForLocation: [DealItem] = []
    
    func fetchToUpdateProfile(completion: @escaping (String?)->Void) {
        guard let _profile = profile else { return completion(Constants.Error.unexpectedError) }

        FirestoreManager.shared.fetchProfile(type: _profile.type, uid: _profile.uid) { data in
            guard let result = data else { return completion(Constants.Error.unexpectedError) }

            self.profile = result
            completion(nil)
        }
    }
    
    func updateBookmarks(completion: @escaping ()->Void) {
        FirestoreManager.shared.fetchBookmarks { [weak self] data in
            if let data = data {
                self?.bookmarks = data
                completion()
            }
        }
    }
}
