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
            reminderButton.isEnabled = true
            viewOnlineButton.isEnabled = true
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
        mapView.setRegion(LocationManager.getRegion(), animated: true)
		
        guard let index = selection else { return }
        let museum = exhibitsViewModel.getMuseum(index: index)
        
        if museum == "No museum listed" {
            return
        }
		
		// perform local search for museum by name, if it exists
        LocationManager.performSearch(museum: museum, mapView: mapView, withOverlay: false)
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "addReminder" {
			var barViewControllers = segue.destination as! UITabBarController
            
            guard let index = selection else { return }
            
            // pass indexpath along to both views, map data to location view
            var destinationViewControllerOne = barViewControllers.viewControllers![0] as? TimeReminderViewController
            destinationViewControllerOne?.selection = index
            
            var destinationViewControllerTwo = barViewControllers.viewControllers![1] as? LocationReminderViewController
            destinationViewControllerTwo?.selection = index
            
            // there is a reminder
            if let reminder = exhibitsViewModel.getReminderForExhibit(index: index) {
                
                var type: WithReminder
                guard let typeOfReminder = reminderViewModel.getReminderType() else { return }
                
                type = typeOfReminder
                    
                // set selected view based on which reminders exist
                switch type {
                case .both, .time:
                    // go to time reminder if there is a time reminder or both time and location
                    barViewControllers.selectedIndex = 0
                case .location:
                    barViewControllers.selectedIndex = 1
                }
            } else {
                // there is no reminder
                // go to time reminder by default if there is no reminder
                barViewControllers.selectedIndex = 0
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
