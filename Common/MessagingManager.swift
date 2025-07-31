//
//  MessagingManager.swift
//  Dilblitz
//
//  Created by OK on 19.01.2022.
//

import Foundation
import FirebaseMessaging

class MessagingManager: NSObject {
    static let shared: MessagingManager = MessagingManager()
    private let keyFCMToken = "keyFCMToken"
    private let keyIsSubscribed = "keyIsSubscribed"
    private let keyFCMTokenWasSent = "keyFCMTokenWasSent"
    
    private var fcmToken: String? {
        get {
            return UserDefaults.standard.object(forKey: keyFCMToken) as? String
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: keyFCMToken)
            UserDefaults.standard.synchronize()
        }
    }
    
    private var fcmTokenWasSent: String? {
        get {
            return UserDefaults.standard.object(forKey: keyFCMTokenWasSent) as? String
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: keyFCMTokenWasSent)
            UserDefaults.standard.synchronize()
        }
    }
    
    func updateFCMToken(_ token: String) {
        fcmToken = token
        
        if isSubscribed {
            sendFCMToken(fcmToken) {_ in }
        } else if let profile = UserManager.shared.profile, profile.type != .guest {
            updateManualyIsSubscribed(true)
        }
    }
    
    private(set) var isSubscribed: Bool {
        get {
            return UserDefaults.standard.bool(forKey: keyIsSubscribed)
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: keyIsSubscribed)
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: .pushNotificationsIsSubscribedChanged, object: nil)
        }
    }
    
    private func sendFCMToken(_ token: String?, completion: ((Bool)->Void)? = nil) {
        guard  token != fcmTokenWasSent else {
            print("Skip to sent. This FCM token already exist")
            completion?(false)
            return
        }
        
        FirestoreManager.shared.updateFCMToken(newToken: token, oldToken: fcmTokenWasSent) { success in
            if success {
                self.fcmTokenWasSent = token
            }
            completion?(success)
        }
    }
    
    private func showAlertToNavigateToSystemSettings() {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            //todo: check text
            let settingsTitle = "Settings"
            topController.showAlert(message: "Please allow Notifications in Settings and try again", title: "", options: ["OK", settingsTitle], completion: { title in
                if title == settingsTitle {
                    topController.open(url: URL(string: UIApplication.openSettingsURLString)!)
                }
            })
        }
    }
    
    func updateManualyIsSubscribed(_ value: Bool, completion: ((Bool)->Void)? = nil) {
        if value {
            isSubscribed = true
            sendFCMToken(fcmToken, completion: completion)
        } else {
            isSubscribed = false
            sendFCMToken(nil, completion: completion)
        }
    }
    
    func subscribeForNotifications(completion: @escaping (Bool)->Void) {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus != .denied else {
                DispatchQueue.main.async {
                    self.showAlertToNavigateToSystemSettings()
                    completion(false)
                }
                return
            }
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            center.requestAuthorization( options: authOptions) { granted, error in
                DispatchQueue.main.async {
                    print("requestAuthorization  granted = \(granted)")
                    if granted {
                        self.isSubscribed = true
                        self.sendFCMToken(self.fcmToken)
                    }
                    UIApplication.shared.registerForRemoteNotifications()
                    completion(granted)
                }
            }
        }
    }
    
    func unSubscribeForNotifications() {
        isSubscribed = false
        sendFCMToken(nil)
    }
}

extension Notification.Name {
    static let pushNotificationsIsSubscribedChanged = Notification.Name("pushNotificationsIsSubscribedChanged")
}
