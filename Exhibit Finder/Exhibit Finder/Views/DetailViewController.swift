//
//  DetailViewController.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/6/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import WebKit
import CoreLocation
import MapKit

class DetailViewController: UIViewController {

	// MARK: IBOutlets
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var museumLabel: UILabel!
	@IBOutlet weak var openDateLabel: UILabel!
	@IBOutlet weak var closeDateLabel: UILabel!
	@IBOutlet weak var permanentLabel: UILabel!
	@IBOutlet weak var tourLabel: UILabel!
	@IBOutlet weak var travelingLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	
	@IBOutlet weak var mapView: MKMapView!
	
	@IBOutlet weak var reminderButton: UIButton!
	@IBOutlet weak var viewOnlineButton: UIButton!
	
	// MARK: Variables
	
	var detailItem: Exhibition?

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		viewOnlineButton.layer.cornerRadius = 10
		reminderButton.layer.cornerRadius = 10
		
		NotificationCenter.default.addObserver(self, selector: #selector(updateButton), name: NSNotification.Name(rawValue: "updateButton"), object: nil)
		
		configureView()
	}

	// MARK: Custom functions
	
	func configureView() {
		// Update the user interface for the detail item.
		guard let detail = detailItem else {
			// if there is no selection, set button titles appropriately
			viewOnlineButton.setTitle("No Selection", for: .normal)
			viewOnlineButton.isEnabled = false
			reminderButton.setTitle(" No Selection ", for: .normal)
			
			return
		}
		titleLabel.text = detail.attributes.title
		museumLabel.text = detail.attributes.museum ?? "No museum listed"
		let open = detail.attributes.openDate.dropLast(14)
		openDateLabel.text = "\(open)"
		let close = detail.attributes.closeDate.dropLast(14)
		closeDateLabel.text = "\(close)"
	
		permanentLabel.text = {
			if detail.attributes.permanentExhibition {
				return "Yes"
			} else {
				return "No"
			}
		}()
	
		tourLabel.text = {
			if detail.attributes.offeredForTour {
				return "Yes"
			} else {
				return "No"
			}
		}()
	
		travelingLabel.text = {
			if detail.attributes.traveling {
				return "Yes"
			} else {
				return "No"
			}
		}()
		
		if ReminderManager.reminders.contains(where: { $0.id == detail.attributes.path.pid }) {
			reminderButton.setTitle(" Edit Reminder ", for: .normal)
		} else {
			reminderButton.setTitle(" Add Reminder ", for: .normal)
		}
		
		descriptionLabel.text = detail.attributes.description.processed.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil).replacingOccurrences(of: "&nbsp;", with: "")
		
		loadMapView()
	}
	
	@objc func updateButton() {
		reminderButton.setTitle(" Edit Reminder ", for: .normal)
	}
	
	func loadMapView() {
		// coordinates for the national mall
		let coordinate = CLLocationCoordinate2D(latitude: 38.8897468, longitude: -77.0143747)
		
		let regionRadius: CLLocationDistance = 1000
		
		let defaultRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
		
		mapView.setRegion(defaultRegion, animated: true)
		
		mapView.removeAnnotations(mapView.annotations)
		
		guard let museum = detailItem?.attributes.museum else { return }
		
		// perform local search for museum by name, if it exists
		let request = MKLocalSearch.Request()
		request.naturalLanguageQuery = museum
		request.region = mapView.region
		let search = MKLocalSearch(request: request)
		
		search.start { [unowned self] response, _ in
			guard let response = response else {
				return
			}

			// create annotation and add to map
			let annotation = MKPointAnnotation()
			guard let result = response.mapItems.first?.placemark else { return }
			annotation.coordinate = result.coordinate
			annotation.title = "\(museum) \n \(result.title ?? "")"
			self.mapView.addAnnotation(annotation)
			
			// recenter map on added annotation
			let region = MKCoordinateRegion(center: result.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
			self.mapView.setRegion(region, animated: true)
		}
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.destination is SeeOnlineViewController {
			let destinationViewController = segue.destination as? SeeOnlineViewController
			guard let detail = detailItem, let url = URL(string: "https://americanart.si.edu\(detail.attributes.path.alias)") else { return }
			destinationViewController?.urlToDisplay = url
		} else if segue.identifier == "addReminder" {
			let barViewControllers = segue.destination as! UITabBarController
			
				let destinationViewControllerOne = barViewControllers.viewControllers![0] as? TimeReminderViewController
				guard let detail = detailItem else { return }
				destinationViewControllerOne?.exhibit = detail
				destinationViewControllerOne?.openDate = openDateLabel.text
				destinationViewControllerOne?.closeDate = closeDateLabel.text
				
				let destinationViewControllerTwo = barViewControllers.viewControllers![1] as? LocationReminderViewController
				destinationViewControllerTwo?.exhibit = detail
				destinationViewControllerTwo?.openDate = openDateLabel.text
				destinationViewControllerTwo?.closeDate = closeDateLabel.text
				destinationViewControllerTwo?.museumLocation = mapView.annotations.first as? MKPointAnnotation
				destinationViewControllerTwo?.region = mapView.region
	
			guard let currentReminder = ReminderManager.currentReminder else { return }
			
			if currentReminder.time != nil {
				barViewControllers.selectedIndex = 0
			} else if currentReminder.location != nil {
				barViewControllers.selectedIndex = 1
			} else {
				return
			}
		}
	}
	
	// MARK: IBActions
	
	@IBAction func viewOnlineButtonTapped(_ sender: UIButton) {
		performSegue(withIdentifier: "viewOnline", sender: Any?.self)
	}
	
	@IBAction func addReminderButtonTapped(_ sender: UIButton) {
		performSegue(withIdentifier: "addReminder", sender: Any?.self)
	}
	
}

