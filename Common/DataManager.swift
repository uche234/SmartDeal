//
//  DataManager.swift
//  Dilblitz
//
//  Created by ОК on 06.05.2021.
//

import Foundation
//import CoreLocation

class DataManager: NSObject {
    static let shared: DataManager = DataManager()
    
    private let key_dealCategories = "key_dealCategories"
    
    var categories: [DealCategory] = []
    
    func loadCategories(useCache: Bool, completion: @escaping (String?)->Void) {
        if useCache, !categories.isEmpty {
            return completion(nil)
        }
        
        FirestoreManager.shared.fetchCategories { data in
            guard let result = data, !result.isEmpty else { return completion(Constants.Error.unexpectedError) }
            
            self.categories = result
            completion(nil)
        }
    }
}
