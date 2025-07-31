//
//  ExploreViewController.swift
//  Dilblitz
//
//  Created by ОК on 20.04.2021.
//

import UIKit

class ExploreViewController: UIViewController {
    
    @IBOutlet weak var searchBar: SearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var noDealsView: NoDealsView!
    
    var refreshControl = UIRefreshControl()
    var fetchedDeals: [DealItem]?
    var collectionData: [DealItem] = []
    let collectionInset: CGFloat = 14
    
    var searchText: String = "" {
        didSet {
            updateData()
        }
    }
    
    var cellWidht: CGFloat {
        return (collectionView.frame.width - 2.0 * collectionInset) / 2.0
    }
    
    var isRegularProfile: Bool {
        return UserManager.shared.profile?.type == .customer
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.onSearch = { [weak self] searchText in
            self?.searchText = searchText
        }
        setupCollectionView()
        locationButton.setImage(UIImage(named: "placemark_white"), for: .normal)
        locationButton.titleLabel?.numberOfLines = 2
        locationButton.titleLabel?.textAlignment = .center
        locationButton.imageView?.contentMode = .scaleAspectFit
        locationButton.semanticContentAttribute = .forceLeftToRight
        locationButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: -5)
        noDealsView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
        loadData()
        NotificationCenter.default.addObserver(self, selector: #selector(locationDidChangedNotification), name: .locationDidChanged, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .locationDidChanged, object: nil)
    }
    
    func setupCollectionView() {
        refreshControl.backgroundColor = UIColor(named: "searchBg")
        refreshControl.tintColor = .clear
        let refreshImageView = UIImageView(image: UIImage(named: "refresh_logo"))
        refreshImageView.contentMode = .scaleAspectFit
        refreshImageView.frame = CGRect(x: 0, y: 0, width: 39, height: 32)
        refreshControl.addSubview(refreshImageView)
        refreshImageView.center = CGPoint(x: refreshControl.bounds.midX, y: refreshControl.bounds.midY)
        refreshImageView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        if let layout = collectionView?.collectionViewLayout as? CustomLayout {
            layout.delegate = self
        }
        
        collectionView.contentInset = .zero
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "DealCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "DealCollectionViewCell")
    }
    
    func updateUI() {
        if let address = LocationTrakingManager.shared.lastLocation?.address {
            locationButton.setTitle(address, for: .normal)
        } else {
            locationButton.setTitle("Unknown location", for: .normal)
        }
    }
    
    func loadData() {
        noDealsView.isHidden = true
        if collectionData.isEmpty {
            collectionView.startActivityAnimating()
        }
        
        FirestoreManager.shared.fetchDeals(for: LocationTrakingManager.shared.lastLocation?.location, enableOnline: true) { [weak self] data in
            guard let self = self else { return }
            
            self.collectionView.stopActivityAnimating()
            self.fetchedDeals = data
            self.updateData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.refreshControl.endRefreshing()
            }
        }
        
        UserManager.shared.updateBookmarks { [weak self] in
            self?.collectionView.reloadData()
        }
    }
    
    func updateData() {
        let allDeals = fetchedDeals ?? []
        if searchText.isEmpty {
            collectionData = allDeals
        } else {
            collectionData = allDeals.filter { $0.promotion.lowercased().contains(searchText.lowercased())}
        }
        
        let layout = collectionView?.collectionViewLayout as? CustomLayout
        layout?.reset()
        collectionView.reloadData()
        noDealsView.isHidden = !collectionData.isEmpty
    }
    
    func bookmarkActionHandler(deal: DealItem) {
        collectionView.startActivityAnimating()
        let tBookmarks = UserManager.shared.bookmarks
        var shouldBookmark: Bool = false
        let index = UserManager.shared.bookmarks.firstIndex(of: deal.documentId)
        
        if index != nil {
            UserManager.shared.bookmarks.remove(at: index!)
        } else {
            UserManager.shared.bookmarks.append(deal.documentId)
            shouldBookmark = true
        }
        
        collectionView.reloadData()
        FirestoreManager.shared.updateCustomerBookmarks(dealId: deal.documentId, isOn: shouldBookmark) { [weak self] error in
            guard let self = self else { return }
            
            self.collectionView.stopActivityAnimating()
            if let error = error {
                self.showAlert(message: error)
                UserManager.shared.bookmarks = tBookmarks
                self.collectionView.reloadData()
            }
        }
    }
    
    func showAuth() {
        Coordinator.navigateToAuth(from: self,
            isBusinessOwner: false,
            dismissCompletion: { [weak self] in
            self?.loadData()
            },
            modally: true)
    }
    
    @objc private func refreshData(_ sender: Any) {
        loadData()
    }
    
    @objc func locationDidChangedNotification(notification: Notification) {
        updateUI()
        loadData()
    }
    
    @IBAction func didTapLocationButton(_ sender: Any) {
        let vc = Coordinator.instantiateChooseLocationVC()
        Coordinator.navigateTo(vc, from: self, modally: true, fullScreen: false)
    }
}

extension ExploreViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DealCollectionViewCell", for: indexPath) as! DealCollectionViewCell
        let deal = collectionData[indexPath.row]
        let isBookmarked = UserManager.shared.bookmarks.contains(deal.documentId)
        cell.configureWith(data: deal, cellWidth: cellWidht, isBookmarked: isBookmarked)
        
        cell.onBookmarkAction = { [weak self] in
            guard let self = self else { return }
            guard isRegularProfile else { return showAuth() }
            guard let ip = collectionView.indexPath(for: cell) else { return }

            bookmarkActionHandler(deal: collectionData[ip.row])
        }
        
        cell.onOptionsAction = { [weak self] in
            guard let self = self else { return }
            guard isRegularProfile else { return showAuth() }
            guard let ip = collectionView.indexPath(for: cell) else { return }
            
            showReportAndShareOptions(deal: collectionData[ip.row])
        }
        cell.onRateAction = { [weak self] in
            guard let self = self else { return }
            guard isRegularProfile else { return showAuth() }
            guard let ip = collectionView.indexPath(for: cell) else { return }

            let deal = collectionData[ip.row]
            showRateDeal(deal) { [weak self] error in
                guard let self = self else { return }
                guard error == nil else {
                    showAlert(message: error!, title: "Rate error")
                    return
                }
                
                let fetchAndUpdateBlock = {
                    FirestoreManager.shared.fetchDeals(ids: [deal.documentId]) { [weak self] data in
                        guard let self = self else { return }
                        
                        if let result = data.first, let index = (fetchedDeals ?? []).firstIndex(where: { $0.documentId == deal.documentId } ) {
                            fetchedDeals?[index] = result
                            updateData()
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
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = Coordinator.instantiateDealDetailsVC()
        vc.deal = collectionData[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ExploreViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellHeight = DealCollectionViewCell.cellHeightForItem(deal: collectionData[indexPath.row], constrainedWidth: cellWidht)
        return CGSize(width: cellWidht, height: cellHeight)
    }
}

extension ExploreViewController: CustomLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath:IndexPath) -> CGFloat {
        return  DealCollectionViewCell.cellHeightForItem(deal: collectionData[indexPath.row], constrainedWidth: cellWidht)
    }
}
