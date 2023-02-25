//
//  ProfileViewController.swift
//  Walk2N
//
//  Created by Zhiquan You on 2/1/23.
//

import UIKit
import Firebase

struct setting {
    let title: String?
    let image: UIImage?
    let text: String?
    let arrow: Bool?
    let handler: (() -> Void)
}

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let db = DatabaseManager.shared
    
    var settingOptions = [setting](repeating: setting(title: nil, image: nil, text: nil, arrow: false, handler: {}), count: 9)
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        //        iv.image = UIImage(named: "profile.png")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.borderWidth = 3
        iv.layer.borderColor = UIColor.lessDark.cgColor
        iv.layer.backgroundColor = UIColor.lightGreen.cgColor
        
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 36)
        label.textColor = .lessDark
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .lessDark
        return label
    }()
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        
        view.addSubview(profileImageView)
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.anchor(top: view.topAnchor, paddingTop: 88, width: 120, height: 120)
        profileImageView.layer.cornerRadius = 120 / 2
        
        view.addSubview(nameLabel)
        nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        nameLabel.anchor(top: profileImageView.bottomAnchor, paddingTop: 12)
        
        view.addSubview(emailLabel)
        emailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emailLabel.anchor(top: nameLabel.bottomAnchor, paddingTop: 4)
        
        return view
    }()
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        view.backgroundColor = .white
        view.addSubview(containerView)
        containerView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 300)
        
        db.getUserInfo { docSnapshot in
            for doc in docSnapshot {
                if doc["firstName"] != nil && doc["lastName"] != nil {
                    self.nameLabel.text = "\(doc["firstName"] as? String ?? "") \(doc["lastName"] as? String ?? "")"
                }
                if doc["email"] != nil {
                    self.emailLabel.text = doc["email"] as? String
                }
                if doc["profileImgUrl"] != nil && (doc["profileImgUrl"] as? String) != nil {
                    if let url = URL(string: doc["profileImgUrl"] as! String) {
                        URLSession.shared.dataTask(with: url) { (data, response, error) in
                            guard let imageData = data else { return }
                            DispatchQueue.main.async { [self] in
                                profileImageView.image = UIImage(data: imageData)
                            }
                        }.resume()
                    }
                }
            }
        }
        
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.anchor(top: containerView.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, height: view.height - 300 - (self.tabBarController?.tabBar.frame.size.height)!)
        tableView.contentInset = UIEdgeInsets(top: -35, left: 0, bottom: -37, right: 0);
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.backgroundColor = UIColor.white
        configure()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func configure() {
        
        db.getUserInfo { docSnapshot in
            for doc in docSnapshot {
                if doc["balance"] != nil && (doc["balance"] as? Double) != nil {
                    let balance = String(describing: (doc["balance"] as! Double).truncate(places: 2))
                    self.settingOptions[0] = (setting(title: "Balance", image: UIImage(named: "balance.png")!, text: balance, arrow: false, handler: {}))
                }
                if doc["age"] != nil && (doc["age"] as? Double) != nil {
                    let age = String(describing: Int(doc["age"] as! Double))
                    self.settingOptions[1] = (setting(title: "Age", image: UIImage(named: "age.png")!, text: "\(age)", arrow: false, handler: {}))
                }
                if doc["height"] != nil && (doc["height"] as? Double) != nil{
                    let height = String(describing: (doc["height"] as! Double))
                    self.settingOptions[2] = (setting(title: "Height", image: UIImage(named: "height.png")!, text: "\(height) cm", arrow: false, handler: {}))
                }
                if doc["weight"] != nil && (doc["weight"] as? Double) != nil{
                    let weight = String(describing: (doc["weight"] as! Double))
                    self.settingOptions[3] = (setting(title: "Weight", image: UIImage(named: "weight.png")!, text: "\(weight) kg", arrow: false, handler: {}))
                }
                if doc["historicalSteps"] != nil && (doc["historicalSteps"] as? [Any]) != nil{
                    let historicalSteps = doc["historicalSteps"] as! [Any]
                    var count = 0
                    if historicalSteps.count > 7 {
                        for i in historicalSteps.count - 8...historicalSteps.count - 1 {
                            let stepData = historicalSteps[i] as! [String: Any]
                            count += stepData["stepCount"] as! Int
                        }
                    } else {
                        for i in 0..<historicalSteps.count {
                            let stepData = historicalSteps[i] as! [String: Any]
                            count += stepData["stepCount"] as! Int
                        }
                    }
                    self.settingOptions[4] = (setting(title: "Steps (past week)", image: UIImage(named: "steps.png")!, text: "\(count)", arrow: false, handler: {}))
                }
                self.tableView.reloadData()
            }
        }
        
        
        //        db.checkUserUpdates { data, update, addition, deletion in
        //            DispatchQueue.main.async {
        //                if update == true {
        //                    if data["balance"] != nil {
        //                        let balance = String(describing: (data["balance"] as! Double).truncate(places: 2))
        //                        let setting = setting(title: "Balance", image: UIImage(named: "balance.png")!, text: balance, arrow: false, handler: {})
        //                        self.settingOptions[0] = setting
        //                    }
        //                    if data["age"] != nil {
        //                        let age = String(describing: Int(data["age"] as! Double))
        //                        let setting = setting(title: "Age", image: UIImage(named: "age.png")!, text: "\(age)", arrow: false, handler: {})
        //                        self.settingOptions[1] = setting
        //                    }
        //                    if data["height"] != nil {
        //                        let height = String(describing: (data["height"] as! Double))
        //                        let setting = setting(title: "Height", image: UIImage(named: "height.png")!, text: "\(height) cm", arrow: false, handler: {})
        //                        self.settingOptions[2] = setting
        //                    }
        //                    if data["weight"] != nil {
        //                        let weight = String(describing: (data["weight"] as! Double).truncate(places: 2))
        //                        let setting = setting(title: "Weight", image: UIImage(named: "weight.png")!, text: "\(weight) kg", arrow: false, handler: {})
        //                        self.settingOptions[3] = setting
        //                    }
        //                    if data["historicalSteps"] != nil {
        //                        let historicalSteps = data["historicalSteps"] as! [Any]
        //                        var count = 0
        //                        if historicalSteps.count > 7 {
        //                            for i in historicalSteps.count - 7...historicalSteps.count {
        //                                let stepData = historicalSteps[i] as! [String: Any]
        //                                count += stepData["stepCount"] as! Int
        //                            }
        //                        } else {
        //                            for i in 0..<historicalSteps.count {
        //                                let stepData = historicalSteps[i] as! [String: Any]
        //                                count += stepData["stepCount"] as! Int
        //                            }
        //                        }
        //                        self.settingOptions[4] = (setting(title: "Steps (past week)", image: UIImage(named: "steps.png")!, text: "\(count)", arrow: false, handler: {}))
        //                    }
        //                }
        //
        //                self.tableView.reloadData()
        //            }
        //        }
        
        let hk = HealthKitManager()
        
        //        hk.gettingStepCount(7) { steps, dates in
        //            DispatchQueue.main.async {
        //                var sum = 0
        //                for i in 0..<steps.count {
        //                    sum += Int(steps[i])
        //                }
        //                self.settingOptions[4] = (setting(title: "Steps (past week)", image: UIImage(named: "steps.png")!, text: "\(sum)", arrow: false, handler: {}))
        //
        //                self.tableView.reloadData()
        //            }
        //        }
        
        hk.gettingDistance(7) { dist in
            DispatchQueue.main.async {
                let distance = String(describing: (dist).truncate(places: 2))
                self.settingOptions[5] = (setting(title: "Distance (past week)", image: UIImage(named: "dist.png")!, text: "\(distance) km", arrow: false, handler: {}))
                self.settingOptions[6] = (setting(title: "Terms of use", image: UIImage(named: "terms.png")!, text: "", arrow: true, handler: {}))
                self.settingOptions[7] = (setting(title: "Privacy", image: UIImage(named: "privacy.png")!, text: "", arrow: true, handler: {}))
                self.settingOptions[8] = (setting(title: "Log out", image: UIImage(named: "logout.png")!, text: "", arrow: false) {
                    self.logout()
                })
                
                self.tableView.reloadData()
            }
        }
        
    }
    
    private func logout() {
        let alert = UIAlertController(title: "Confirmation", message: "Log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            AuthManager().logout()
            
            // after logout, redirect to login
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let mainMenuViewController = storyboard.instantiateViewController(identifier: "MainMenuViewController")
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(mainMenuViewController)
        }))
        self.present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let setting = settingOptions[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ProfileTableViewCell.identifier,
            for: indexPath
        ) as? ProfileTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: setting)
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let setting = settingOptions[indexPath.row]
        setting.handler()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0;
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }
    
}
