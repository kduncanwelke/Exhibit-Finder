//
//  MasterViewController.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/6/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import CoreLocation

class MasterViewController: UITableViewController {

	var detailViewController: DetailViewController? = nil
	
	// MARK: Variables
	
	var exhibitsList: [Exhibition] = []
	var upcomingExhibits: [Exhibition] = []
	var currentDate = Date()
	let dateFormatter = ISO8601DateFormatter()
	var hasBeenLoaded = false
	var segmentedController: UISegmentedControl!
	let searchController = UISearchController(searchResultsController: nil)
	var searchResults = [Exhibition]()

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		let items = ["Current", "Upcoming", "My Reminders"]
		segmentedController = UISegmentedControl(items: items)
		segmentedController.tintColor = UIColor(red:1.00, green:0.58, blue:0.00, alpha:1.0)
		segmentedController.selectedSegmentIndex = 0
		navigationItem.titleView = segmentedController
		segmentedController.addTarget(self, action: #selector(segmentSelected), for: .valueChanged)
		
		NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name(rawValue: "reload"), object: nil)
		
		// search setup
		searchController.delegate = self
		searchController.searchResultsUpdater = self
		searchController.obscuresBackgroundDuringPresentation = false
		searchController.searchBar.placeholder = "Type to search . . ."
		navigationItem.searchController = searchController
		navigationItem.hidesSearchBarWhenScrolling = false
		searchController.definesPresentationContext = true
		
		if let split = splitViewController {
		    let controllers = split.viewControllers
		    detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
			
			// handle split view behavior
			if split.displayMode == .primaryHidden {
				split.preferredDisplayMode = .allVisible
				// prevent collapsing to detail
			} else {
				return
			}
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
		super.viewWillAppear(animated)
		
		if hasBeenLoaded {
			return
		} else {
			deleteExpiredReminders()
			loadExhibitions()
		}
		
		loadReminders()
	}
	
	@objc
	func insertNewObject(_ sender: Any) {
		//objects.insert(NSDate(), at: 0)
		//let indexPath = IndexPath(row: 0, section: 0)
		//tableView.insertRows(at: [indexPath], with: .automatic)
	}
	
	// MARK: Custom functions
	
	@objc func segmentSelected() {
		tableView.reloadData()
	}
	
	func loadExhibitions() {
		DataManager<Exhibit>.fetch(with: nil) { [unowned self] result in
			switch result {
			case .success(let response):
				DispatchQueue.main.async {
					guard let response = response.first?.data else {
						self.showAlert(title: "Connection failed", message: "Json response failed, please try again later.")
						return
					}
					
					for exhibit in response {
						guard let openDate = self.getDate(from: exhibit.attributes.openDate), let closeDate = self.getDate(from: exhibit.attributes.closeDate) else {
							return
						}
						
						if openDate <= self.currentDate && closeDate >= self.currentDate {
							self.exhibitsList.append(exhibit)
						} else if openDate > self.currentDate {
							self.upcomingExhibits.append(exhibit)
						}
						
						if ReminderManager.reminders.contains(where: { $0.id == exhibit.attributes.path.pid }) {
							ReminderManager.exhibitsWithReminders.append(exhibit)
						} else {
							// not
						}
					}
					self.hasBeenLoaded = true
					self.tableView.reloadData()
				}
			case .failure(let error):
				DispatchQueue.main.async {
					switch error {
					case Errors.networkError:
						self.showAlert(title: "Networking failed", message: "\(Errors.networkError.localizedDescription)")
					default:
						self.showAlert(title: "Networking failed", message: "\(error.localizedDescription)")
					}
				}
			}
		}
	}
	
	@objc func reload() {
		loadReminders()
	}

	func deleteExpiredReminders() {
		let managedContext = CoreDataManager.shared.managedObjectContext
		let fetchRequest = NSFetchRequest<Reminder>(entityName: "Reminder")
		let now = Date()
		//let calendar = Calendar.current
		//var dateComponents = DateComponents()
		//dateComponents.month = 8
		//dateComponents.day = 18
		//guard let now = calendar.date(from: dateComponents) else { return }
		fetchRequest.predicate = NSPredicate(format: "invalidDate > %@", now as CVarArg)
		
		var remindersToDelete: [Reminder] = []
		do {
			remindersToDelete = try managedContext.fetch(fetchRequest)
		} catch let error as NSError {
			print("could not fetch, \(error), \(error.userInfo)")
		}
		
		if remindersToDelete.count > 0 {
			for reminder in remindersToDelete {
				managedContext.delete(reminder)
				print("deleted")
				
				// clear notifications and geofenced areas associated with reminder
				clearNotification(result: reminder)
				endLocationMonitoring(result: reminder)
			}
			
			do {
				try managedContext.save()
			} catch {
				print("Failed to save")
			}
		} else {
			return
		}
		
	}
	
	func endLocationMonitoring(result: Reminder) {
		if let location = result.location, let name = result.name {
			LocationManager.stopMonitoringRegion(latitude: location.latitude, longitude: location.longitude, exhibitName: name, radius: location.radius)
			print("stopped monitoring")
		}
	}
	
	func clearNotification(result: Reminder) {
		// remove existing time-based notification
		let notificationCenter = UNUserNotificationCenter.current()
		let identifier = "\(result.id)"
		notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
		
		notificationCenter.getPendingNotificationRequests(completionHandler: { notifs in
			for notif in notifs {
				print(notif)
			}
		})
		
	}
	
