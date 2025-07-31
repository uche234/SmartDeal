//
//  LocationTrakingManager.swift
//  Dilblitz
//
//  Created by OK on 24.01.2022.
//

import Foundation
import CoreLocation
import UIKit

fileprivate struct GetLocationData {
    let manager: CLLocationManager
    var isManagerInitiallyAuthorized: Bool = false
    let completion: ((DBLocation?)->Void)?
}

class LocationTrakingManager: NSObject {
    static let shared: LocationTrakingManager = LocationTrakingManager()
    
    var isTrakingLocation = false
    private var trakinLocationManager = CLLocationManager()
    var requestLocationPeriod: TimeInterval? = nil
    
    lazy var lastLocation: LocationWithAddress? = manualySetLocation {
        didSet {
            if lastLocation != nil {
                NotificationCenter.default.post(name: .locationDidChanged, object: nil)
            }
        }
    }
    
    var manualySetLocation: LocationWithAddress? {
        get {
            if let savedData = UserDefaults.standard.data(forKey: "manualySetLocationKey") {
                let decoder = JSONDecoder()
                if let loadedLocation = try? decoder.decode(LocationWithAddress.self, from: savedData) {
                    return loadedLocation
                }
            }
            return nil
        }
        set {
            if let value = newValue {
                let encoder = JSONEncoder()
                if let encoded = try? encoder.encode(value) {
                    UserDefaults.standard.set(encoded, forKey: "manualySetLocationKey")
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "manualySetLocationKey")
            }
        }
    }
    
    private var getLocationQueue: [GetLocationData] = []
    
    func startTrakingLocation() {
        guard manualySetLocation == nil else { return }
        guard !isTrakingLocation else { return }
        
        var data = GetLocationData(manager: trakinLocationManager, completion: nil)
        data.isManagerInitiallyAuthorized = trakinLocationManager.isAuthorized
        _startTrakingLocation(data: data)
    }
    
    private func _startTrakingLocation(data: GetLocationData) {
        data.manager.delegate = self
        data.manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        if data.manager.isAuthorized {
            data.manager.startUpdatingLocation()
            if data.manager == trakinLocationManager {
                isTrakingLocation = true
            }
        } else {
            if data.manager.authorizationStatus == .notDetermined {
                data.manager.requestWhenInUseAuthorization()
            } else if let completion = data.completion {
                completion(nil)
                showLocationDeniedAlert()
            }
        }
    }
    
    func getAddressFromLocation(_ location: DBLocation, completion: @escaping ([String], String?)->Void) {
        let loc: CLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, _ in
            let placemarks: [CLPlacemark] = placemarks ?? []
            var result: [String] = []

            for item in placemarks {
                if let compactAddress = item.compactAddress {
                    result.append(compactAddress)
                } else {
                    let addressString = [item.thoroughfare, item.subThoroughfare, item.locality].compactMap { $0 }.joined(separator: ", ")
                    if !addressString.isEmpty {
                        result.append(addressString)
                    }
                }
            }
            
            completion(result, nil)
        }
    }
    
    func getLocationFromAddress(_ address: String, completion: @escaping (_ location: DBLocation?)-> Void) {
        guard !address.trimmingCharacters(in: .whitespaces).isEmpty else { return completion(nil) }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            guard let placemarks = placemarks,
            let location = placemarks.first?.location?.coordinate else {
                completion(nil)
                return
            }
            completion(DBLocation(latitude: location.latitude, longitude: location.longitude))
        }
    }
    
    func stopTrakingLocation() {
        trakinLocationManager.stopUpdatingLocation()
        trakinLocationManager.delegate = nil
        isTrakingLocation = false
    }
    
    func getLocation(completion: @escaping (DBLocation?)->Void) {
        let lm = CLLocationManager()
        var data = GetLocationData(manager: lm, completion: completion)
        data.isManagerInitiallyAuthorized = lm.isAuthorized
        getLocationQueue.append(data)
        _startTrakingLocation(data: data)
    }
    
    private func sendUpdateLocation(_ location: DBLocation) {
        FirestoreManager.shared.updateProfileLocation(location) { _ in }
    }
    
    private func showLocationDeniedAlert() {
        guard let rootVC = Utils.topViewController else { return }
        
        let optionSettings = "Settings"
        //todo: check text
        rootVC.showAlert(message: "Please, enable location in settings", title: "", options: ["Cancel", optionSettings]) { option in
            if option == optionSettings, let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                rootVC.open(url: settingsUrl)
            }
        }
    }
}

extension LocationTrakingManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if manager.isAuthorized {
            if manager == trakinLocationManager {
                startTrakingLocation()
            } else if let dataItem = getLocationQueue.first(where: { $0.manager == manager } ) {
                if !dataItem.isManagerInitiallyAuthorized {
                    _startTrakingLocation(data: dataItem)
                }
            }
        } else if manager.isDenied, let dataItem = getLocationQueue.first(where: { $0.manager == manager }), dataItem.completion != nil {
            showLocationDeniedAlert()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.first?.coordinate
        let _location = DBLocation(latitude: coordinate?.latitude, longitude: coordinate?.longitude)
        
        if let index = getLocationQueue.firstIndex(where: { $0.manager == manager }) {
            getLocationQueue[index].manager.stopUpdatingLocation()
            getLocationQueue[index].completion?(_location)
            getLocationQueue.remove(at: index)
        }
        
        guard let resultLocation = _location, manager == trakinLocationManager else { return }
        
        stopTrakingLocation()
        sendUpdateLocation(resultLocation)
        
        self.getAddressFromLocation(resultLocation) { data, _ in
            guard self.manualySetLocation == nil else { return }
            guard let address = data.first, !address.isEmpty else { return }
            
            self.lastLocation = LocationWithAddress(location: resultLocation, address: address)
            
            if let requestLocationPeriod = self.requestLocationPeriod {
                DispatchQueue.main.asyncAfter(deadline: .now() + requestLocationPeriod) {
                    self.startTrakingLocation()
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let index = getLocationQueue.firstIndex(where: { $0.manager == manager }) {
            getLocationQueue[index].manager.stopUpdatingLocation()
            getLocationQueue[index].completion?(nil)
            getLocationQueue.remove(at: index)
        }
    }
}

extension Notification.Name {
    static let locationDidChanged = Notification.Name("locationDidChanged")
}

extension CLLocationManager {
    var isAuthorized: Bool {
        return (self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways)
    }
    
    var isDenied: Bool {
        return self.authorizationStatus == .denied
    }
}
