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
	
	var museumLocation: MKPointAnnotation?
	var region: MKCoordinateRegion?
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
                
            confirmButton.setTitle("Save Changes", for: .normal)
                
            // create pin from a reminder
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            addItemToMap(title: address, coordinate: coordinate, radius: radius)
        } else if exhibitsViewModel.getReminderForExhibit(index: index) != nil && reminderViewModel.hasLocation() == false {
            // there is a reminder but no location, so show museum
            if let location = museumLocation, let mapRegion = region {
                mapView.addAnnotation(location)
                mapView.setRegion(mapRegion, animated: true)
                
                let circle = MKCircle(center: location.coordinate, radius: 125)
                mapView.addOverlay(circle)
            }
        } else {
            // there is no existing location reminder
            // if a museum location is in use, display it
            if let location = museumLocation, let mapRegion = region {
                mapView.addAnnotation(location)
                mapView.setRegion(mapRegion, animated: true)
                
                let circle = MKCircle(center: location.coordinate, radius: 125)
                mapView.addOverlay(circle)
            } else {
                // if segue was made too quickly, museum location may not have passed, so perform search
                let museum = exhibitsViewModel.getMuseum(index: index)
                performSearch(museum: "\(museum) Washington DC")
                
                // if there is no location associated with the selected exhibit, show national mall
                let coordinate = CLLocationCoordinate2D(latitude: 38.8897468, longitude: -77.0143747)
                let defaultRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
                mapView.setRegion(defaultRegion, animated: true)
            }
        }
	}
	
	func updateLocation(location: MKPlacemark) {
		// wipe annotations if location was updated
		mapView.removeAnnotations(mapView.annotations)
		mapView.removeOverlays(mapView.overlays)
		
		let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
		let locale = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
		let geocoder = CLGeocoder()
		
		// parse address to assign it to title for pin
		geocoder.reverseGeocodeLocation(locale, completionHandler: { [unowned self] (placemarks, error) in
			if error == nil {
				guard let firstLocation = placemarks?[0] else { return }
				// add to map
				let radius = Double(self.slider.value)
				self.addItemToMap(title: "\(firstLocation.name ?? "") \n \(LocationManager.parseAddress(selectedItem: firstLocation))", coordinate: coordinate, radius: radius)
			}
			else {
				// an error occurred during geocoding
				self.showAlert(title: "Error geocoding", message: "Location could not be parsed")
			}
		})
	}

	func performSearch(museum: String) {
		// perform local search for museum by name, if it exists
		let request = MKLocalSearch.Request()
		request.naturalLanguageQuery = museum
		request.region = mapView.region
		let search = MKLocalSearch(request: request)
		
		search.start { [unowned self] response, _ in
			guard let response = response else {
				return
			}
			
			guard let result = response.mapItems.first?.placemark else { return }
			// add to map
			self.addItemToMap(title: "\(museum) \n \(result.title ?? "")", coordinate: result.coordinate, radius: 125)
		}
	}
	
	func addItemToMap(title: String, coordinate: CLLocationCoordinate2D, radius: Double) {
		let annotation = MKPointAnnotation()
		annotation.coordinate = coordinate
		annotation.title = title
		mapView.addAnnotation(annotation)
		
		// recenter map on added annotation
		let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
		mapView.setRegion(region, animated: true)
		
		// add overlay for region
		let circle = MKCircle(center: coordinate, radius: radius)
		mapView.addOverlay(circle)
	}
	
	@objc func sliderChanged(slider: UISlider) {
		selectedRange.text = "\(Int(slider.value))ft"
		guard let location = museumLocation else { return }
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
		if locationManager.monitoredRegions.count == 20 {
			showAlert(title: "Unable to save", message: "The maximum of 20 monitored locations has been met - please delete or modify an existing reminder.")
		} else if mapView.annotations.isEmpty {
			showAlert(title: "No museum displayed", message: "A location was not loaded. Please check your network connection and try again.")
		} else {
            guard let index = selection else { return }
            
            // save location
            reminderViewModel.saveLocation(museumLocation: museumLocation, min: leftStepper.value, max: rightStepper.value, circle: mapView.overlays.first as? MKCircle, index: index)
			
            // create geofence and start monitoring
            if let pin = museumLocation, let title = reminderViewModel.getExhibitForReminder(index: index)?.exhibit, let circle = mapView.overlays.first as? MKCircle {
				
				let annotation = MKPointAnnotation()
				let coordinate = CLLocationCoordinate2D(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
				annotation.coordinate = coordinate
				
				let geofenceArea = LocationManager.getMonitoringRegion(for: annotation, exhibitName: title, radius: circle.radius)
		
				locationManager.startMonitoring(for: geofenceArea)
				print("\(annotation.coordinate.latitude), \(annotation.coordinate.longitude)")
				print("started monitoring")
			}
			
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
