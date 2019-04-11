//
//  LocationReminderViewController.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/10/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import MapKit

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
		
		guard let location = museumLocation, let mapRegion = region else {
			// if there is no location associated with the selected exhibit, show national mall
			let coordinate = CLLocationCoordinate2D(latitude: 38.8897468, longitude: -77.0143747)
			let regionRadius: CLLocationDistance = 1000
			let defaultRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
			
			mapView.setRegion(defaultRegion, animated: true)
			mapView.removeAnnotations(mapView.annotations)
			return
		}
		mapView.addAnnotation(location)
		mapView.setRegion(mapRegion, animated: true)
		
		let circle = MKCircle(center: location.coordinate, radius: 125)
		mapView.addOverlay(circle)
    }
    

	// MARK: Custom functions
	
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
		if inputValue <= 12 {
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
