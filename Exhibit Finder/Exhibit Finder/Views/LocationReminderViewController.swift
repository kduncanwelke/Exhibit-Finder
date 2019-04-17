//
//  LocationReminderViewController.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/10/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import MapKit
import CoreData

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
	@IBOutlet weak var museumName: UILabel!
	@IBOutlet weak var time: UILabel!
	
	
	// MARK: Variables
	
	var exhibit: Exhibition?
	var openDate: String?
	var closeDate: String?
	var museumLocation: MKPointAnnotation?
	var region: MKCoordinateRegion?
	let dateFormatter = DateFormatter()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		mapView.delegate = self
		dateFormatter.dateFormat = "yyyy-MM-dd"
		
        // Do any additional setup after loading the view.
		confirmButton.layer.cornerRadius = 10
		slider.addTarget(self, action: #selector(sliderChanged(slider:)), for: .valueChanged)
		leftStepper.addTarget(self, action: #selector(leftStepperChanged(stepper:)), for: .valueChanged)
		rightStepper.addTarget(self, action: #selector(rightStepperChanged(stepper:)), for: .valueChanged)
		
		configureView()
    }
	
	// MARK: Custom functions
	
	func configureView() {
		guard let selectedExhibit = exhibit, let open = openDate, let close = closeDate else { return }
		exhibitName.text = selectedExhibit.attributes.title
		museumName.text = selectedExhibit.attributes.museum ?? "Not applicable"
		
		let date = Date()
		guard let convertedOpenDate = dateFormatter.date(from: open) else { return }
		if convertedOpenDate > date {
			time.text = "\(open) to \(close)"
		} else {
			time.text = "Today to \(close)"
		}
		
		mapView.removeAnnotations(mapView.annotations)
		mapView.removeOverlays(mapView.overlays)
		let regionRadius: CLLocationDistance = 1000
		
		// if there is a reminder do this
		if let reminderInfo = ReminderManager.currentReminder?.location {
			// show time range selections and region
			leftStepper.value = reminderInfo.minTime
			startTime.text = returnTime(inputValue: reminderInfo.minTime)
			
			rightStepper.value = reminderInfo.maxTime
			endTime.text = returnTime(inputValue: reminderInfo.maxTime)
			
			slider.value = Float(reminderInfo.radius)
			
			confirmButton.setTitle("Save Changes", for: .normal)
			
			// create pin from a reminder reminder
			let annotation = MKPointAnnotation()
			let coordinate = CLLocationCoordinate2D(latitude: reminderInfo.latitude, longitude: reminderInfo.longitude)
			annotation.coordinate = coordinate
			annotation.title = reminderInfo.address
			
			// add pin to map
			mapView.addAnnotation(annotation)
			
			// set region and add circular overly
			let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
			mapView.setRegion(region, animated: true)
			let circle = MKCircle(center: coordinate, radius: reminderInfo.radius)
			mapView.addOverlay(circle)
		} else { // if there is no reminder set do this instead
			guard let location = museumLocation, let mapRegion = region else {
				// if there is no location associated with the selected exhibit, show national mall
				let coordinate = CLLocationCoordinate2D(latitude: 38.8897468, longitude: -77.0143747)
				let defaultRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
				
				mapView.setRegion(defaultRegion, animated: true)
				return
			}
			
			mapView.addAnnotation(location)
			mapView.setRegion(mapRegion, animated: true)
			
			let circle = MKCircle(center: location.coordinate, radius: 125)
			mapView.addOverlay(circle)
			
		}
	}
	
	func saveEntry() {
		let managedContext = CoreDataManager.shared.managedObjectContext
		
		guard let currentReminder = ReminderManager.currentReminder else {
			// if there's no reminder selected, create a new one
			let newReminder = Reminder(context: managedContext)
			
			var location: Location?
			location = Location(context: managedContext)
			
			getLocationForReminder(location: location)
			newReminder.location = location
			getExhibitData(reminder: newReminder)
			
			do {
				try managedContext.save()
				print("saved")
			} catch {
				// this should never be displayed but is here to cover the possibility
				showAlert(title: "Save failed", message: "Notice: Data has not successfully been saved.")
			}
			
			return
		}
		
		// otherwise overwrite existing item with new time selection
		guard let location = currentReminder.location else { return }
		getLocationForReminder(location: location)
		currentReminder.location = location
		
		do {
			try managedContext.save()
			print("resave successful")
		} catch {
			// this should never be displayed but is here to cover the possibility
			showAlert(title: "Save failed", message: "Notice: Data has not successfully been saved.")
		}
	}
	
	func reloadReminders() {
		let managedContext = CoreDataManager.shared.managedObjectContext
		let fetchRequest = NSFetchRequest<Reminder>(entityName: "Reminder")
		//ReminderManager.reminders.removeAll()
		
		do {
			ReminderManager.reminders = try managedContext.fetch(fetchRequest)
			print("reminders reloaded")
		} catch let error as NSError {
			showAlert(title: "Could not retrieve data", message: "\(error.userInfo)")
		}
	}
	
	// get location info for location based reminder
	func getLocationForReminder(location: Location?) {
		guard let locationReminder = mapView.annotations.first, let address = locationReminder.title, let currentExhibit = exhibit else { return }
		location?.address = address
		location?.latitude = locationReminder.coordinate.latitude
		location?.longitude = locationReminder.coordinate.longitude
		location?.name = currentExhibit.attributes.title
		location?.minTime = leftStepper.value
		location?.maxTime = rightStepper.value
		guard let overlay = mapView.overlays.first as? MKCircle else { return }
		location?.radius = overlay.radius
	}
	
	// get exhibit data for reminder
	func getExhibitData(reminder: Reminder) {
		guard let currentExhibit = exhibit else { return }
		reminder.name = currentExhibit.attributes.title
		reminder.id = Int64(currentExhibit.attributes.path.pid)
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
		if mapView.annotations.isEmpty {
			showAlert(title: "No location selected", message: "Please select a place on the map for this notification")
		} else {
			saveEntry()
			reloadReminders()
			
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateButton"), object: nil)
			
			dismiss(animated: true, completion: nil)
		}
	}
	
	@IBAction func cancelButtonPressed(_ sender: UIButton) {
		dismiss(animated: true, completion: nil)
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
