//
//  Date.swift
//  Dilblitz
//
//  Created by ОК on 28.05.2021.
//

import Foundation

extension Date {
    var ddmmyyyString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: self)
    }
    
    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    var timeAgoSinceNow: String {
            let fromDate = self
            let toDate = Date()

//            // Year
//            if let interval = Calendar.current.dateComponents([.year], from: fromDate, to: toDate).year, interval > 0  {
//
//                return interval == 1 ? "\(interval)" + " " + "year ago" : "\(interval)" + " " + "years ago"
//            }
//
//            // Month
//            if let interval = Calendar.current.dateComponents([.month], from: fromDate, to: toDate).month, interval > 0  {
//
//                return interval == 1 ? "\(interval)" + " " + "month ago" : "\(interval)" + " " + "months ago"
//            }

            // Day
            if let interval = Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day, interval > 0  {
                //return interval == 1 ? "\(interval)" + " " + "day ago" : "\(interval)" + " " + "days ago"
                return ddmmyyyString
            }

            // Hours
            if let interval = Calendar.current.dateComponents([.hour], from: fromDate, to: toDate).hour, interval > 0 {
                return interval == 1 ? "\(interval)" + " " + "hour" : "\(interval)" + " " + "hours"
            }

            // Minute
            if let interval = Calendar.current.dateComponents([.minute], from: fromDate, to: toDate).minute, interval > 0 {
                return interval == 1 ? "\(interval)" + " " + "minute" : "\(interval)" + " " + "minutes"
            }

            return "now"
        }
}
