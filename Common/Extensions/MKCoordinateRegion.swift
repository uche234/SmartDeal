//
//  MKCoordinateRegion.swift
//  Dilblitz
//
//  Created by ОК on 02.05.2021.
//

import MapKit

extension MKCoordinateRegion {
    
    init?(coordinates: [CLLocationCoordinate2D]) {
        
        let primeRegion = MKCoordinateRegion.region(for: coordinates, transform: { $0 }, inverseTransform: { $0 })
        
        let transformedRegion = MKCoordinateRegion.region(for: coordinates, transform: MKCoordinateRegion.transform, inverseTransform: MKCoordinateRegion.inverseTransform)
        
        if let a = primeRegion,
            let b = transformedRegion,
            let min = [a, b].min(by: { $0.span.longitudeDelta < $1.span.longitudeDelta }) {
            self = min
        }
            
        else if let a = primeRegion {
            self = a
        }
            
        else if let b = transformedRegion {
            self = b
        }
            
        else {
            return nil
        }
    }
    
    // Latitude -180...180 -> 0...360
    private static func transform(c: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        if c.longitude < 0 { return CLLocationCoordinate2DMake(c.latitude, 360 + c.longitude) }
        return c
    }
    
    // Latitude 0...360 -> -180...180
    private static func inverseTransform(c: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        if c.longitude > 180 { return CLLocationCoordinate2DMake(c.latitude, -360 + c.longitude) }
        return c
    }
    
    private typealias Transform = (CLLocationCoordinate2D) -> (CLLocationCoordinate2D)
    
    private static func region(for coordinates: [CLLocationCoordinate2D], transform: Transform, inverseTransform: Transform) -> MKCoordinateRegion? {
        
        // handle empty array
        guard !coordinates.isEmpty else { return nil }
        
        // handle single coordinate
        guard coordinates.count > 1 else {
            return MKCoordinateRegion(center: coordinates[0], span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        }
        
        let transformed = coordinates.map(transform)
        
        let minLat = transformed.min { $0.latitude < $1.latitude }!.latitude
        let maxLat = transformed.max { $0.latitude < $1.latitude }!.latitude
        let minLon = transformed.min { $0.longitude < $1.longitude }!.longitude
        let maxLon = transformed.max { $0.longitude < $1.longitude }!.longitude
        let span = MKCoordinateSpan(latitudeDelta: maxLat - minLat, longitudeDelta: maxLon - minLon)
        
        let center = inverseTransform(CLLocationCoordinate2DMake((maxLat - span.latitudeDelta / 2), maxLon - span.longitudeDelta / 2))
        
        return MKCoordinateRegion(center: center, span: span)
    }
}
