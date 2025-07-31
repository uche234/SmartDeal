//
//  FirestoreManager.swift
//  Dilblitz
//
//  Created by ОК on 19.04.2021.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FBSDKLoginKit
import GoogleSignIn


let COLLECTION_CUSTOMERS = "Customers"
let COLLECTION_BUSINESS = "Business"
let COLLECTION_DEALS = "Deals"
let COLLECTION_CATEGORIES = "Categories"
let COLLECTION_SAVED = "Saved"
let COLLECTION_PURCHASES = "Purchases"
let COLLECTION_NOTIFICATIONS = "Notifications"
let COLLECTION_TOKENS = "Tokens"
let COLLECTION_REPORTS = "Reports"
let COLLECTION_RATINGS = "Ratings"
let COLLECTION_DELETION_QUEUE = "DeletionQueue"

class FirestoreManager {
    static let shared: FirestoreManager = FirestoreManager()
    
    let db = Firestore.firestore()
    
    var chunks = [[String]]()

    var isAuthorized: Bool {
        return currentUser != nil
    }
    
    var currentUser: User? {
        return Auth.auth().currentUser
    }
        
    weak var handle: AuthStateDidChangeListenerHandle?
        
    //MARK: - Auth
    
    func checkAuth(completion: @escaping (Bool)->Void) {
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            if let strongUser = user {
                print("Auth.auth().addStateDidChangeListener:  Status = athorized, displayName = \(strongUser.displayName ?? "nil")")
            } else {
                print("Auth.auth().addStateDidChangeListener:  Status = not athorized")
            }
            
            Auth.auth().removeStateDidChangeListener(self.handle!)
            completion(self.currentUser != nil)
        }
    }
    
    private func handleLogin(type: ProfileType, firUser: User, completion: @escaping (Bool, String?)->Void) {
        guard let collection = type.name else {
            return completion(false, Constants.Error.unexpectedError)
        }
        
        let alterCollection = type.alter.name!
        self.db.collection(alterCollection).document(firUser.uid).getDocument { snapshot, error in
            guard error == nil else {
                self.logOut()
                return completion(false, Constants.Error.unexpectedError)
            }
            
            if let user = Profile(type: type.alter, document: snapshot) {
                UserManager.shared.profile = user
                FirestoreManager.shared.updateLastLoginDate{ _ in }
                print("### alter LOGIN ==> uid: \(user.uid) email: \(user.email)  displayName: \(user.displayName)")
                completion(true, nil)
            } else {
                self.db.collection(collection).document(firUser.uid).getDocument { snapshot, error in
                    guard error == nil else {
                        self.logOut()
                        return completion(false, Constants.Error.unexpectedError)
                    }
                    
                    if let user = Profile(type: type, document: snapshot) {
                        UserManager.shared.profile = user
                        FirestoreManager.shared.updateLastLoginDate{ _ in }
                        print("### LOGIN ==> uid: \(user.uid) email: \(user.email)  displayName: \(user.displayName)")
                        completion(false, nil)
                    } else {
                        print("### LOGIN ==> user document \(firUser.uid) is not exist")
                        let firEmail = firUser.email ?? ""
                        let firDisplayName = firUser.displayName ?? ""
                        
                        let profile = Profile(type: type, uid: firUser.uid, email: firEmail, firstname: "", surname: "")
                        UserManager.shared.profile = profile
                        self.setProfile(profile) { _ in
                            completion(false, nil)
                        }
                    }
                }
            }
        }
    }
    
    func login(type: ProfileType, email: String, password: String, completion: @escaping (Bool, String?)->Void) {
        logOut()
        Auth.auth().signIn(withEmail: email, password: password, completion: { (result, error) in
            guard let user = result?.user else { return completion(false, self.authErrorDescription(error)) }
            
            self.handleLogin(type: type, firUser: user, completion: completion)
        })
    }
    
    // Facebook, Apple, ...
    func login(type: ProfileType, credential: AuthCredential, completion: @escaping (Bool, String?)->Void) {
        Auth.auth().signIn(with: credential) { (result, error) in
            guard let user = result?.user else { return completion(false, self.authErrorDescription(error)) }
            
            self.handleLogin(type: type, firUser: user, completion: completion)
        }
    }
    
    func signUpAnonimously(_ completion: @escaping (String?) -> Void) {
        Auth.auth().signInAnonymously { result, error in
            if error == nil {
                UserManager.shared.profile = Profile.guestProfile(id: result?.user.uid ?? "")
            }
             
            completion(error?.localizedDescription)
        }
    }
    
    func signUp(type: ProfileType, email: String, password: String, firstname: String, surname: String, birthDate: Date?, gender: Gender?, completion: @escaping (String?)->Void) {
        logOut()
        
        let addUserBlock: ((String)->Void) = { uid in
            var profile = Profile(type: type, uid: uid, email: email, firstname: firstname, surname: surname)
            profile.birthDate = birthDate
            profile.gender = gender
            UserManager.shared.profile = profile
            self.setProfile(profile) { _ in
                completion(nil)
            }
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            guard error == nil else {
                let errorDescription = self.authErrorDescription(error!)
                return completion(errorDescription)
            }
            
            guard let user = authResult?.user else {
                completion(nil)
                return
            }
            
            let displayName = "\(firstname) \(surname)".trimmingCharacters(in: .whitespacesAndNewlines)
            if !displayName.isEmpty {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = displayName
                changeRequest?.commitChanges { (error) in
                    addUserBlock(user.uid)
                }
            } else {
                addUserBlock(user.uid)
            }
        }
    }
    
    @discardableResult func logOut() -> Bool {
        facebookLogout()
        do {
            try Auth.auth().signOut()
            UserManager.shared.resetUserData()
            return true
        } catch {
            return false
        }
    }
    
    func verifyEmail(completion: @escaping (String?)-> Void) {
        guard let user = currentUser else {
            return completion("Internal error")
        }
        
        if user.isEmailVerified {
            return completion(nil)
        } else {
            user.sendEmailVerification { error in
                return completion(error?.localizedDescription)
            }
        }
    }
    
    func deleteAccount() {
        deleteAccount { _ in }
    }
    
    func deleteAccount(completion: @escaping (String?)-> Void) {
        guard let profile = UserManager.shared.profile else { return completion(nil) }
        print("❌ deleting \(profile.uid)")
        
        Auth.auth().currentUser?.delete { error in
            guard error == nil else {
                return completion(error?.localizedDescription)
            }
            
            if profile.type == .guest {
                UserManager.shared.resetUserData()
                completion(nil)
            } else {
                self.deleteAccountData(profile) {
                    completion(nil)
                }
            }
        }
    }
    
    private func deleteAccountData(_ profile: Profile, completion: @escaping ()->Void) {
        let data: [String: Any] = ["collection": profile.isBusinessOwner ? COLLECTION_BUSINESS : COLLECTION_CUSTOMERS,
                                   "documentId": profile.uid]
        
        db.collection(COLLECTION_DELETION_QUEUE).addDocument(data: data) { error in
            if let error = error {
                print("❌ Error adding document: \(error.localizedDescription), uid: \(profile.uid)")
                return completion()
            } else {
                print("❎ adding document successful")
            }
            UserManager.shared.resetUserData()
            completion()
        }
    }
    
    private func facebookLogout() {
        let loginManager = LoginManager()
        loginManager.logOut()
    }
    
    private func authErrorDescription(_ error: Error?) -> String {
        var result = Constants.Error.unexpectedError
        guard let error = error else { return result }
        
        if let errorCode = AuthErrorCode.Code(rawValue: error._code) {
            switch errorCode {
            case .emailAlreadyInUse:
                result = Constants.Error.emailAlreadyInUse
            case .userNotFound:
                result = Constants.Error.userNotFound
            case .wrongPassword:
                result = Constants.Error.wrongPassword
            default:
                result = Constants.Error.unexpectedError
            }
        }
        return result
    }
    
    func resetPassword(email: String, completion: @escaping (String?)->Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            completion(error?.localizedDescription)
        }
    }
    
    //MARK: - test functions
    
    //MARK: - USER
    
    func fetchProfile(type: ProfileType, uid: String, completion: @escaping (Profile?)->Void) {
        guard let collection = type.name else {
            return completion(Profile.guestProfile(id: uid))
        }
        
        db.collection(collection).document(uid).getDocument { snapshot, error in
            guard error == nil else { return completion(nil) }
                
            let result = Profile(type: type, document: snapshot)
            completion(result)
        }
    }
    
    func setProfile(_ profile: Profile, completion: @escaping (Bool)->Void) {
        guard let collection = profile.type.name else {
            return completion(false)
        }
        
        var data: [String:Any] = [ProfileKey.userId: profile.uid,
                                  ProfileKey.email: profile.email,
                                  ProfileKey.firstname: profile.firstname,
                                  ProfileKey.surname: profile.surname,
                                  ProfileKey.birthDate: profile.birthDate ?? NSNull(),
                                  ProfileKey.gender: profile.gender?.rawValue ?? NSNull(),
                                  ProfileKey.creationDate: Timestamp(date: profile.creationDate),
                                  ProfileKey.avatar: profile.avatarUrl?.absoluteString ?? ""]
        
        if profile.isBusinessOwner {
            data[ProfileKey.category] = profile.category
            data[ProfileKey.businessName] = profile.businessName
            data[ProfileKey.businessAddress] = profile.businessAddress
            data[ProfileKey.isOnlineStore] = profile.isOnlineStore
            if let location = profile.businessLocation {
                let geo = GeoPoint(latitude: location.latitude, longitude: location.longitude)
                data[ProfileKey.businessLocation] = geo
            }
        }
        print("### setProfile data = \(data)")
        db.collection(collection)
            .document(profile.uid)
            .setData(data, merge: false) { error in
                completion(error == nil)
            }
    }
    
    func updateProfileLocation(_ location: DBLocation, completion: @escaping (Bool)->Void) {
        let geo = GeoPoint(latitude: location.latitude, longitude: location.longitude)
        let data = [ProfileKey.lastLocation : geo]
        updateProfile(data: data, completion: completion)
    }
    
    func updateLastLoginDate(completion: @escaping (_ success: Bool)->Void) {
        let data = [ProfileKey.lastLoginDate : Timestamp(date: Date())]
        updateProfile(data: data, completion: completion)
    }
    
    func updateProfile(data: [String:Any], completion: @escaping (_ success: Bool)->Void) {
        guard let profile = UserManager.shared.profile else {
            Coordinator.redirectToAuth()
            return
        }
        guard let collection = profile.type.name, !profile.uid.isEmpty else {
            return completion(true)
        }
        

        db.collection(collection)
            .document(profile.uid)
            .setData(data, merge: true) { error in
                completion(error == nil)
            }
    }
    
    //MARK: - USER ACTIONS
    
    func updateCustomerBookmarks(dealId: String, isOn: Bool, completion: @escaping (String?)->Void) {
        guard let userId = FirestoreManager.shared.currentUser?.uid else {
            Coordinator.redirectToAuth()
            return
        }
        
        let data: [String:Any] = ["updated" : Timestamp(date: Date())]
        let docRef = db.collection(COLLECTION_CUSTOMERS)
            .document(userId)
            .collection(COLLECTION_SAVED)
            .document(dealId)
        
        if isOn {
            docRef.setData(data) { error in
                return completion( error == nil ? nil :Constants.Error.unexpectedError)
                }
        } else {
            docRef.delete { error in
                return completion( error == nil ? nil :Constants.Error.unexpectedError)
            }
        }
    }
    
    func fetchBookmarks(completion: @escaping ([String]?)->Void) {
        guard let userId = FirestoreManager.shared.currentUser?.uid else {
            Coordinator.redirectToAuth()
            return
        }
        
        db.collection(COLLECTION_CUSTOMERS)
            .document(userId)
            .collection(COLLECTION_SAVED).getDocuments { snapshot, error in
                guard let snapshot = snapshot else { return completion (nil) }
                
                let result = snapshot.documents.map { $0.documentID }
                completion(result)
            }
    }
    
    //MARK: - DEALS
    func uploadDeal(_ deal: CreateDealItem, completion: @escaping (String?)->Void) {
        guard let userId = FirestoreManager.shared.currentUser?.uid else {
            Coordinator.redirectToAuth()
            return
        }
        
        if let image = deal.image, let imageData = image.pngData() {
            let timeStamp = Int(Date().timeIntervalSince1970)
            let imageFileName = "\(timeStamp).png"
            _uploadImage(data: imageData, storageName: userId, fileName: imageFileName, completion: { url in
                guard let imageUrl = url else { return completion("Upload image Error") }
    
                self.addDeal(userId: userId, model: deal, imageUrl: imageUrl, completion: completion)
            }) { progress in }
            
        } else {
            self.addDeal(userId: userId, model: deal, imageUrl: nil, completion: completion)
        }
    }
    
    func updateDeal(id: String, model: CreateDealItem, completion: @escaping (String?)->Void) {
        guard let userId = FirestoreManager.shared.currentUser?.uid else {
            Coordinator.redirectToAuth()
            return
        }
        
        if let image = model.image, let imageData = image.pngData() {
            let timeStamp = Int(Date().timeIntervalSince1970)
            let imageFileName = "\(timeStamp).png"
            _uploadImage(data: imageData, storageName: userId, fileName: imageFileName, completion: { url in
                guard url != nil else { return completion("Upload image Error") }
                
                self.updateDeal(userId: userId, dealId: id, model: model, imageUrl: url, completion: completion)
            }) { progress in }
            
        } else {
            updateDeal(userId: userId, dealId: id, model: model, imageUrl: nil, completion: completion)
        }
    }
    
    func uploadImage(_ image: UIImage, profileId: String, completion: @escaping (URL?)->Void) {
        let storageName = profileId
        let timeStamp = Int(Date().timeIntervalSince1970)
        let imageFileName = "\(timeStamp).png"
        
        guard let pngData = image.pngData() else { return completion(nil) }
        
        _uploadImage(data: pngData, storageName: storageName, fileName: imageFileName, completion: completion)
    }
    
    private func _uploadImage(data: Data, storageName: String, fileName: String, completion: @escaping (URL?)->Void, onProgress:((Double)->Void)? = nil) {
        let imageRef: StorageReference = Storage.storage().reference().child(storageName).child(fileName)
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        
        let uploadTask = imageRef.putData(data, metadata: metadata, completion: { (metadata, error) in
            imageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    completion(nil)
                    return
                }
                completion(downloadURL)
            }
        })
        uploadTask.observe(.progress) { snapshot in }
    }
    
    private func addDeal(userId: String, model: CreateDealItem, imageUrl: URL?, completion: @escaping (String?)->Void) {
        let collectionRef = db.collection(COLLECTION_DEALS)
        let newDocId = collectionRef.document().documentID
        
        var data: [String:Any] = [DealItemKey.userId : userId,
                                  DealItemKey.description : model.about,
                                  DealItemKey.price : model.price,
                                  DealItemKey.discount : model.discount,
                                  DealItemKey.isOnlineStore : model.isOnlineStore,
                                  DealItemKey.promotion : model.promotion,
                                  DealItemKey.address : model.address,
                                  DealItemKey.creationDate: Timestamp(date: Date()),
                                  DealItemKey.dealId : newDocId,
                                  DealItemKey.categories: model.categoryIds
                                 ]
        if let displayName = UserManager.shared.profile?.businessName {
            data[DealItemKey.businessName] = displayName
        }
            
        if let imageUrl = imageUrl, let image = model.image, image.size.height > 0 {
            data[DealItemKey.imageUrl] = imageUrl.absoluteString
            data[DealItemKey.imageAspect] = image.size.width / image.size.width
        }
        
        if let expDate = model.expirationDate {
            data[DealItemKey.expirationDate] = Timestamp(date: expDate)
        }
        if let location = model.location {
            let geo: GeoPoint = GeoPoint(latitude: location.latitude, longitude: location.longitude)
            data[DealItemKey.geo] = geo
        }
        if let quantity = model.quantity {
            data[DealItemKey.quantity] = quantity
        }
        
        collectionRef.document(newDocId).setData(data) { error in
            completion(error == nil ? nil : Constants.Error.unexpectedError)
        }
    }
    
    private func deleteSubcollection(_ collection: String, in docRef: DocumentReference, completion: @escaping ()->Void) {
        docRef.collection(collection).getDocuments { spanshot, error in
            if let documents = spanshot?.documents, !documents.isEmpty {
                let ids = documents.map { $0.documentID }
                self.chunks = ids.chunked(by: 5)
                self.deleteNextChunk(collection, in: docRef, completion: completion)
            } else {
                completion()
            }
        }
    }
    
    private func deleteNextChunk(_ collection: String, in docRef: DocumentReference, completion: @escaping ()->Void) {
        if chunks.isEmpty {
            completion()
        } else {
            let idList = chunks.removeFirst()
            var queryCount = 0
            for id in idList {
                docRef.collection(collection).document(id).delete { _ in
                    queryCount += 1
                    if queryCount == idList.count {
                        self.deleteNextChunk(collection, in: docRef, completion: completion)
                    }
                }
            }
        }
    }
    
    func deleteDeal(id: String, completion: @escaping (String?)->Void) {
        let docRef = db.collection(COLLECTION_DEALS).document(id)
        
        deleteSubcollection(COLLECTION_RATINGS, in: docRef) {
            docRef.delete { error in
                completion(error == nil ? nil : Constants.Error.unexpectedError)
            }
        }
    }
    
    private func updateDeal(userId: String, dealId: String, model: CreateDealItem, imageUrl: URL?, completion: @escaping (String?)->Void) {
        var data: [String:Any] = [DealItemKey.userId : userId,
                                  DealItemKey.description : model.about,
                                  DealItemKey.price : model.price,
                                  DealItemKey.discount : model.discount,
                                  DealItemKey.isOnlineStore : model.isOnlineStore,
                                  DealItemKey.promotion : model.promotion,
                                  DealItemKey.address : model.address]
        
        if let imageUrl = imageUrl, let image = model.image, image.size.height > 0 {
            data[DealItemKey.imageUrl] = imageUrl.absoluteString
            data[DealItemKey.imageAspect] = image.size.width / image.size.width
        }
        
        if let expDate = model.expirationDate {
            data[DealItemKey.expirationDate] = Timestamp(date: expDate)
        } else {
            data[DealItemKey.expirationDate] = NSNull()
        }
        if let location = model.location {
            let geo: GeoPoint = GeoPoint(latitude: location.latitude, longitude: location.longitude)
            data[DealItemKey.geo] = geo
        } else {
            data[DealItemKey.geo] = NSNull()
        }
        
        if let quantity = model.quantity {
            data[DealItemKey.quantity] = quantity
        } else {
            data[DealItemKey.quantity] = NSNull()
        }
        
        //todo: // Delete old Image
        db.collection(COLLECTION_DEALS).document(dealId).setData(data, merge: true) { error in
            completion(error == nil ? nil : Constants.Error.unexpectedError)
        }
    }
    
    func fetchDeals(completion: @escaping ([DealItem]?)->Void, filterExpired: Bool = true) {
        db.collection(COLLECTION_DEALS)
            .getDocuments { snapshot, error in
                guard error == nil else { return completion(nil) }

                var result = (snapshot?.documents ?? []).compactMap { DealItem($0) }
                if filterExpired {
                    result = result.filter { !$0.isExpired }
                }
            
                completion(result)
        }
    }
    
    func fetchDeals(categoryId: String, completion: @escaping ([DealItem]?)->Void) {
        db.collection(COLLECTION_DEALS)
            .whereField(DealItemKey.categories, arrayContains: categoryId)
            //.whereField(DealItemKey.expirationDate, isGreaterThan: Timestamp(date: Date())) //todo: required index
            .getDocuments { snapshot, error in
            guard error == nil else { return completion(nil) }

            var result = (snapshot?.documents ?? []).compactMap { DealItem($0) }
            result = result.filter { !$0.isExpired }
            completion(result)
        }
    }
    
    func fetchDeals(for location: DBLocation?, enableOnline: Bool, completion: @escaping ([DealItem]?)->Void) {
        var result: [DealItem] = []
        let queryOnlineStoreBlock = {
            if enableOnline {
                self.db.collection(COLLECTION_DEALS)
                    .whereField(DealItemKey.isOnlineStore, isEqualTo: true)
                    .getDocuments { snapshot, error in
                        result += (snapshot?.documents ?? []).compactMap { DealItem($0) }
                        result = result.filter { !$0.isExpired }
                        completion(result)
                    }
            } else {
                completion(result)
            }
        }
        
        if let location = location {
            let lesserGeopoint = GeoPoint(latitude: location.region.minLat, longitude: location.region.minLon)
            let greaterGeopoint = GeoPoint(latitude: location.region.maxLat, longitude: location.region.maxLon)

            db.collection(COLLECTION_DEALS)
            .whereField(DealItemKey.geo, isGreaterThan: lesserGeopoint)
            .whereField(DealItemKey.geo, isLessThan: greaterGeopoint)
                .getDocuments { snapshot, error in
                    guard error == nil else { return completion(nil) }
                    
                    result += (snapshot?.documents ?? []).compactMap { DealItem($0) }
                    queryOnlineStoreBlock()
            }
        } else {
            queryOnlineStoreBlock()
        }
    }
    
    func fetchDeal(id: String, completion: @escaping (DealItem?, String?)->Void) {
        db.collection(COLLECTION_DEALS)
            .document(id)
            .getDocument { snapshot, error in
                if let snapshot = snapshot, let dealItem = DealItem(snapshot) {
                    completion(dealItem, nil)
                }
                completion(nil, Constants.Error.unexpectedError)
            }
    }
    
    func fetchDeals(ids: [String], completion: @escaping ([DealItem])->Void) {
        guard !ids.isEmpty else { return completion([]) }
        
        var queryCount: Int = 0
        var result: [DealItem] = []
        
        for documentId in ids {
            db.collection(COLLECTION_DEALS).document(documentId).getDocument { snapshot, error in
                queryCount += 1
                if let snapshot = snapshot, let dealItem = DealItem(snapshot) {
                    result.append(dealItem)
                }
                if queryCount == ids.count {
                    completion(result)
                }
            }
        }
    }
    
    func updateDealRating(_ value: Int, dealId: String, completion: @escaping (String?)->Void) {
        guard let userId = FirestoreManager.shared.currentUser?.uid else {
            Coordinator.redirectToAuth()
            return
        }
        
        let data: [String:Any] = [RatingKey.customerId: userId, RatingKey.dealId: dealId, RatingKey.rating: value]
        db.collection(COLLECTION_DEALS)
            .document(dealId)
            .collection(COLLECTION_RATINGS)
            .document(userId)
            .setData(data) { error in
                completion(error == nil ? nil : Constants.Error.unexpectedError)
            }
    }
    
    func fetchDealRating(dealId: String, completion: @escaping (Int?)->Void) {
        guard let userId = FirestoreManager.shared.currentUser?.uid else {
            Coordinator.redirectToAuth()
            return
        }
        db.collection(COLLECTION_DEALS)
            .document(dealId)
            .collection(COLLECTION_RATINGS)
            .document(userId).getDocument { snapshot, error in
                if let snapshot = snapshot, let rating = Rating(snapshot) {
                    completion(rating.value)
                } else {
                    completion(nil)
                }
            }
    }
    
    //MARK: - Purchases
    func addDealToPurchased(deal: DealItem, completion: @escaping (String?)->Void) {
        guard let userId = FirestoreManager.shared.currentUser?.uid else {
            Coordinator.redirectToAuth()
            return
        }
        
        var data: [String:Any] = [DealItemKey.dealId: deal.documentId,
                                  DealItemKey.userId : deal.userId,
                                  DealItemKey.description : deal.about,
                                  DealItemKey.price : deal.price,
                                  DealItemKey.discount : deal.discount,
                                  DealItemKey.isOnlineStore : deal.isOnlineStore,
                                  DealItemKey.promotion : deal.promotion,
                                  DealItemKey.address : deal.address,
                                  "date" : Timestamp(date: Date())]
        
        if let imageUrl = deal.imageUrl, let aspect = deal.imageAspect {
            data[DealItemKey.imageUrl] = imageUrl.absoluteString
            data[DealItemKey.imageAspect] = aspect
        }
        
        if let expDate = deal.expirationDate {
            data[DealItemKey.expirationDate] = Timestamp(date: expDate)
        }
        if let location = deal.location {
            let geo: GeoPoint = GeoPoint(latitude: location.latitude, longitude: location.longitude)
            data[DealItemKey.geo] = geo
        }
        
        db.collection(COLLECTION_CUSTOMERS)
            .document(userId)
            .collection(COLLECTION_PURCHASES)
            .addDocument(data: data) { error in
                completion(error == nil ? nil : Constants.Error.unexpectedError)
            }
    }
    
    func fetchPurchasedDeals(completion: @escaping ([DealItem]?)->Void) {
        guard let userId = FirestoreManager.shared.currentUser?.uid else {
            Coordinator.redirectToAuth()
            return
        }
        
        db.collection(COLLECTION_CUSTOMERS)
            .document(userId)
            .collection(COLLECTION_PURCHASES)
            .getDocuments { snapshot, error in
                guard error == nil else { return completion(nil) }

                let result = (snapshot?.documents ?? []).compactMap { DealItem($0) }
                completion(result)
            }
    }
    
    //MARK: - Categories
    
    func fetchCategories(completion: @escaping ([DealCategory]?)->Void) {
        db.collection(COLLECTION_CATEGORIES)
            .order(by: DealCategoryKey.index)
            .getDocuments { snapshot, error in
            guard error == nil else { return completion(nil) }
                
            let result = (snapshot?.documents ?? []).compactMap { DealCategory($0) }
            completion(result)
        }
    }
    
    //MARK: - Business
    func fetchMyDeals(completion: @escaping ([DealItem]?)->Void) {
        db.collection(COLLECTION_DEALS)
            .whereField(DealItemKey.userId, isEqualTo: currentUser?.uid ?? "")
            .getDocuments { snapshot, error in
            guard error == nil else { return completion(nil) }

            let result = (snapshot?.documents ?? []).compactMap { DealItem($0) }
            completion(result)
        }
    }
    
    //MARK: - Notifications
    func fetchNotifications(completion: @escaping ([NotificationItem]?)->Void) {
        db.collection(COLLECTION_NOTIFICATIONS)
            .whereField(NotificationItemKey.userId, isEqualTo: currentUser?.uid ?? "")
            .order(by: NotificationItemKey.date, descending: true)
            .getDocuments { snapshot, error in
            guard error == nil else { return completion(nil) }

            let result = (snapshot?.documents ?? []).compactMap { NotificationItem($0) }
            completion(result)
        }
    }
    
    func setNotificationsAsRead(_ notifications: [NotificationItem], completion: @escaping (String?)->Void) {
        guard !notifications.isEmpty else { return completion(nil) }
        
        let batch = db.batch()
        let collectionRef = db.collection(COLLECTION_NOTIFICATIONS)
        
        let updates: [(documentId: String, data: [String: Any])] = notifications.map { ($0.documentId, [NotificationItemKey.read : true]) }
        for update in updates {
            let docRef = collectionRef.document(update.documentId)
            batch.updateData(update.data, forDocument: docRef)
        }
        batch.commit { error in
            completion(error?.localizedDescription)
        }
    }
    
    func deleteNotification(id: String, completion: @escaping (String?)->Void) {
        db.collection(COLLECTION_NOTIFICATIONS)
            .document(id)
            .delete { error in
                completion(error == nil ? nil : Constants.Error.unexpectedError)
            }
    }
    
    func deleteNotifications(ids: [String], completion: @escaping (String?)->Void) {
        guard !ids.isEmpty else { return completion(nil) }
        
        let batch = db.batch()
        let collectionRef = db.collection(COLLECTION_NOTIFICATIONS)

        for documentId in ids {
            let docRef = collectionRef.document(documentId)
            batch.deleteDocument(docRef)
        }
        
        batch.commit { error in
            completion(error?.localizedDescription)
        }
    }
    
    func updateFCMToken(newToken: String?, oldToken: String?, completion: @escaping (Bool)->Void) {
        guard let profile = UserManager.shared.profile else { return }
        
        let addNewDocumentBlock: (String)->Void = { token in
            let accountType: String = profile.isBusinessOwner ? "business" : "customer"
            let data = ["token": token, "userId" : profile.uid, "type": accountType]
            self.db.collection(COLLECTION_TOKENS).addDocument(data: data) { error in
                completion(error == nil)
            }
            print("FDB: did set token data to new Document: \(data)")//del
        }
        
        if let oldToken = oldToken {
            db.collection(COLLECTION_TOKENS).whereField("token", isEqualTo: oldToken).getDocuments { snapshot, error in
                print("#FETCH notification token)")//del
                guard let firstDoc = snapshot?.documents.first else {
                    if let newToken = newToken {
                        addNewDocumentBlock(newToken)
                    } else {
                        print("FDB: cannot delete token \(oldToken) because it's not found in database")//del
                        completion(true)
                    }
                    return
                }
                
                if let newToken = newToken {
                    let data = ["token": newToken, "userId" : profile.uid]
                    self.db.collection(COLLECTION_TOKENS).document(firstDoc.documentID).setData(data) { error in
                        completion(error == nil)
                    }
                    print("FDB: did update token data in existing document: \(data)")//del
                } else {
                    self.db.collection(COLLECTION_TOKENS).document(firstDoc.documentID).delete() { error in
                        print("FDB: did delete token data. Success: \(error == nil)")//del
                        completion(error == nil)
                    }
                }
            }
        } else if let newToken = newToken {
            addNewDocumentBlock(newToken)
        } else {
            completion(false)
        }
    }
    
    //MARK: - Reports
    func addReport(dealId: String, text: String, completion: @escaping (String?)->Void) {
        guard let userId = FirestoreManager.shared.currentUser?.uid else {
            Coordinator.redirectToAuth()
            return
        }
        
        let data: [String:Any] = ["userID": userId, "dealID": dealId, "text": text, "date" : Timestamp(date: Date())]
        db.collection(COLLECTION_REPORTS)
            .addDocument(data: data) { error in
                completion(error == nil ? nil : Constants.Error.unexpectedError)
        }
    }
}
