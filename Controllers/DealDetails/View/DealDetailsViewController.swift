//
//  DealDetailsViewController.swift
//  Dilblitz
//
//  Created by ОК on 02.05.2021.
//

import UIKit
import MapKit

class DealDetailsViewController: UIViewController {
    
    @IBOutlet weak var dealTitleLabel: UILabel!
    @IBOutlet weak var businessName: UILabel!
    @IBOutlet weak var containerWithShadow: RoundedViewWithShadow!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var coverImageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var discountLabel: UILabel!
    @IBOutlet weak var discountLabelContainer: UIView!
    @IBOutlet weak var discountLabelTrailing: NSLayoutConstraint!
    @IBOutlet weak var dealPromotionLabel: UILabel!
    @IBOutlet weak var oldPriceLabel: UILabel!
    @IBOutlet weak var newPriceLabel: UILabel!
    
    @IBOutlet weak var rateView: RateView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var expiresContainer: UIView!
    @IBOutlet weak var expiresLabel: UILabel!
    @IBOutlet weak var locationIconImageView: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var customerPhotosContainer: UIView!
    
    @IBOutlet weak var purchaseDealButton: UIButton!
    @IBOutlet weak var purchaseDealButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapViewHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionContainerLeading: NSLayoutConstraint!
    @IBOutlet weak var collectioinViewButtom: NSLayoutConstraint!
    @IBOutlet weak var bookmarkButton: UIButton!
    
    var deal: DealItem!
    var isBookmarked = false
    var collectionData: [URL] {
        return deal.photoUrls
    }
    
    let cellLineSpacing: CGFloat = 16
    var cellWidth: CGFloat {
        let collectionWidth = UIScreen.main.bounds.width - 2.0 * collectionContainerLeading.constant
        return collectionWidth / 3.0 - 2.0 * cellLineSpacing
    }
    var cellHeight: CGFloat {
        let aspect: CGFloat = 103.0 / 77.0
        return cellWidth / aspect
    }
    
