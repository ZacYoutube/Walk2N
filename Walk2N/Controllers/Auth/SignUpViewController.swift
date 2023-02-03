//
//  SignUpViewController.swift
//  Walk2N
//
//  Created by Zhiquan You on 1/30/23.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {
    
    private let emailTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Enter your email"
        field.returnKeyType = .next
        field.leftViewMode = .always
        field.leftView = UIView(frame: CGRect(x:0, y:0, width: 10, height: 0))
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.layer.cornerRadius = 10
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let passwordTextField: UITextField = {
        let field = UITextField()
        field.isSecureTextEntry = true
        field.placeholder = "Enter your password"
        field.returnKeyType = .next
        field.leftViewMode = .always
        field.leftView = UIView(frame: CGRect(x:0, y:0, width: 10, height: 0))
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.layer.cornerRadius = 10
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let secondPasswordTextField: UITextField = {
        let field = UITextField()
        field.isSecureTextEntry = true
        field.placeholder = "Re-enter your password"
        field.returnKeyType = .next
        field.leftViewMode = .always
        field.leftView = UIView(frame: CGRect(x:0, y:0, width: 10, height: 0))
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.layer.cornerRadius = 10
        field.backgroundColor = .secondarySystemBackground
        return field
    }()

    
    private let createAccountBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Sign up", for: .normal)
        btn.layer.cornerRadius = 10
        btn.backgroundColor = .systemBlue
        return btn
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.alpha = 0
        label.textAlignment = .center
        label.textColor = .red
        return label
    }()
    
    private func addSubView() {
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(secondPasswordTextField)
        view.addSubview(createAccountBtn)
        view.addSubview(errorLabel)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubView()
        view.backgroundColor = .systemBackground
        createAccountBtn.addTarget(self, action: #selector(signup), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        errorLabel.center = CGPoint(x: view.width  / 2,
                                    y: errorLabel.height / 2)
        emailTextField.frame = CGRect(x: 25, y: view.safeAreaInsets.top + 20, width: view.width - 50, height: 50)
        passwordTextField.frame = CGRect(x: 25, y: emailTextField.btm + 20, width: view.width - 50, height: 50)
        secondPasswordTextField.frame = CGRect(x: 25, y: passwordTextField.btm + 20, width: view.width - 50, height: 50)
        createAccountBtn.frame = CGRect(x: 25, y: secondPasswordTextField.btm + 30, width: view.width - 50, height: 50)
        errorLabel.frame = CGRect(x: 25, y:  createAccountBtn.btm + 10, width: view.width - 50, height: 50)
    }
    
    
//    func validateCredentials() -> String? {
//        // returns error message if there is an error otherwise return null
//        if email.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
//           password.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
//           reenteredPassword.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
//            return "Please fill in the required fields."
//        }
//
//        if password.text?.trimmingCharacters(in: .whitespacesAndNewlines) != reenteredPassword.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
//            return "password does not match."
//        }
//
//
//        return nil
//    }
        
    
    @objc private func signup() {
        let email = emailTextField.text
        let pass = passwordTextField.text
        let pass1 = secondPasswordTextField.text
        
        if pass?.trimmingCharacters(in: .whitespacesAndNewlines) != pass1?.trimmingCharacters(in: .whitespacesAndNewlines){
            errorLabel.text = "Please enter the same password"
            errorLabel.alpha = 1
            return
        }
        
        guard pass == pass1, pass!.count >= 8, pass1!.count >= 8 else{
            return
        }
        
        AuthManager.shared.createNewUser(email: email!, password: pass!) { registered, uid in
            DispatchQueue.main.async {
                if registered {
                    DatabaseManager.shared.insertUser(email: email!, uid: uid) { success in
                        if success {
                            print("success add to db")
                        }else{
                            print()
                        }
                    }
                    print("success")
                    print(registered)
                }
                else{
                    print("nooo")
                    print(registered)
                }
            }
        }
    }
        }
        
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

