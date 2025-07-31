//
//  AuthViewController.swift
//  Dilblitz
//
//  Created by ОК on 14.04.2021.
//

import UIKit
import FBSDKLoginKit
import GoogleSignIn
import Firebase
import CryptoKit
import AuthenticationServices

class AuthViewController: UIViewController {
    
    @IBOutlet weak var inputsContainer: RoundedViewWithShadow!
    @IBOutlet weak var segmentedControl: CustomSegmentedControl!
    @IBOutlet weak var firstNameInputView: InputView!
    @IBOutlet weak var surnameInputView: InputView!
    @IBOutlet weak var emailInputView: InputView!
    @IBOutlet weak var ageInputView: InputView!
    @IBOutlet weak var genderInputView: InputView!
    @IBOutlet weak var passwordInputView: InputView!
    @IBOutlet weak var confirmPasswordInputView: InputView!
    @IBOutlet weak var continueButtonContainer: RoundedViewWithShadow!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var accountTypeButton: UIButton!
    @IBOutlet weak var loginOrSignUpLabel: UILabel!
    @IBOutlet weak var forgotPasswordContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var authButtonsStackView: UIStackView!
    @IBOutlet weak var rememberButton: UIButton!
    @IBOutlet weak var rememberIconButton: UIButton!
    @IBOutlet weak var guestAuthButton: UIButton!
    
    @IBOutlet weak var termsAndPrivacyTextView: LinksTextView!
    @IBOutlet weak var logoTop: NSLayoutConstraint!
    @IBOutlet weak var bgImageAspect: NSLayoutConstraint!
    
    @IBOutlet weak var mainContainerTop: NSLayoutConstraint!
    @IBOutlet weak var mainContainerBottom: NSLayoutConstraint!
    
    private let datePicker = UIDatePicker()
    private let genderPickerView = UIPickerView()
    
    private var genders: [Gender] {
        return Gender.allCases
    }
    
    var isBusinessOwner: Bool = false
    var dismissCompletion: (() -> Void)?
    
    var isEmailVerified: Bool {
        return FirestoreManager.shared.currentUser?.isEmailVerified ?? false
    }
    
    var storedEmail: String? {
        return Settings.getEmail(isBusinessOwner: isBusinessOwner)
    }
    
    var isRememberMeChecked: Bool {
        return storedEmail != nil
    }
    
    var isLogin = true {
        didSet {
            updateInitialLoginSignUpState()
            updateUI()
        }
    }
    
    var email: String {
        return emailInputView.textFieldText
    }
    
    var password: String {
        return passwordInputView.textFieldText
    }
    
    var selectedGender: Gender?
    var selectedAge: Date?
    
    var confirmPassword: String {
        return confirmPasswordInputView.textFieldText
    }
    
