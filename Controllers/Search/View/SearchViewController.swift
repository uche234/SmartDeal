//
//  SearchViewController.swift
//  Dilblitz
//
//  Created by ОК on 02.05.2021.
//

import UIKit

class SearchViewController: UIViewController {
    
    @IBOutlet weak var searchBar: SearchBar!
    @IBOutlet weak var addressCompleterView: AddressCompleterView!
    @IBOutlet weak var categoriesCollectionView: UICollectionView!
    @IBOutlet weak var dealsCollectionView: UICollectionView!
    @IBOutlet weak var mapOrListButton: UIButton!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var activityIndicatorContainer: UIView!
    @IBOutlet weak var noDealsView: NoDealsView!
    
    let dealCellWidth = UIScreen.main.bounds.width - 34.0
    
    var searchMapViewController: SearchMapViewController?
    var addressCompleterLastSelectedResult: SearchAddressResult?
    var categories: [DealCategory] = []
    var selectedLocation: DBLocation?
    var allDeals: [DealItem]?

    var isMapMode: Bool = false {
        didSet {
            if isMapMode {
                dealsCollectionView.isHidden = true
                mapContainerView.isHidden = false
                mapOrListButton.setTitle("List", for: .normal)
                mapOrListButton.setImage(UIImage(named: "list"), for: .normal)
                searchMapViewController?.updateDeals(tableData)
                noDealsView.backgroundColor = .white
            } else {
                dealsCollectionView.isHidden = false
                mapContainerView.isHidden = true
                mapOrListButton.setTitle("Map", for: .normal)
                mapOrListButton.setImage(UIImage(named: "map"), for: .normal)
                noDealsView.backgroundColor = .clear
            }
            reloadTableOrMap()
        }
    }
    
    var selectedCategory: DealCategory? {
        didSet {
            categoriesCollectionView.reloadData()
        }
    }
    
    var tableData: [DealItem] = [] {
        didSet {
            reloadTableOrMap()
        }
    }
    
    var isRegularProfile: Bool {
        return UserManager.shared.profile?.type == .customer
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addressCompleterView.backgroundColor = .white.withAlphaComponent(0.6)
        addressCompleterView.maxRows = 4
        addressCompleterView.tableView.isScrollEnabled = true
        addressCompleterView.tableView.showsVerticalScrollIndicator = true
        addressCompleterView.onChangedHeight = { [weak self] in
            UIView.animate(withDuration: 0.1) {
                self?.view.layoutIfNeeded()
            }
        }
        addressCompleterView.onAddressSelected = { [weak self] searchResult in
            guard let self = self else { return }
            
            self.addressCompleterLastSelectedResult = searchResult
            self.addressCompleterView.cancelSearch()
            self.searchBar.textField.text = searchResult.title
            self.searchBar.textField.resignFirstResponder()
        }
        isMapMode = false
        noDealsView.isHidden = true
        mapOrListButton.layer.cornerRadius = 0.5 * mapOrListButton.bounds.height
        setupCategoriesCollectionView()
        setupDealsCollectionView()
        searchBar.onSearch = { [weak self] searchText in
            self?.addressCompleterView.searchForText(searchText)
        }
        searchBar.onStartEditing = { [weak self] in
            guard let self = self else { return }
            self.selectedCategory = nil
            self.addressCompleterView.searchForText(self.searchBar.searchText)
        }
        searchBar.onEndEditing = { [weak self] in
            guard let self = self else { return }
            
            self.addressCompleterView.cancelSearch()
            self.reloadTableOrMap()
            self.loadDeals()
        }
        locationButton.setImage(UIImage(named: "placemark_white"), for: .normal)
        locationButton.titleLabel?.numberOfLines = 2
        locationButton.titleLabel?.textAlignment = .center
        locationButton.imageView?.contentMode = .scaleAspectFit
        locationButton.semanticContentAttribute = .forceLeftToRight
        locationButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: -5)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadTableOrMap()
        updateUI()
        if categories.isEmpty {
            loadCategories()
        }
        loadDeals()

        NotificationCenter.default.addObserver(self, selector: #selector(locationDidChangedNotification), name: .locationDidChanged, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .locationDidChanged, object: nil)
    }
    
