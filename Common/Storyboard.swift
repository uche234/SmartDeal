//
//  Storyboard.swift
//  Dilblitz
//
//  Created by ОК on 20.05.2021.
//

import UIKit

enum Storyboard {
    //common
    case CheckEmail
    
    //for business
    case BProfile, MyDeals, CreateDeal, PreviewDeal
    
    //for customer
    case Explore, Search, CProfile, CNotifications, Settings
    case Report(dealItem: DealItem)
    case RateDeal(dealItem: DealItem)
    
    var name: String {
        switch self {
        case .CheckEmail:
            return "CheckEmail"
        case .BProfile:
            return "BProfile"
        case .CreateDeal:
            return "CreateDeal"
        case .PreviewDeal:
            return "PreviewDeal"
        case .MyDeals:
            return "MyDeals"
        case .Settings:
            return "Settings"
        case .Explore:
            return "Explore"
        case .Search:
            return "Search"
        case .CProfile:
            return "CProfile"
        case .CNotifications:
            return "CNotifications"
        case .Report:
            return "Report"
        case .RateDeal:
            return "RateDeal"
        }
    }
    
    func instantiate() -> UIViewController {
        let storyboard = UIStoryboard(name: name, bundle: nil)
        let vc = storyboard.instantiateInitialViewController()!
        
        //optional initilazing
        switch self {
        case .Report(let dealItem):
            (vc as? ReportViewController)?.deal = dealItem
        case .RateDeal(let dealItem):
            (vc as? RateDealViewController)?.deal = dealItem
        default: break
        }
        
        return vc
    }
}