    var validFirstname: String {
        return firstNameInputView.textFieldText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var validSurname: String {
        return surnameInputView.textFieldText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    fileprivate var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.items = ["LOGIN", "SIGN UP"]
        segmentedControl.onIndexSelected = { [weak self] index in
            self?.isLogin = index == 0
        }
        loginButton.layer.cornerRadius = 0.5 * loginButton.bounds.height
        setupRoundedView(inputsContainer)
        setupRoundedView(continueButtonContainer, radius: 0.5 * continueButtonContainer.bounds.height)
        setupInputViews()
        updateInitialLoginSignUpState()
        updateUI()
        
        termsAndPrivacyTextView.configure(fullText: "By continuing, you agree to Dilblitz's Terms of Service\nand acknowledge Dilblitz's Privacy Policy.",
            termsText: "Terms of Service",
            privacyText: "Privacy Policy.",
            termsHandler: { [weak self] in
                if let url = URL(string: Constants.Link.terms) {
                    self?.open(url: url)
                }
            }, privacyHandler: { [weak self] in
                if let url = URL(string: Constants.Link.privacy) {
                    self?.open(url: url)
                }
        })
        termsAndPrivacyTextView.textAlignment = .center
        
        logoTop.constant = Utils.safeAreaInsets.top
        let mainContainerHeight: CGFloat = 575//from storyboard
        let mainContainerAndBgImageHeight: CGFloat = mainContainerHeight - 50 + UIScreen.main.bounds.width * bgImageAspect.constant + Utils.safeAreaInsets.bottom
        let minOffset: CGFloat = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ? 400 : 226
        let topOffset = min(minOffset, UIScreen.main.bounds.height - mainContainerAndBgImageHeight)
        mainContainerTop.constant = topOffset
        mainContainerBottom.constant = Utils.safeAreaInsets.bottom
    }
    
    private func setupInputViews() {
        firstNameInputView.icon = UIImage(named: "user")
        firstNameInputView.placeholder = "First Name"
        firstNameInputView.textField.autocapitalizationType = .words
        surnameInputView.placeholder = "Surname"
        surnameInputView.textField.autocapitalizationType = .words
        ageInputView.icon = UIImage(named: "calendar")
        ageInputView.placeholder = "Age"
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Utils.minAgeDate(years: isBusinessOwner ? 18 : 12)
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
        genderInputView.icon = UIImage(named: "gender")
        genderInputView.placeholder = "Gender"
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
        
        emailInputView.icon = UIImage(named: "email")
        emailInputView.placeholder = "Email Address"
        emailInputView.textField.keyboardType = .emailAddress
        emailInputView.delegate = self
        passwordInputView.icon = UIImage(named: "lock")
        passwordInputView.placeholder = "Password"
        passwordInputView.isSecureTextEntry = true
        confirmPasswordInputView.icon = UIImage(named: "lock")
        confirmPasswordInputView.placeholder = "Confirm Password"
        confirmPasswordInputView.isSecureTextEntry = true
    }
    
    private func setupRoundedView(_ rView: RoundedViewWithShadow, radius: CGFloat? = nil) {
        rView.cornerRadius = radius ?? 15.0
        rView.shadowOffsetWidth = 0
        rView.shadowOpacity = 0.2
    }
    
    private func updateInitialLoginSignUpState() {
        if isLogin {
            emailInputView.textFieldText = storedEmail ?? ""
        } else {
            emailInputView.textFieldText = ""
        }
        
        firstNameInputView.textFieldText = ""
        surnameInputView.textFieldText = ""
        passwordInputView.textFieldText = ""
        confirmPasswordInputView.textFieldText = ""
    }
    
    private func updateUI() {
        accountTypeButton.setTitle(isBusinessOwner ? "I'm a customer" : "I'm a business owner", for: .normal)
        loginOrSignUpLabel.isHidden = isBusinessOwner
        authButtonsStackView.isHidden = isBusinessOwner
        guestAuthButton.isHidden = isBusinessOwner
        
        if isLogin {
            loginButton.setTitle("Login", for: .normal)
            loginOrSignUpLabel.text = "Login with"
            firstNameInputView.isHidden = true
            surnameInputView.isHidden = true
            confirmPasswordInputView.isHidden = true
            ageInputView.isHidden = true
            genderInputView.isHidden = true
            forgotPasswordContainerHeight.constant = 44
            if isRememberMeChecked {
                rememberIconButton.setImage(UIImage(systemName: "checkmark.square"), for: .normal)
            } else {
                rememberIconButton.setImage(UIImage(systemName: "square"), for: .normal)
            }
        } else {
            loginButton.setTitle("Sign Up", for: .normal)
            loginOrSignUpLabel.text = "Sign Up with"
            firstNameInputView.isHidden = false
            surnameInputView.isHidden = false
            ageInputView.isHidden = false
            genderInputView.isHidden = false
            confirmPasswordInputView.isHidden = false
            forgotPasswordContainerHeight.constant = 0
        }
    }
    
    @IBAction func didTapLoginButton(_ sender: Any) {
        guard Validator.isEmailValid(email) else {
            self.showAlert(message: Constants.Error.emailInputError)
            return
        }
        
        guard Validator.isPasswordValid(password) else {
            self.showAlert(message: Constants.Error.passwordInputError)
            return
        }
        
        if !isLogin {
            guard password == confirmPassword else  {
                self.showAlert(message: Constants.Error.passwordIsNotTheSame)
                return
            }
        }
        
        view.endEditing(true)
        
        if isLogin {
            login()
        } else {
            signUp()
        }
    }
    
    private func login() {
        view.startActivityAnimating()
        if let profile = UserManager.shared.profile, profile.type == .guest {
            FirestoreManager.shared.deleteAccount()
        }
        
        FirestoreManager.shared.login(type: isBusinessOwner ? .business : .customer, email: email, password: password) { [weak self] reverse, error in
            guard let self = self else { return }
            
            if reverse {
                isBusinessOwner = !isBusinessOwner
            }
            view.stopActivityAnimating()
            guard error == nil else {
                showAlert(message: error!)
                return
            }
            
            if isEmailVerified {
                navigateToAuthorizedRoot()
                MessagingManager.shared.updateManualyIsSubscribed(true)
            } else {
                navigateToCheckEmail(email: email)
            }
        }
    }
    
    private func signUp() {
        view.startActivityAnimating()
        if let profile = UserManager.shared.profile, profile.type == .guest {
            FirestoreManager.shared.deleteAccount()
        }
        
        FirestoreManager.shared.signUp(type: isBusinessOwner ? .business : .customer, email: email, password: password, firstname: validFirstname, surname: validSurname, birthDate: selectedAge, gender: selectedGender) { [weak self] error in
            guard let self = self else { return }
            
            view.stopActivityAnimating()
            guard error == nil else {
                showAlert(message: error!)
                return
            }
            if isBusinessOwner {
                Settings.shouldOpenBusinessProfile = true
            }
            
            if isEmailVerified {
                navigateToAuthorizedRoot()
                MessagingManager.shared.updateManualyIsSubscribed(true)
            } else {
                navigateToCheckEmail(email: email)
            }
        }
    }
    
    private func navigateToCheckEmail(email: String) {
        print("AuthViewController :: navigateToCheckEmail: \(Thread.callStackSymbols)")
        let vc = Storyboard.CheckEmail.instantiate() as! CheckEmailViewController
        vc.email = email
        vc.isBusinessOwner = isBusinessOwner
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToAuthorizedRoot() {
        if dismissCompletion != nil {
            dismiss(animated: true)
            dismissCompletion?()
        } else if self.isBusinessOwner {
            Coordinator.setRootViewController(BRootTabBarViewController())
        } else {
            Coordinator.setRootViewController(CRootTabBarViewController())
        }
    }
    
    //MARK: - Facebook
    
    func removeFbData() {
        let fbManager = LoginManager()
        fbManager.logOut()
        AccessToken.current = nil
    }
    
    func loginWithCredential(_ credential:  AuthCredential) {
        self.view.startActivityAnimating()
        FirestoreManager.shared.login(type: self.isBusinessOwner ? .business : .customer, credential: credential, completion: { [weak self] reverse, error in
            guard let self = self else { return }
            
            if let error = error {
                view.stopActivityAnimating()
                showAlert(message: error)
            } else {
                if reverse {
                    isBusinessOwner = !isBusinessOwner
                }

                view.stopActivityAnimating()
                navigateToAuthorizedRoot()
                MessagingManager.shared.updateManualyIsSubscribed(true)
            }
        })
    }
    
    //MARK: - Actions
    
    @IBAction func didTapAccountTypeButton(_ sender: Any) {
        isBusinessOwner.toggle()
        updateInitialLoginSignUpState()
        updateUI()
    }
    
    @IBAction func didTapRememberButton(_ sender: Any) {
        if storedEmail == nil {
            Settings.setEmail(email, isBusinessOwner: isBusinessOwner)
        } else {
            Settings.setEmail(nil, isBusinessOwner: isBusinessOwner)
        }
        updateUI()
    }
    
    @IBAction func didTapForgotPasswordButton(_ sender: Any) {
        view.endEditing(true)
        guard Validator.isEmailValid(email) else {
            self.showAlert(message: Constants.Error.emailInputError)
            return
        }
            
        view.startActivityAnimating()
        FirestoreManager.shared.resetPassword(email: email) { [weak self]  error in
            guard let self = self else { return }
            
            self.view.stopActivityAnimating()
            if let error = error {
                self.showAlert(message: error)
            } else {
                self.showAlert(message: "Check the email to reset password")//todo:  //check text
            }
        }
    }
    
    @IBAction func didTapFacebookButton(_ sender: Any) {
        if let profile = UserManager.shared.profile, profile.type == .guest {
            FirestoreManager.shared.deleteAccount()
        } else {
            FirestoreManager.shared.logOut()
        }
        
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"], from: self) { (result, error) in
            guard let result = result else {
                self.showAlert(message: error?.localizedDescription ?? Constants.Error.unexpectedError)
                self.removeFbData()
                return
            }
            
            guard !result.isCancelled else { return }

            let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current?.tokenString ?? "")
            self.loginWithCredential(credential)
        }
    }
    
