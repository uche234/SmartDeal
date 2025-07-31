//
//  OnboardingViewController.swift
//  Lend
//
//  Created by ОК on 06.01.2021.
//

import UIKit
import CHIPageControl

class OnboardingViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var customPageControl: CHIPageControlAji!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    
    var collectionData: [OnboardingModel] = []
    var currentPageIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        customPageControl.radius = 3.5
        setupData()
        setupCollectionView()
    }
    
    func setupData() {
        let page_1 = OnboardingModel(image: UIImage(named: "onboarding 1"),
                                     imageInsets: UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 60),
                                     title: "Stay up to date with the latest deals in your area")
        
        let page_2 = OnboardingModel(image: UIImage(named: "onboarding 2"),
                                     imageInsets: UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 60),
                                     title: "Save and share your favorite deals with friends")
        
        let page_3 = OnboardingModel(image: UIImage(named: "onboarding 3"),
                                     imageInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20),
                                     title: "You are ready to start finding great deals!")
        
        collectionData = [page_1, page_2, page_3]
    }

    func setupCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = flowLayout
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.isPagingEnabled = true
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(UINib(nibName: "OnboardingCell", bundle: nil), forCellWithReuseIdentifier: "OnboardingCell")
    }
    
    func navigateToChooseAccountType() {
        Coordinator.navigateTo(storyboard: "ChooseAccountTypeViewController", from: self, modally: true)
    }
    
    func toggleShowBackButton(show: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.backButton.alpha = show ? 1 : 0
        }
    }
    
    @IBAction func didTapNextButton() {
        if let currentIndex = collectionView.indexPathsForVisibleItems.first {
            if currentIndex.row < collectionData.count - 1 {
                let newIndex = IndexPath(row: currentIndex.row + 1, section: currentIndex.section)
                collectionView.scrollToItem(at: newIndex, at: .centeredHorizontally, animated: true)
            } else {
                navigateToChooseAccountType()
            }
            if currentIndex.row == 0 {
                toggleShowBackButton(show: true)
            }
        }
    }
    
    @IBAction func didTapSkipButton() {
        navigateToChooseAccountType()
    }
    
    @IBAction func didTapBackButton() {
        if let currentIndex = collectionView.indexPathsForVisibleItems.first {
            if currentIndex.row > 0 {
                let newIndex = IndexPath(row: currentIndex.row - 1, section: currentIndex.section)
                collectionView.scrollToItem(at: newIndex, at: .centeredHorizontally, animated: true)
            }
            if currentIndex.row == 1 {
                toggleShowBackButton(show: false)
            }
        }
    }
}

extension OnboardingViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OnboardingCell", for: indexPath) as! OnboardingCell
        cell.configureWith(data: collectionData[indexPath.row])
        
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let center = CGPoint(x: collectionView.contentOffset.x + (collectionView.frame.width / 2), y: (collectionView.frame.height / 2))
        if let indexPath = collectionView.indexPathForItem(at: center) {
            currentPageIndex = indexPath.row
            toggleShowBackButton(show: indexPath.row > 0)
        }
        
        customPageControl.progress = Double(currentPageIndex)
    }
}

extension OnboardingViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
