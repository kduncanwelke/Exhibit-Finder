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
	
	var museumPinLocation: MKPointAnnotation?
    
    private let reminderViewModel = ReminderViewModel()
    private let exhibitsViewModel = ExhibitsViewModel()
    private let detailViewModel = DetailViewModel()
    var selection: IndexPath?

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
        guard let index = exhibitsViewModel.getCurrentIndex() else {
            // if there is no selection, set button titles appropriately
            viewOnlineButton.setTitle("No Selection", for: .normal)
            viewOnlineButton.isEnabled = false
            reminderButton.setTitle(" No Selection ", for: .normal)
            return
        }
        
        if let reminder = exhibitsViewModel.getReminderForExhibit(indexPath: index) {
            print("reminder for exhibit")
            print(reminder)
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
				Nuke.loadImage(with: url, options: NukeOptions.options, into: self.exhibitImage) { [unowned self] response, completed, total in
					if response != nil {
                        self.exhibitImage.image = response?.image
					} else {
                        self.exhibitImage.image = NukeOptions.options.failureImage
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
        detailViewModel.loadMapView(mapView: mapView, selection: index)
	}
	
	@objc func updateButton() {
		reminderButton.setTitle("Edit Reminder", for: .normal)
        guard let index = exhibitsViewModel.getCurrentIndex() else { return }
        titleLabel.text = exhibitsViewModel.getTitle(index: index)
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "addReminder" {
			var barViewControllers = segue.destination as! UITabBarController
            
            guard let index = exhibitsViewModel.getCurrentIndex() else { return }
            
            barViewControllers.selectedIndex = detailViewModel.setSelectedBarViewController(index: index)
		}
	}
	
	// MARK: IBActions
	
	@IBAction func viewOnlineButtonTapped(_ sender: UIButton) {
        guard let index = exhibitsViewModel.getCurrentIndex() else { return }
        
        guard let url = exhibitsViewModel.getURL(index: index) else { return }
        
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}
	
	@IBAction func addReminderButtonTapped(_ sender: UIButton) {
		performSegue(withIdentifier: "addReminder", sender: Any?.self)
	}
	
}