    @IBAction func didTapGoogleButton(_ sender: Any) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        if let profile = UserManager.shared.profile, profile.type == .guest {
            FirestoreManager.shared.deleteAccount()
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            guard error == nil,
                  let idToken = result?.user.idToken,
                let accessToken = result?.user.accessToken
            else {
                self.showAlert(message: error?.localizedDescription ?? Constants.Error.unexpectedError)
                self.removeFbData()
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
              self.loginWithCredential(credential)
        }
    }
    
    @IBAction func didTapAppleButton(_ sender: Any) {
        if let profile = UserManager.shared.profile, profile.type == .guest {
            FirestoreManager.shared.deleteAccount()
        }
        
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    @IBAction func didTapGuestAuthButton() {
        if let profile = UserManager.shared.profile, profile.type == .guest {
            if presentingViewController is ChooseAccountTypeViewController {
                FirestoreManager.shared.deleteAccount()
            } else {
                dismiss(animated: true)
                return
            }
        }
        
        view.startActivityAnimating()
        FirestoreManager.shared.logOut()
        
        FirestoreManager.shared.signUpAnonimously { [weak self] error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                view.stopActivityAnimating()
                
                view.stopActivityAnimating()
                if let error = error {
                    showAlert(message: error)
                    return
                }
                
                navigateToAuthorizedRoot()
            }
        }
    }
    
