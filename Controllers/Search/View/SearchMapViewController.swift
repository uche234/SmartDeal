//
//  SearchMapViewController.swift
//  Dilblitz
//
//  Created by ОК on 06.05.2021.
//

import UIKit
import MapKit
import CHIPageControl

class SearchMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var customPageControl: CHIPageControlAji!
    
    var currentPageIndex: Int = 0
    
    private var deals: [DealItem] = []
    var onShowDealDetails: ((DealItem)->Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        setupCollectionView()
        customPageControl.isHidden = true
    }
    
    public func updateDeals(_ deals: [DealItem]) {
        self.deals = deals
        
        if deals.count <= 3 {
            customPageControl.numberOfPages = deals.count
        } else {
            customPageControl.numberOfPages = 3
        }
        
        customPageControl.progress = 0
        customPageControl.radius = 3.5
        reloadMap(animated: false)
        collectionView.reloadData()
    }
    
    func setupCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = flowLayout
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UINib(nibName: "DealSmallCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "DealSmallCollectionViewCell")
    }
    
    func reloadMap(animated: Bool) {
        mapView.removeAnnotations(mapView.annotations)

        let dealLocations = deals.compactMap { $0.location }
        let locations = dealLocations.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }

        var annotations: [MKPointAnnotation] = []
        for locationItem in locations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = locationItem
            annotations.append(annotation)
        }
        mapView.addAnnotations(annotations)
        moveMapToCurrentDealLocation(animated: animated)
    }
    
    
    private func moveMapToCurrentDealLocation(animated: Bool) {
        guard deals.indices.contains(currentPageIndex) else { return }
        guard let location = deals[currentPageIndex].location else { return }
            
        let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
        mapView.setRegion(region, animated: animated)
    }
    
    func updatePageControl() {
        if deals.count >= 3 {
            if currentPageIndex == 0 {
                customPageControl.progress = 0
            } else if currentPageIndex == deals.count - 1 {
                customPageControl.progress = 2
            } else {
                customPageControl.progress = 1
            }
        } else {
            if currentPageIndex == 0 {
                customPageControl.progress = 0
            } else {
                customPageControl.progress = 1
            }
        }
    }
}

extension SearchMapViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return deals.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DealSmallCollectionViewCell", for: indexPath) as! DealSmallCollectionViewCell
        cell.configureWith(data: deals[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onShowDealDetails?(deals[indexPath.row])
    }
}

extension SearchMapViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let center = CGPoint(x: collectionView.contentOffset.x + (collectionView.frame.width / 2), y: (collectionView.frame.height / 2))
        var newIndex: Int?
        if let indexPath = collectionView.indexPathForItem(at: center) {
            newIndex = indexPath.row
        }
        
        guard newIndex != nil, newIndex! != currentPageIndex else {
            return
        }
        
        currentPageIndex = newIndex!
        updatePageControl()
        reloadMap(animated: true)
    }
}

extension SearchMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard deals.indices.contains(currentPageIndex) else { return nil }
        
        let currentDeal = deals[currentPageIndex]
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "dealLocation")
        if annotation.coordinate.latitude == currentDeal.location?.latitude, annotation.coordinate.longitude == currentDeal.location?.longitude {
            annotationView.image = UIImage(named:"placemark active")
        } else {
            annotationView.image = UIImage(named:"placemark inactive")
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let currentDeal = deals[currentPageIndex]
        
        guard let annotation = view.annotation else { return }
        
        if annotation.coordinate.latitude == currentDeal.location?.latitude, annotation.coordinate.longitude == currentDeal.location?.longitude {
            return
        }
        
        guard let index = deals.firstIndex(where: { $0.location?.latitude ==  annotation.coordinate.latitude && $0.location?.longitude ==  annotation.coordinate.longitude }) else { return }
        
        currentPageIndex = index
        updatePageControl()
        collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: true)
        reloadMap(animated: true)
    }
}
