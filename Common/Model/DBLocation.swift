//
//  Location.swift
//  Dilblitz
//
//  Created by ОК on 20.04.2021.
//

import Foundation

import CoreLocation
import MapKit

struct DBLocation: Codable, Equatable {
    
    static func == (lhs: DBLocation, rhs: DBLocation) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    let latitude: Double
    let longitude: Double
    
    init?(latitude: Double?, longitude: Double?) {
        guard
            let latitude = latitude,
            let longitude = longitude
        else { return nil }
        
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    func toString() -> String {
        return "\(latitude),\(longitude)"
    }
    
    var region: (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        let radius: Double = Constants.defaultRegionRadiusMeters
        let clLocation = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        let coordinateRegion = MKCoordinateRegion(center: clLocation, latitudinalMeters: radius, longitudinalMeters: radius)
        let span = coordinateRegion.span
        
        let minLat = latitude - span.latitudeDelta * 0.5
        let maxLat = latitude + span.latitudeDelta * 0.5
        let minLon = longitude - span.longitudeDelta * 0.5
        let maxLon = latitude + span.longitudeDelta * 0.5
        
        return (minLat, maxLat, minLon, maxLon)
    }
    
    var description: String {
        "\(latitude),\(longitude)"
    }
}