    //MARK: - Utility
    
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
      }.joined()

      return hashString
    }
    
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: Array<Character> =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
          }
          return random
        }

        randoms.forEach { random in
          if remainingLength == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
    }
    
    @objc func agePickerDoneAction() {
        ageInputView.textField.resignFirstResponder()
        ageInputView.textFieldText = datePicker.date.ddmmyyyString
        selectedAge = datePicker.date
    }
    
    @objc func agePickerCancelAction() {
        ageInputView.textField.resignFirstResponder()
    }
    
    @objc func genderPickerDoneAction() {
        genderInputView.textField.resignFirstResponder()
        let result = genders[genderPickerView.selectedRow(inComponent: 0)]
        genderInputView.textFieldText = result.name
        selectedGender = result
    }
    
    @objc func genderPickerCancelAction() {
        genderInputView.textField.resignFirstResponder()
    }
}

extension AuthViewController: InputViewDelegate {
    func inputView(_ sender: InputView, didChangeText text: String) {
        if sender == emailInputView, isRememberMeChecked {
            Settings.setEmail(text, isBusinessOwner: isBusinessOwner)
        }
    }
}

extension AuthViewController: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                idToken: idTokenString,
                                                rawNonce: nonce)
        
            FirestoreManager.shared.login(type: isBusinessOwner ? .business : .customer, credential: credential) { [weak self] reverse, error in
                guard let self = self else { return }
                
                view.stopActivityAnimating()
                if reverse {
                    isBusinessOwner = !isBusinessOwner
                }
                guard error == nil else {
                    showAlert(message: error!)
                    return
                }
                
                navigateToAuthorizedRoot()
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard (error as NSError).code != ASAuthorizationError.Code.canceled.rawValue else { return }
          
        self.showAlert(message: error.localizedDescription)
    }
}


extension AuthViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return ASPresentationAnchor(frame: view.frame)
    }
}

extension AuthViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
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
