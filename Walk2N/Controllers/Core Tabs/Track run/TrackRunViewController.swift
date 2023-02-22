//
//  TrackRunViewController.swift
//  Walk2N
//
//  Learned and borrowed from https://medium.com/macoclock/logic-for-building-a-simple-jogging-and-running-app-in-ios-13-swift-5-116a49af226
//

import UIKit
import MapKit
import CoreLocation
import MessageUI
import Firebase

class TrackRunViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var runButton: UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var errorView: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var sv: UIStackView!
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 500
    var locationAccess = false
        
    var locationsPassed = [CLLocation]()
    var isRunning = false
    var route: MKPolyline?
    var distanceTraveled: Double = 0.0
    
    var startRunTime: Date?
    var endRunTime: Date?
    
    let stepCounter = StepCounter()
    var currentShoe: Shoe? = nil
    
    var currency: Double? = 0.0

//    var timer : Timer?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpNavbar()
        navigationItem.title = "Map"
        mapView.delegate = self
        reset()
        setup()
    }
    
    func setup() {
        runButton.setTitleColor(.lessDark, for: .normal)
        runButton.setTitle("START MOVE", for: .normal)
        distanceLabel.isHidden = true
        stepsLabel.isHidden = true
        distanceLabel.textColor = .systemRed
        stepsLabel.textColor = .systemRed
        checkLocationServices()
    }

    func addLocationsToArray(_ locations: [CLLocation]) {
        for location in locations {
            if !locationsPassed.contains(location) {
                locationsPassed.append(location)
            }
        }
    }

    func calculateAndDisplayDistance() {
        var totalDistance = 0.0
        if locationsPassed.count > 0 {
            for i in 1..<locationsPassed.count {
                let previousLocation = locationsPassed[i-1]
                let currentLocation = locationsPassed[i]
                totalDistance += currentLocation.distance(from: previousLocation)
            }
        }
        
        distanceTraveled = totalDistance
        let displayDistance: String
        displayDistance = String(format: "Distance Travelled: %.2f kilometers", distanceTraveled * 0.001)
        distanceLabel.text = displayDistance
    }
    
    func getAppleMapsURL() -> String? {
        guard let startLocation = locationsPassed.first?.coordinate, let endLocation = locationsPassed.last?.coordinate, locationsPassed.count > 1 else {
            return nil
        }
        
        let source = MKMapItem(placemark: MKPlacemark(coordinate: startLocation))
        source.name = "Start"
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: endLocation))
        destination.name = "End"
        
        let appleMapsURL = "http://maps.apple.com/maps?saddr=\(startLocation.latitude),\(startLocation.longitude)&daddr=\(endLocation.latitude),\(endLocation.longitude)"
        return appleMapsURL
    }
    
    func startRun() {
        reset()
        
        isRunning = true
        distanceLabel.isHidden = true
        stepsLabel.isHidden = true
        sv.isHidden = true
        
        distanceLabel.text = ""
        stepsLabel.text = ""
        
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        
        startRunTime = Date()
    }
    
    
    func stopRun() {
        isRunning = false
        
        distanceLabel.isHidden = false
        stepsLabel.isHidden = false
        distanceLabel.textColor = .lessDark
        stepsLabel.textColor = .lessDark
        
        sv.isHidden = false
        sv.backgroundColor = .lightGreen
        sv.layer.cornerRadius = 8
        
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.stopUpdatingLocation()
        displayRoute()
        
        endRunTime = Date()
        calculateBonus()
    }
    
    private func calculateBonus() {
        
        self.stepCounter.getSteps(from: self.startRunTime!) { stepsTaken in
            
            DispatchQueue.main.async {
                if self.currentShoe != nil {
                    let steps = Double(stepsTaken!)
                    let currentShoe = self.currentShoe!
                    let balance = self.currency
                    let stepGoalToday = 1000.0
                    var stepsString: String = ""
                    var bonus: Double = 0.0
                    
                    let db = DatabaseManager.shared
                    
                    // here we can calculate the bonus - formula for now
                    db.getUserInfo { docSnapshot in
                        for doc in docSnapshot {
                            if (doc["currentShoe"] as? [String: Any]) != nil {
                                if self.distanceTraveled * 0.001 > 0.0 {
                                    let bonusSoFar = doc["bonusEarnedToday"] as! Double
                                    bonus = bonusSoFar + steps * currentShoe.awardPerStep!
                                    db.updateUserInfo(fieldToUpdate: ["bonusEarnedToday", "balance", "bonusEarnedDuringRealTimeRun"], fieldValues: [bonus, balance! + bonus - bonusSoFar, bonus - bonusSoFar]) { bool in }
                                    stepsString = "Steps Taken: \(Int(steps)), bonus earned: \(Double(bonus - bonusSoFar).truncate(places: 2))"
                                    self.stepsLabel.text = stepsString
                                }
                            }
                        }
                        
                    }
                }
            }
        }
    }
    
    func enableButtons() {
        runButton.isEnabled = true
        runButton.isHidden = false
        runButton.layer.backgroundColor = UIColor.lightGreen.cgColor
        runButton.layer.cornerRadius = 16
    }
    
    func disableAllButtons() {
        runButton.isEnabled = false
        runButton.isHidden = true
    }
}