	// load reminders from core data
	func loadReminders() {
		let managedContext = CoreDataManager.shared.managedObjectContext
		let fetchRequest = NSFetchRequest<Reminder>(entityName: "Reminder")
		
		do {
			ReminderManager.reminders = try managedContext.fetch(fetchRequest)
			print("reminders loaded")
		} catch let error as NSError {
			showAlert(title: "Could not retrieve data", message: "\(error.userInfo)")
		}
	
		// if section 2 (where deletion occurs) is selected, don't reload table view as it breaks fade animation
		if segmentedController.selectedSegmentIndex != 2 {
			tableView.reloadData()
		}
	}

	
	// turn date into string to pass into search
	func getDate(from stringDate: String) -> Date? {
		guard let createdDate = dateFormatter.date(from: stringDate) else {
			print("date conversion failed")
			return nil
		}
		return createdDate
	}

	// MARK: - Segues

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
		    if let indexPath = tableView.indexPathForSelectedRow {
				
				var object: Exhibition
				if segmentedController.selectedSegmentIndex == 0 {
					object = exhibitsList[indexPath.row]
				} else if segmentedController.selectedSegmentIndex == 1 {
					object = upcomingExhibits[indexPath.row]
				} else {
					object = ReminderManager.exhibitsWithReminders[indexPath.row]
				}
				
				if let result = ReminderManager.reminders.first(where: { $0.id == object.attributes.path.pid }) {
					ReminderManager.currentReminder = result
				} else {
					ReminderManager.currentReminder = nil
				}
				
				let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
				
				controller.detailItem = object
		        controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
		        controller.navigationItem.leftItemsSupplementBackButton = true
		    }
		}
	}

	// MARK: - Table View

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if isFilteringBySearch() {
			return searchResults.count
		} else if segmentedController.selectedSegmentIndex == 0 {
			return exhibitsList.count
		} else if segmentedController.selectedSegmentIndex == 1{
			return upcomingExhibits.count
		} else {
			return ReminderManager.exhibitsWithReminders.count
		}
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "exhibitCell", for: indexPath) as! ExhibitTableViewCell

		var object: Exhibition
		
		// check if items are being filtered or not, and use appropriate array
		if isFilteringBySearch() {
			object = searchResults[indexPath.row]
		} else if segmentedController.selectedSegmentIndex == 0 {
			object = exhibitsList[indexPath.row]
		} else if segmentedController.selectedSegmentIndex == 1 {
			object = upcomingExhibits[indexPath.row]
		} else {
			object = ReminderManager.exhibitsWithReminders[indexPath.row]
		}
		
		cell.title.text = object.attributes.title
		cell.musuem.text = object.attributes.museum ?? "No museum listed"
		let open = object.attributes.openDate.dropLast(14)
		cell.openDate.text = "\(open)"
		let close = object.attributes.closeDate.dropLast(14)
		cell.closeDate.text = "\(close)"
		
		if ReminderManager.reminders.isEmpty {
			cell.hasReminder.text = "No Reminder"
		} else {
			// set text to show reminder if one matches
			if ReminderManager.reminders.contains(where: { $0.id == object.attributes.path.pid }) {
				cell.hasReminder.text = "Reminder Set"
			} else {
				cell.hasReminder.text = "No Reminder"
			}
		}

		return cell
	}

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		if segmentedController.selectedSegmentIndex == 0 || segmentedController.selectedSegmentIndex == 1 {
			return false
		} else {
			return true
		}
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			let managedContext = CoreDataManager.shared.managedObjectContext
			
			if let result = ReminderManager.reminders.first(where: { $0.id == ReminderManager.exhibitsWithReminders[indexPath.row].attributes.path.pid }) {
				
				clearNotification(result: result)
				endLocationMonitoring(result: result)
				
				managedContext.delete(result)
				
				do {
					try managedContext.save()
				} catch {
					print("Failed to save")
				}
			
				ReminderManager.exhibitsWithReminders.remove(at: indexPath.row)
				ReminderManager.currentReminder = nil
				tableView.deleteRows(at: [indexPath], with: .fade)
				
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
			}
		} else if editingStyle == .insert {
		    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
		}
	}
}

extension MasterViewController: UISearchControllerDelegate, UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		guard let searchText = searchController.searchBar.text else { return }
		filterSearch(searchText)
	}
	
	func searchBarIsEmpty() -> Bool {
		return searchController.searchBar.text?.isEmpty ?? true
	}
	
	// return search results based on title and entry body text
	func filterSearch(_ searchText: String) {
		var exhibitions: [Exhibition]
		
		if segmentedController.selectedSegmentIndex == 0 {
			exhibitions = exhibitsList
		} else if segmentedController.selectedSegmentIndex == 1 {
			exhibitions = upcomingExhibits
		} else {
			exhibitions = ReminderManager.exhibitsWithReminders
		}
		
		searchResults = exhibitions.filter({(exhibit: Exhibition) -> Bool in
			return exhibit.attributes.title.lowercased().contains(searchText.lowercased()) || exhibit.attributes.description.processed.lowercased().contains(searchText.lowercased())
		})
		tableView.reloadData()
	}
	
	func isFilteringBySearch() -> Bool {
		return searchController.isActive && !searchBarIsEmpty()
	}
	
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		searchBar.endEditing(true)
	}
}