    func setupCategoriesCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        categoriesCollectionView.collectionViewLayout = flowLayout
        categoriesCollectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        categoriesCollectionView.delegate = self
        categoriesCollectionView.dataSource = self
        categoriesCollectionView.register(UINib(nibName: "CategoryCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "CategoryCollectionViewCell")
    }
    
    func setupDealsCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 17
        flowLayout.minimumInteritemSpacing = 0
        dealsCollectionView.collectionViewLayout = flowLayout
        dealsCollectionView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        dealsCollectionView.delegate = self
        dealsCollectionView.dataSource = self
        dealsCollectionView.register(UINib(nibName: "DealCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "DealCollectionViewCell")
    }
    
    func updateUI() {
        if selectedLocation == nil {
            if let location = LocationTrakingManager.shared.lastLocation {
                locationButton.setTitle(location.address, for: .normal)
            } else {
                locationButton.setTitle("Unknown location", for: .normal)
            }
        } else {
            locationButton.setTitle("Reset location", for: .normal)
        }
    }
    
    func loadDeals() {
        noDealsView.isHidden = true
        if tableData.isEmpty {
            activityIndicatorContainer.startActivityAnimating()
        }
        FirestoreManager.shared.fetchDeals { [unowned self] deals in
            self.activityIndicatorContainer.stopActivityAnimating()
            self.allDeals = deals?.filter { $0.approved }
            self.filterDeals()
        }
    }
    
    func filterDeals() {
        UserManager.shared.updateBookmarks { [weak self] in
            guard let self = self else { return }
            
            if let category = self.selectedCategory {
                self.fetchDeals(category: category)
            } else if !self.searchBar.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                self.filterDealsBy(text: self.searchBar.searchText)
            } else {
                self.tableData = self.filterDealsBy(location: LocationTrakingManager.shared.lastLocation?.location, enableOnline: true)
                self.noDealsView.isHidden = !self.tableData.isEmpty
            }
        }
    }
    
    func filterDealsBy(text: String) {
        var mAddress = text
        var textMatch = self.allDeals?.filter({ item in
            return item.promotion.contains(text) || item.about.contains(text) || text.contains(item.promotion) || text.contains(item.about)
        }) ?? []
        
        if let addressCompleterResult = addressCompleterLastSelectedResult, text.contains(addressCompleterResult.title), let subtitle = addressCompleterResult.subtitle {
            mAddress = "\(text), \(subtitle)"
            
            LocationTrakingManager.shared.getLocationFromAddress(mAddress) { location in
                self.selectedLocation = location
                self.updateUI()
                let deals = self.filterDealsBy(location: location, enableOnline: false)
                textMatch.append(contentsOf: deals)
                self.tableData = textMatch
                self.noDealsView.isHidden = !self.tableData.isEmpty
            }
        } else {
            tableData = textMatch
            noDealsView.isHidden = !tableData.isEmpty
        }
    }
    
    func filterDealsBy(location: DBLocation?, enableOnline: Bool) -> [DealItem] {
        return allDeals?.filter({ item in
            var result = false
            
            if let location = location, let compare = item.location {
                result = compare.latitude > location.region.minLat &&
                compare.longitude > location.region.minLon &&
                compare.latitude < location.region.maxLat &&
                compare.longitude < location.region.maxLon
            }
            
            return result || (enableOnline && item.isOnlineStore)
        }) ?? []
    }
    
    func fetchDeals(category: DealCategory) {
        FirestoreManager.shared.fetchDeals(categoryId: category.documentId) { [weak self] data in
            guard let self = self else { return }

            self.activityIndicatorContainer.stopActivityAnimating()
            self.tableData = (data ?? []).filter { $0.approved }
            self.noDealsView.isHidden = !self.tableData.isEmpty
        }
    }
    
    func loadCategories() {
        FirestoreManager.shared.fetchCategories { [weak self] data in
            self?.categories = data ?? []
            self?.categoriesCollectionView.reloadData()
        }
    }
    
    func reloadTableOrMap() {
        if isMapMode {
            searchMapViewController?.updateDeals(tableData)
        } else {
            dealsCollectionView.reloadData()
        }
    }
    
    func bookmarkActionHandler(deal: DealItem) {
        dealsCollectionView.startActivityAnimating()
        let tBookmarks = UserManager.shared.bookmarks
        var shouldBookmark: Bool = false
        let index = UserManager.shared.bookmarks.firstIndex(of: deal.documentId)
        
        if index != nil {
            UserManager.shared.bookmarks.remove(at: index!)
        } else {
            UserManager.shared.bookmarks.append(deal.documentId)
            shouldBookmark = true
        }
        
        dealsCollectionView.reloadData()
        FirestoreManager.shared.updateCustomerBookmarks(dealId: deal.documentId, isOn: shouldBookmark) { [weak self] error in
            guard let self = self else { return }
            
            self.dealsCollectionView.stopActivityAnimating()
            if let error = error {
                self.showAlert(message: error)
                UserManager.shared.bookmarks = tBookmarks
                self.dealsCollectionView.reloadData()
            }
        }
    }
    
    func showAuth() {
        Coordinator.navigateToAuth(from: self,
            isBusinessOwner: false,
            dismissCompletion: { [weak self] in
                guard let self = self else { return }
            
                reloadTableOrMap()
                updateUI()
                if categories.isEmpty {
                    loadCategories()
                }
                loadDeals()
            },
            modally: true)
    }
    
    private func showDealDetails(_ deal: DealItem) {
        let vc = Coordinator.instantiateDealDetailsVC()
        vc.deal = deal
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func mapListButtonPressed(_ sender: Any) {
        isMapMode.toggle()
    }
    
    @IBAction func resetLocationButtonPressed(_ sender: Any) {
        let vc = Coordinator.instantiateChooseLocationVC()
        Coordinator.navigateTo(vc, from: self, modally: true, fullScreen: false)
    }
    
    @objc func locationDidChangedNotification(notification: Notification) {
        selectedLocation = nil
        updateUI()
        if searchBar.searchText.isEmpty, selectedCategory == nil {
            loadDeals()
        }
    }
    
    //MARK: Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SearchMapViewController {
            vc.onShowDealDetails = { [weak self] deal in
                self?.showDealDetails(deal)
            }
            searchMapViewController = vc
        }
    }
}