extension TrackRunViewController{
//    @IBAction func locationButtonTapped(_ sender: Any) {
//        centerViewOnUserLocation()
//    }
    
    @IBAction func runButtonTapped(_ sender: Any) {
        DatabaseManager.shared.checkUserUpdates { data, update, added, deleted in
            if let user = data as? [String: Any] {
                if added == true || deleted == true {
                    if user["currentShoe"] is [String: Any] {
                        let user = user["currentShoe"] as? [String: Any]
                        self.currentShoe = Shoe(id: user?["id"] as? String, name: user?["name"] as? String, awardPerStep: user?["awardPerStep"] as? Double, imgUrl: user?["imgUrl"] as? String, price: user?["price"] as? Double, expirationDate: (user?["expirationDate"] as! Timestamp).dateValue())
                        self.toggleRun()
                    } else {
                        if self.runButton.title(for: .normal) == "START MOVE" {
                            let alert = UIAlertController(title: "Confirmation", message: "You will not receive any bonus if you don't wear a shoe. Are you sure?", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                                self.runButton.setTitle("STOP MOVE", for: .normal)
                                self.startRun()
                                self.runButton.setTitleColor(.red, for: .normal)
                            }))
                            self.present(alert, animated: true)
                        } else {
                            self.toggleRun()
                        }
                    }
                    if (user["balance"] != nil) {
                        self.currency = (user["balance"] as! Double)
                    }
                }
            }
        }
    }
    
    private func toggleRun() {
        if self.runButton.title(for: .normal) == "START MOVE" {
            self.runButton.setTitle("STOP MOVE", for: .normal)
            self.startRun()
            self.runButton.setTitleColor(.red, for: .normal)
        } else {
            self.runButton.setTitle("START MOVE", for: .normal)
            self.stopRun()
            self.runButton.setTitleColor(UIColor.lessDark, for: .normal)
        }
    }
}

extension TrackRunViewController: MFMessageComposeViewControllerDelegate {
    
    func getComposeMessageViewController(message: String) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.body = message
        controller.messageComposeDelegate = self
        return controller
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension TrackRunViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .systemBlue
        renderer.lineWidth = 5
        renderer.alpha = 0.5
        
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Annotation {
            let id = "pin"
            let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            pin.canShowCallout = true
            pin.animatesDrop = true
            pin.pinTintColor = annotation.coordinateType == .start ? .green : .red
            pin.calloutOffset = CGPoint(x: -8, y: -3)
            return pin
        }
        return nil
    }
    
    func displayRoute() {
        var routeCoordinates = [CLLocationCoordinate2D]()
        for location in locationsPassed {
            routeCoordinates.append(location.coordinate)
        }
        route = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
        guard let route = route else { return }
        mapView.addOverlay(route)
        mapView.setVisibleMapRect(route.boundingMapRect, edgePadding: UIEdgeInsets(top: 200, left: 50, bottom: 50, right: 50), animated: true)
        
        calculateAndDisplayDistance()
        setupAnnotations()
    }
    
    func setupAnnotations() {
        guard let startLocation = locationsPassed.first?.coordinate, let endLocation = locationsPassed.last?.coordinate, locationsPassed.count > 1 else {
            return
        }
        let startAnnotation = Annotation(coordinateType: .start, coordinate: startLocation)
        let endAnnotation = Annotation(coordinateType: .end, coordinate: endLocation)
        
        mapView.addAnnotation(startAnnotation)
        mapView.addAnnotation(endAnnotation)
    }
    
    func removeOverlays() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
    }
    
    func reset() {
        removeOverlays()
        distanceTraveled = 0
        locationsPassed.removeAll()
        route = nil
    }
}

extension TrackRunViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        if isRunning {
            addLocationsToArray(locations)
        }
        
        let region = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint("MSH: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationManagerDidChangeAuthorization(manager)
    }
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            enableButtons()
            errorView.isHidden = true
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
            mapView.showsUserLocation = true
        } else {
            disableAllButtons()
            
            locationManager.stopUpdatingLocation()
            errorView.isHidden = false
            errorView.text = "Location not found"
        }
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            self.errorView.isHidden = true
            self.setupLocationManager()
            self.locationManagerDidChangeAuthorization(self.locationManager)
        } else {
            self.disableAllButtons()

            self.errorView.isHidden = false
            self.errorView.text = "Please enable Location Services"
        }

    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            errorView.isHidden = true
            locationManager.requestLocation()
            centerViewOnUserLocation()
            break
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        default:
            disableAllButtons()
            
            //Alert error
            locationManager.stopUpdatingLocation()
            errorView.isHidden = false
            errorView.text = "For this app to work\n" +
            "Please go to Setttings\n" +
            "Then Privacy\n" +
            "Then Location Services\n" +
            "Then Running App\n" +
            "Then Select Always"
            break
        }
    }
}
