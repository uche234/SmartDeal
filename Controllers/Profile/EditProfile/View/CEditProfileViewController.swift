//
//  EditProfileViewController.swift
//  Dilblitz
//
//  Created by ОК on 19.12.2021.
//

import UIKit

class CEditProfileViewController: UIViewController {
    
    @IBOutlet weak var profileView: ProfileView!
    @IBOutlet weak var bgView: RoundedViewWithShadow!
    @IBOutlet weak var firstNameInputView: InputView!
    @IBOutlet weak var surnameInputView: InputView!
    @IBOutlet weak var emailInputView: ProfileInputView!
    @IBOutlet weak var ageInputView: ProfileInputView!
    @IBOutlet weak var genderInputView: ProfileInputView!
    @IBOutlet weak var saveButton: UIButton!
    
    var avatarWasChanged: Bool = false
    var tmpProfile: Profile! {
        didSet {
            profileView.configureWith(profile: tmpProfile)
        }
    }
    private let datePicker = UIDatePicker()
    private let genderPickerView = UIPickerView()
    private var genders: [Gender] {
        return Gender.allCases
    }
    
    var validSurname: String {
        return surnameInputView.textFieldText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tmpProfile = UserManager.shared.profile!
        setupUI()
    }
    
    func setupUI() {
        saveButton.layer.cornerRadius = 0.5 * saveButton.bounds.height
        
        profileView.onEditImageAction = { [weak self] in
            self?.editAvatar()
        }
        
        profileView.configureWith(profile: tmpProfile)
        
        bgView.cornerRadius = 15
        bgView.shadowOffsetWidth = 0
        bgView.shadowRadius = 6
        bgView.shadowOpacity = 0.3
        
        firstNameInputView.icon = UIImage(named: "user")
        firstNameInputView.placeholder = "First Name"
        firstNameInputView.textField.autocapitalizationType = .words
        firstNameInputView.delegate = self
        firstNameInputView.textFieldText = tmpProfile.firstname

        surnameInputView.icon = UIImage(named: "user")
        surnameInputView.placeholder = "Surname"
        surnameInputView.textField.autocapitalizationType = .words
        surnameInputView.delegate = self
        surnameInputView.textFieldText = tmpProfile.surname
        
        emailInputView.titleLabel.text = "Email Address"
        emailInputView.iconImageView.image = UIImage(named: "email")
        emailInputView.isUserInteractionEnabled = false
        emailInputView.text = tmpProfile.email
        
        ageInputView.titleLabel.text = "Age"
        ageInputView.iconImageView.image = UIImage(named: "calendar")
        ageInputView.chevronDownIcon.isHidden = false
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Utils.minAgeDate(years: (tmpProfile?.isBusinessOwner ?? false) ? 18 : 12)
        ageInputView.textField.inputView = datePicker
        do {
            let toolBar = UIToolbar()
            toolBar.sizeToFit()
            let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.agePickerDoneAction))
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.agePickerCancelAction))
            toolBar.setItems([cancelButton, flexibleSpace, doneButton], animated: false)
            toolBar.isUserInteractionEnabled = true
            ageInputView.textField.inputAccessoryView = toolBar
        }
        
        genderInputView.titleLabel.text = "Gender"
        genderInputView.iconImageView.image = UIImage(named: "gender")
        genderInputView.chevronDownIcon.isHidden = false
        genderPickerView.dataSource = self
        genderPickerView.delegate = self
        genderInputView.textField.inputView = genderPickerView
        do {
            let toolBar = UIToolbar()
            toolBar.sizeToFit()
            let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.genderPickerDoneAction))
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.genderPickerCancelAction))
            toolBar.setItems([cancelButton, flexibleSpace, doneButton], animated: false)
            toolBar.isUserInteractionEnabled = true
            genderInputView.textField.inputAccessoryView = toolBar
        }
        
        ageInputView.textField.text = tmpProfile.birthDate != nil ? "\(tmpProfile.birthDate!.ddmmyyyString)" : ""
        if let birthDate = tmpProfile.birthDate {
            datePicker.date = birthDate
        }
        genderInputView.textField.text = tmpProfile.gender?.name ?? ""
        if let gender = tmpProfile.gender, let index = genders.firstIndex(where: { $0 == gender }) {
            genderPickerView.selectRow(index, inComponent: 0, animated: false)
        }
    }
    
    func updateProfileAndUploadData() {
        var isChanged: Bool = false
        
        let originalProfile = UserManager.shared.profile!
        
        if originalProfile.businessName != tmpProfile.businessName {
            isChanged = true
        }
        
        if originalProfile.displayName != tmpProfile.displayName {
            isChanged = true
        }
        
        if originalProfile.birthDate != tmpProfile.birthDate {
            isChanged = true
        }
        
        if originalProfile.gender != tmpProfile.gender {
            isChanged = true
        }
        
        if avatarWasChanged {
            isChanged = true
        }
        
        if isChanged {
            if avatarWasChanged {
                avatarWasChanged = false
                FirestoreManager.shared.uploadImage(profileView.imageView.image ?? UIImage(), profileId: tmpProfile.uid) { url in
                    self.tmpProfile.avatarUrl = url
                    UserManager.shared.profile = self.tmpProfile
                    FirestoreManager.shared.setProfile(self.tmpProfile) { _ in }
                }
            } else {
                UserManager.shared.profile = tmpProfile
                FirestoreManager.shared.setProfile(tmpProfile) { _ in }
            }
        }
    }
    
    func editAvatar() {
        let title = "Choose avatar image"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title:"Camera", style: .default , handler:{ (UIAlertAction)in
            self.getImage(fromSourceType: .camera)
        }))
        
        alert.addAction(UIAlertAction(title: "Photo Album", style: .default , handler:{ (UIAlertAction)in
            self.getImage(fromSourceType: .photoLibrary)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction) in }))
        
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
            addActionSheetForiPad(actionSheet: alert)
        }
        
        self.present(alert, animated: true, completion: {})
    }
    
    func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = sourceType
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveButtonPressed() {
        updateProfileAndUploadData()
        navigationController?.popViewController(animated: true)
    }
    
    @objc func agePickerDoneAction() {
        ageInputView.textField.resignFirstResponder()
        tmpProfile.birthDate = datePicker.date
        ageInputView.text = datePicker.date.ddmmyyyString
    }
    
    @objc func agePickerCancelAction() {
        ageInputView.textField.resignFirstResponder()
    }
    
    @objc func genderPickerDoneAction() {
        genderInputView.textField.resignFirstResponder()
        
        tmpProfile.gender = genders[genderPickerView.selectedRow(inComponent: 0)]
        genderInputView.text = tmpProfile.gender?.name ?? ""
    }
    
    @objc func genderPickerCancelAction() {
        genderInputView.textField.resignFirstResponder()
    }
}

extension CEditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            avatarWasChanged = true
            profileView.imageView.image = image.updateSizeAndImageOrientionUpSide(maxSize: 300)
        }
        dismiss(animated: true, completion: nil)
    }
}

extension CEditProfileViewController: InputViewDelegate {
    func inputView(_ sender: InputView, didChangeText text: String) {
        if sender == firstNameInputView {
            tmpProfile.firstname = text
        } else if sender == surnameInputView {
            tmpProfile.surname = text
        }
    }
}

extension CEditProfileViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return genders.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genders[row].name
    }
    
}
