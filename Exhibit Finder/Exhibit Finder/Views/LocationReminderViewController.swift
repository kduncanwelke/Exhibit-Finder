//
//  LocationReminderViewController.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/10/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class LocationReminderViewController: UIViewController {

	// MARK: IBOutlets
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var confirmButton: UIButton!
	@IBOutlet weak var slider: UISlider!
	@IBOutlet weak var selectedRange: UILabel!
	@IBOutlet weak var leftStepper: UIStepper!
	@IBOutlet weak var rightStepper: UIStepper!
	@IBOutlet weak var startTime: UILabel!
	@IBOutlet weak var endTime: UILabel!
	@IBOutlet weak var exhibitName: UILabel!
	
	// MARK: Variables

	let dateFormatter = DateFormatter()
	let locationManager = CLLocationManager()
	let regionRadius: CLLocationDistance = 1000
    var selection: IndexPath?
    
    private let reminderViewModel = ReminderViewModel()
    private let exhibitsViewModel = ExhibitsViewModel()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		mapView.delegate = self
		dateFormatter.dateFormat = "yyyy-MM-dd"
		
		locationManager.delegate = self
		
		confirmButton.layer.cornerRadius = 10
		slider.addTarget(self, action: #selector(sliderChanged(slider:)), for: .valueChanged)
		leftStepper.addTarget(self, action: #selector(leftStepperChanged(stepper:)), for: .valueChanged)
		rightStepper.addTarget(self, action: #selector(rightStepperChanged(stepper:)), for: .valueChanged)
		
        // set stepper values care apparently the storyboard ones aren't respected
        leftStepper.value = 8.0
        rightStepper.value = 17.0
        
		configureView()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		// perform check for location services access, as this is the main area that depends on location
		if CLLocationManager.locationServicesEnabled() {
			switch CLLocationManager.authorizationStatus() {
			case .notDetermined, .restricted, .denied:
				showSettingsAlert(title: "Location service not enabled", message: "Proximity reminders require use of location services to provide region-based notifications. These notifications will not be displayed until settings are adjusted.")
			case .authorizedAlways:
				print("access")
			case .authorizedWhenInUse:
				showSettingsAlert(title: "Location service limited", message: "Location services are only authorized for when this app is in use. Proximity reminders will not be displayed if the app is closed, unless settings are adjusted.")
			@unknown default:
				return
			}
		} else {
			showAlert(title: "Notice", message: "Location services are not available - all features of this app may not be available.")
		}
	}
	
	// MARK: Custom functions
	
	func configureView() {
		guard let index = selection else { return }
        
        exhibitName.text = exhibitsViewModel.getTitle(index: index)
		mapView.removeAnnotations(mapView.annotations)
		mapView.removeOverlays(mapView.overlays)
		
        // there is an existing location reminder
        if exhibitsViewModel.getReminderForExhibit(index: index) != nil && reminderViewModel.hasLocation() {
            print("has reminder")
            // show time range selections and region
            let address = reminderViewModel.getAddress() ?? ""
            let min = reminderViewModel.getMinTime()
            let max = reminderViewModel.getMaxTime()
            let radius = reminderViewModel.getRadius()
            let lat = reminderViewModel.getLat()
            let long = reminderViewModel.getLong()
            
            leftStepper.value = min
            startTime.text = returnTime(inputValue: min)
            rightStepper.value = max
            endTime.text = returnTime(inputValue: max)
                
            slider.value = Float(radius)
            print(radius)
                
            confirmButton.setTitle("Save Changes", for: .normal)
                
            checkForLocation(index: index, withOverlay: false)
            
            // create pin from a reminder
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            LocationManager.addItemToMap(title: address, coordinate: coordinate, radius: radius, regionRadius: 1000, mapView: mapView, withOverlay: true)
        } else if exhibitsViewModel.getReminderForExhibit(index: index) != nil && reminderViewModel.hasLocation() == false {
            print("reminder with no location")
            // there is a reminder but no location, so show museum
            checkForLocation(index: index, withOverlay: true)
        } else {
            print("no reminder")
            // there is no existing location reminder
            // if a museum location is in use, display it
            checkForLocation(index: index, withOverlay: true)
        }
	}
    
    func checkForLocation(index: IndexPath, withOverlay: Bool) {
        mapView.setRegion(LocationManager.getRegion(), animated: true)
        
        guard let index = selection else { return }
        let museum = exhibitsViewModel.getMuseum(index: index)
        
        if museum == "No museum listed" {
            return
        }
        
        // perform local search for museum by name, if it exists
        LocationManager.performSearch(museum: museum, mapView: mapView, withOverlay: withOverlay)
    }
	
	@objc func sliderChanged(slider: UISlider) {
		selectedRange.text = "\(Int(slider.value))ft"
        guard let location = mapView.annotations.first else { return }
		let circle = MKCircle(center: location.coordinate, radius: CLLocationDistance(slider.value))
		mapView.removeOverlays(mapView.overlays)
		mapView.addOverlay(circle)
	}
	
	@objc func leftStepperChanged(stepper: UIStepper) {
		rightStepper.minimumValue = stepper.value + 1
		leftStepper.maximumValue = rightStepper.value - 1
		let valueToDisplay = returnTime(inputValue: stepper.value)
		
		startTime.text = valueToDisplay
	}
	
	@objc func rightStepperChanged(stepper: UIStepper) {
		rightStepper.minimumValue = leftStepper.value + 1
		leftStepper.maximumValue = stepper.value - 1
		let valueToDisplay = returnTime(inputValue: stepper.value)
		
		endTime.text = valueToDisplay
	}
	
	// return time to display on labels, converting 24-hour time used in stepper to 12-hour time
	func returnTime(inputValue: Double) -> String {
		if inputValue < 12 {
			let value = Int(inputValue)
			return "\(value)am"
		} else if inputValue == 12 {
			let value = Int(inputValue)
			return "\(value)pm"
		} else if inputValue == 24 {
			let value = Int(inputValue) - 12
			return "\(value)am"
		} else {
			let value = Int(inputValue) - 12
			return "\(value)pm"
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
	
	// MARK: IBActions
	
	@IBAction func confirmButtonPressed(_ sender: UIButton) {
        if LocationManager.getGeofenceCount() == 20 {
			showAlert(title: "Unable to save", message: "The maximum of 20 monitored locations has been met - please delete or modify an existing reminder.")
		} else if mapView.annotations.isEmpty {
			showAlert(title: "No museum displayed", message: "A location was not loaded. Please check your network connection and try again.")
		} else {
            guard let index = selection else { return }
            
            // save location
            reminderViewModel.saveLocation(museumLocation: LocationManager.museumPinLocation, min: leftStepper.value, max: rightStepper.value, circle: mapView.overlays.first as? MKCircle, index: index)
        
            // create geofence and start monitoring
            LocationManager.addGeofence(museumLocation: LocationManager.museumPinLocation, exhibit: reminderViewModel.getExhibitForReminder(index: index), map: mapView)
            
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateButton"), object: nil)
			
			dismiss(animated: true, completion: nil)
		}
	}
	
	@IBAction func cancelButtonPressed(_ sender: UIButton) {
		dismiss(animated: true, completion: nil)
	}
	
}

// MARK: Extensions

extension LocationReminderViewController: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		showAlert(title: "Geolocation failed", message: "Please check your data connection or location sharing settings.")
	}
}

extension LocationReminderViewController: MKMapViewDelegate {
	// handle map overlays
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
		circleRenderer.fillColor = UIColor.orange.withAlphaComponent(0.5)
		circleRenderer.strokeColor = UIColor.white
		circleRenderer.lineWidth = 1.0
		return circleRenderer
	}
}
