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
import Nuke

class DetailViewController: UIViewController {

	// MARK: IBOutlets
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var museumLabel: UILabel!
	@IBOutlet weak var openDateLabel: UILabel!
	@IBOutlet weak var closeDateLabel: UILabel!
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	
	@IBOutlet weak var exhibitImage: UIImageView!
	@IBOutlet weak var mapView: MKMapView!
	
	@IBOutlet weak var reminderButton: UIButton!
	@IBOutlet weak var viewOnlineButton: UIButton!
	
	// MARK: Variables
	
    var selection: IndexPath?
	var detailItem: Exhibit?
	var image: UIImage?
	var museumPinLocation: MKPointAnnotation?
    
    private let reminderViewModel = ReminderViewModel()
    private let exhibitsViewModel = ExhibitsViewModel()

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
		navigationItem.leftItemsSupplementBackButton = true
		
		viewOnlineButton.layer.cornerRadius = 10
		reminderButton.layer.cornerRadius = 10
		exhibitImage.layer.cornerRadius = exhibitImage.frame.height / 2
		exhibitImage.clipsToBounds = true
		
		NotificationCenter.default.addObserver(self, selector: #selector(updateButton), name: NSNotification.Name(rawValue: "updateButton"), object: nil)
		
		configureView()
	}
	
	// MARK: Custom functions
	
	func configureView() {
        guard let index = selection else {
            // if there is no selection, set button titles appropriately
            viewOnlineButton.setTitle("No Selection", for: .normal)
            viewOnlineButton.isEnabled = false
            reminderButton.setTitle(" No Selection ", for: .normal)
            return
        }
        
        if let reminder = exhibitsViewModel.getReminderForExhibit(index: index) {
            reminderButton.isEnabled = true
            viewOnlineButton.isEnabled = true
            reminderButton.setTitle("Edit Reminder", for: .normal)
        } else {
            // no reminder
            reminderButton.isEnabled = false
            viewOnlineButton.isEnabled = false
            reminderButton.setTitle("Add Reminder", for: .normal)
        }
		
		DispatchQueue.main.async {
			if let url = self.exhibitsViewModel.getImageUrl(index: index) {
				// load image with Nuke
				Nuke.loadImage(with: url, options: NukeOptions.options, into: self.exhibitImage) { [unowned self] response, err in
					if err != nil {
						self.exhibitImage.image = NukeOptions.options.failureImage
					} else {
						self.exhibitImage.image = response?.image
					}
				}
			}
		}
		
		titleLabel.text = exhibitsViewModel.getTitle(index: index)
        museumLabel.text = exhibitsViewModel.getMuseum(index: index)
        openDateLabel.text = exhibitsViewModel.getOpenDate(index: index)
        closeDateLabel.text = exhibitsViewModel.getCloseDate(index: index)
        locationLabel.text = exhibitsViewModel.getLocation(index: index)
        descriptionLabel.text = exhibitsViewModel.getVerboseInfo(index: index)
		loadMapView()
	}
	
	@objc func updateButton() {
		reminderButton.setTitle("Edit Reminder", for: .normal)
	}
	
	func loadMapView() {
		// coordinates for the national mall
		let coordinate = CLLocationCoordinate2D(latitude: 38.8897468, longitude: -77.0143747)
		
		let regionRadius: CLLocationDistance = 1000
		
		let defaultRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
		
		mapView.setRegion(defaultRegion, animated: true)
		
        guard let index = selection else { return }
        let museum = exhibitsViewModel.getMuseum(index: index)
        
        if museum == "No museum listed" {
            return
        }
		
		// perform local search for museum by name, if it exists
		var request = MKLocalSearch.Request()
		request.naturalLanguageQuery = "\(museum) Washington DC"
		request.region = mapView.region
		var search = MKLocalSearch(request: request)
		
		search.start { [unowned self] response, _ in
			guard var response = response else {
				return
			}

			// create annotation and add to map
			var annotation = MKPointAnnotation()
			guard var result = response.mapItems.first?.placemark else { return }
			annotation.coordinate = result.coordinate
			annotation.title = "\(museum) \n \(result.title ?? "")"
			self.mapView.addAnnotation(annotation)
			self.museumPinLocation = annotation
			
			// recenter map on added annotation
			var region = MKCoordinateRegion(center: result.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
			self.mapView.setRegion(region, animated: true)
		}
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "addReminder" {
			var barViewControllers = segue.destination as! UITabBarController
			
				var destinationViewControllerOne = barViewControllers.viewControllers![0] as? TimeReminderViewController
				guard let detail = detailItem else { return }
				destinationViewControllerOne?.exhibit = detail
				destinationViewControllerOne?.openDate = openDateLabel.text
				destinationViewControllerOne?.closeDate = closeDateLabel.text
				
				var destinationViewControllerTwo = barViewControllers.viewControllers![1] as? LocationReminderViewController
				destinationViewControllerTwo?.exhibit = detail
				destinationViewControllerTwo?.openDate = openDateLabel.text
				destinationViewControllerTwo?.closeDate = closeDateLabel.text
				destinationViewControllerTwo?.museumLocation = museumPinLocation
				destinationViewControllerTwo?.region = mapView.region
			
			guard let currentReminder = ReminderManager.currentReminder else {
				// go to time reminder by default if there is no reminder
				barViewControllers.selectedIndex = 0
				return
			}
			
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
        guard let index = selection else { return }
        
        guard let url = exhibitsViewModel.getURL(index: index) else { return }
        
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}
	
	@IBAction func addReminderButtonTapped(_ sender: UIButton) {
		performSegue(withIdentifier: "addReminder", sender: Any?.self)
	}
	
}
