//
//  RootTabBarViewController.swift
//  Dilblitz
//
//  Created by ОК on 20.04.2021.
//

import UIKit

class CRootTabBarViewController: UITabBarController, UITabBarControllerDelegate  {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Coordinator.rootTabbarController = self
        delegate = self
        tabBar.backgroundColor = .white
        tabBar.isTranslucent = false
        tabBar.tintColor = UIColor(named: "mainBlue")
        tabBar.unselectedItemTintColor = UIColor(named: "grayText")
        setupViewControllers()
        
        LocationTrakingManager.shared.requestLocationPeriod = 5 * 60
        LocationTrakingManager.shared.startTrakingLocation()
        fetchNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let deal = Coordinator.dealToShowOnStart {
            presentDeal(deal)
            Coordinator.dealToShowOnStart = nil
        }
    }
    
    func setupViewControllers() {
        
        var _viewControllers: [UIViewController] = []

        //EXPLORE
        let exploreVC = Storyboard.Explore.instantiate()
        let exploreNC = UINavigationController(rootViewController: exploreVC)
        exploreNC.tabBarItem = UITabBarItem(title: "Explore", image: UIImage(named: "tab_explore"), tag: 0)
        exploreNC.isNavigationBarHidden = true
        _viewControllers.append(exploreNC)
        
        //SEARCH
        let searchVC = Storyboard.Search.instantiate()
        let searchNC = UINavigationController(rootViewController: searchVC)
        searchNC.tabBarItem = UITabBarItem(title: "Search", image: UIImage(named: "tab_search"), tag: 1)
        searchNC.isNavigationBarHidden = true
        _viewControllers.append(searchNC)
        
        //PROFILE
        let profileVC = Storyboard.CProfile.instantiate()
        let profileNC = UINavigationController(rootViewController: profileVC)
        profileNC.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(named: "tab_profile"), tag: 2)
        profileNC.isNavigationBarHidden = true
        _viewControllers.append(profileNC)
        
        //NOTIFICATIONS
        let notificationsVC = Storyboard.CNotifications.instantiate()
        let notificationsNC = UINavigationController(rootViewController: notificationsVC)
        notificationsNC.tabBarItem = UITabBarItem(title: "Notifications", image: UIImage(named: "tab_notify"), tag: 3)
        notificationsNC.isNavigationBarHidden = true
        _viewControllers.append(notificationsNC)
        
        //SETTINGS
        let settingsVC = Storyboard.Settings.instantiate()
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "tab_settings"), tag: 4)
        _viewControllers.append(settingsVC)
        
        viewControllers = _viewControllers
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
           return true
    }
    
    private func fetchNotifications() {
        FirestoreManager.shared.fetchNotifications { [weak self] data in
            guard let self = self else { return }
            
            updateNotificationsBadge(notifications: data ?? [])
        }
    }
    
    private func updateNotificationsBadge(notifications: [NotificationItem]) {
        let tabIndex = 3
        guard let tabItems = tabBar.items, tabIndex < tabItems.count else { return }
        
        let notReadCount = (notifications.filter { $0.read == false }).count
        tabItems[tabIndex].badgeValue = notReadCount == 0 ? nil : "\(notReadCount)"
    }

}