    var isRegularProfile: Bool {
        return UserManager.shared.profile?.type == .customer
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.isHidden = true
        setupUI()
        setupCollectionView()
        
        let touch = UITapGestureRecognizer(target: self, action: #selector(mapTapHandler))
        mapView.addGestureRecognizer(touch)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        if UserManager.shared.profile?.isBusinessOwner == true { //by request to remove buttom from customer view but we just set height to 0 for all
            purchaseDealButtonHeight.constant = 0
//        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard mapView.delegate == nil else { return }
        
        if let dealLocation = deal.location {
            mapViewHeight.constant = mapView.bounds.width * 8.0 / 15.0
            mapView.isHidden = false
            mapView.delegate = self
            let center = CLLocationCoordinate2D(latitude: dealLocation.latitude, longitude: dealLocation.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
            mapView.setRegion(region, animated: false)
            let annotation = MKPointAnnotation()
            annotation.coordinate = center
            mapView.addAnnotation(annotation)
        } else {
            mapViewHeight.constant = 0
            mapView.isHidden = true
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        discountLabelContainer.layer.cornerRadius = 0.5 * discountLabelContainer.frame.size.height
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let imageAspect = deal.imageAspect, imageAspect != 0 {
            coverImageViewHeight.constant = coverImageView.bounds.width / CGFloat(imageAspect)
        } else {
            coverImageViewHeight.constant = coverImageView.bounds.width / 2
        }
        
        rateView.rate = Float(deal.rate)
    }
    
    private func setupUI() {
        dealTitleLabel.text = deal.promotion
        businessName.text = deal.businessName ?? ""
        containerWithShadow.cornerRadius = 22
        containerWithShadow.shadowOffsetHeight = 0
        containerWithShadow.shadowOffsetWidth = 0
        containerWithShadow.shadowOpacity = 0.3
        coverImageView.layer.cornerRadius = 12
        mapView.layer.cornerRadius = 12
        purchaseDealButton.layer.cornerRadius = 0.5 * purchaseDealButton.bounds.height
        coverImageView.sd_setImage(with: deal.imageUrl)
        
        if deal.discount > 0 {
            discountLabelContainer.isHidden = false
            discountLabel.text = "\(Int(deal.discount))% off"
        } else {
            discountLabelContainer.isHidden = true
            discountLabel.text = ""
        }
        
        dealPromotionLabel.text = deal.promotion
        
        let discountPrice: Double = deal.price - deal.price * deal.discount / 100.0
        oldPriceLabel.text = String(format: "%.02f", deal.price)
        newPriceLabel.text = "￡\(String(format: "%.02f", discountPrice))"
        
        rateView.height = 14
        rateView.titleLabel.font = rateView.titleLabel.font.withSize(14)
        
        if let profile = UserManager.shared.profile, !profile.isBusinessOwner {
            rateView.onTouchAction = { [weak self] in
                self?.onRateAction()
            }
        }
        descriptionLabel.text = deal.about
        if let expDate = deal.expirationDate {
            expiresLabel.text = "Expires on \(expDate.dateTimeString)"
        } else {
            expiresLabel.text = ""
        }
        
        locationLabel.text = deal.address
        locationIconImageView.image = locationIconImageView.image?.imageWithColor(color1: UIColor(named: "mainBlue")!)
        
        updateBookmarkButton()
    }
    
    private func updateBookmarkButton(force: Bool = false) {
        if !force {
            isBookmarked = UserManager.shared.bookmarks.contains(deal.documentId)
        }
        
        bookmarkButton.setImage(UIImage(named: isBookmarked ? "bookmark_filled" : "bookmark"), for: .normal)
    }
    
    private func setupCollectionView() {
        if deal.photoUrls.isEmpty {
            customerPhotosContainer.isHidden = true
            collectionViewHeight.constant = 0
            collectioinViewButtom.constant = -32
        } else {
            collectionViewHeight.constant = cellHeight
        }
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 16
        collectionView.collectionViewLayout = flowLayout
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UINib(nibName: "DealPhotoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "DealPhotoCollectionViewCell")
    }
    
    private func onRateAction() {
        guard isRegularProfile else { return showAuth() }
        
        showRateDeal(deal) { [weak self] error in
            guard let self = self else { return }
            guard error == nil else {
                showAlert(message: error!, title: "Rate error")
                return
            }

            let fetchAndUpdateBlock = {
                FirestoreManager.shared.fetchDeals(ids: [self.deal.documentId]) { [weak self] data in
                    guard let self = self else { return }
                    
                    if let result = data.first {
                        self.rateView.rate = Float(result.rate)
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                fetchAndUpdateBlock()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                fetchAndUpdateBlock()
            }
        }
    }
    
    func purchaseDeal() {
        guard isRegularProfile else { return showAuth() }
        
        view.startActivityAnimating()
        FirestoreManager.shared.addDealToPurchased(deal: deal) { [weak self] error in
            guard let self = self else { return }
            
            self.view.stopActivityAnimating()
            guard error == nil else {
                self.showAlert(message: error!)
                return
            }
            
            self.showAlert(message: "Deal purchased") { _ in
                self.navigateBack(toRoot: true)
            }
        }
    }
    
    private func navigateBack(toRoot: Bool) {
        if let nc = self.navigationController {
            if toRoot {
                nc.popToRootViewController(animated: true)
            } else {
                nc.popViewController(animated: true)
            }
        } else {
            self.dismiss(animated: true)
        }
    }
    
    func showAuth() {
        Coordinator.navigateToAuth(from: self, isBusinessOwner: false, dismissCompletion: {}, modally: true)
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        navigateBack(toRoot: false)
    }
    
    @IBAction func purchaseDealButtonPressed(_ sender: Any) {
        purchaseDeal()
    }
    
    @IBAction func bookmarButtonPressed() {
        self.isBookmarked = !self.isBookmarked
        updateBookmarkButton(force: true)
        
        FirestoreManager.shared.updateCustomerBookmarks(dealId: deal.documentId, isOn: isBookmarked) { [weak self] error in
            guard error == nil else {
                self?.showAlert(message: error!)
                return }
            
            UserManager.shared.updateBookmarks { [weak self] in
                self?.updateBookmarkButton()
            }
        }
    }
    
    @objc func mapTapHandler() {
        let alert = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            
        alert.addAction(UIAlertAction(title: "Google Maps", style: .default , handler:{ _ in
            guard let location = self.deal.location else { return }
            
            if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                if let url = URL(string: "comgooglemaps-x-callback://?saddr=&daddr=\(location.latitude),\(location.longitude)&directionsmode=driving") {
                    UIApplication.shared.open(url, options: [:])
                }
            } else {
               if let urlDestination = URL.init(string: "https://www.google.co.in/maps/dir/?saddr=&daddr=\(location.latitude),\(location.longitude)&directionsmode=driving") {
                        UIApplication.shared.open(urlDestination)
                    }
                }
           }
        ))
        
        alert.addAction(UIAlertAction(title: "Apple Maps", style: .default, handler:{ _ in
            guard let location = self.deal.location else { return }
            
            let placemark = MKPlacemark(coordinate:
                                            CLLocationCoordinate2D(latitude: CLLocationDegrees(location.latitude),
                                                                   longitude: CLLocationDegrees(location.longitude)))
            let source = MKMapItem(placemark: placemark)
            source.name = self.deal.promotion
                    
            MKMapItem.openMaps(
              with: [source],
              launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsMapCenterKey]
            )
        }))
    
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ _ in }))

        //uncomment for iPad Support
        alert.popoverPresentationController?.sourceView = self.view

        self.present(alert, animated: true, completion: {})
    }
}

extension DealDetailsViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DealPhotoCollectionViewCell", for: indexPath) as! DealPhotoCollectionViewCell
        cell.configureWith(imageUrl: collectionData[indexPath.row])
        
        return cell
    }
}

extension DealDetailsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
}

extension DealDetailsViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "dealLocation")
        annotationView.image = UIImage(named:"placemark small")
        return annotationView
    }
}