extension SearchViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //CATEGORIES
        if collectionView == categoriesCollectionView {
            return categories.count
        }
        
        //DEALS
        return tableData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //CATEGORIES
        if collectionView == categoriesCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCollectionViewCell", for: indexPath) as! CategoryCollectionViewCell
            let isSelected = categories[indexPath.row].documentId == selectedCategory?.documentId
            cell.configureWith(data: categories[indexPath.row], isSelected: isSelected)
            return cell
        }
        
        //DEALS
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DealCollectionViewCell", for: indexPath) as! DealCollectionViewCell
        let deal = tableData[indexPath.row]
        let isBookmarked = UserManager.shared.bookmarks.contains(deal.documentId)
        cell.configureWith(data: deal, cellWidth: dealCellWidth, isBookmarked: isBookmarked)
        cell.onBookmarkAction = { [weak self] in
            guard let self = self else { return }
            guard isRegularProfile else { return showAuth() }
            guard let ip = self.dealsCollectionView.indexPath(for: cell) else { return }
            
            self.bookmarkActionHandler(deal: self.tableData[ip.row])
        }
        
        cell.onRateAction = { [weak self] in
            guard let self = self else { return }
            guard isRegularProfile else { return showAuth() }
            guard let ip = self.dealsCollectionView.indexPath(for: cell) else { return }

            self.showRateDeal(self.tableData[ip.row]) { [weak self] error in
                guard let self = self else { return }
                guard error == nil else {
                    showAlert(message: error!, title: "Rate error")
                    return
                }

                let fetchAndUpdateBlock = {
                    FirestoreManager.shared.fetchDeals(ids: [deal.documentId]) { [weak self] data in
                        guard let self = self else { return }
                        
                        if let result = data.first, let index = self.tableData.firstIndex(where: { $0.documentId == deal.documentId } ) { 
                            self.tableData[index] = result
                            self.reloadTableOrMap()
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
        
        cell.onOptionsAction = { [weak self] in
            guard let self = self else { return }
            guard isRegularProfile else { return showAuth() }
            guard let ip = self.dealsCollectionView.indexPath(for: cell) else { return }

            self.showReportAndShareOptions(deal: self.tableData[ip.row])
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //CATEGORIES
        if collectionView == categoriesCollectionView {
            guard !searchBar.textField.isFirstResponder else { return }
            
            if categories[indexPath.row].documentId == selectedCategory?.documentId {
                selectedCategory = nil
            } else {
                searchBar.searchText = ""
                selectedLocation = nil
                updateUI()
                selectedCategory = categories[indexPath.row]
            }
            updateUI()
            tableData = []
            loadDeals()
            return
        }
        
        //DEALS
        showDealDetails(tableData[indexPath.row])
    }
}

extension SearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //CATEGORIES
        if collectionView == categoriesCollectionView {
            return CGSize(width: 100, height: 82)
        }
        
        //DEALS
        let cellHeight = DealCollectionViewCell.cellHeightForItem(deal: tableData[indexPath.row], constrainedWidth: dealCellWidth)
        return CGSize(width: dealCellWidth, height: cellHeight)
    }
}
