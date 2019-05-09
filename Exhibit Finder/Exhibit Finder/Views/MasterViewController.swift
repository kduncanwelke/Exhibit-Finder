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
import Nuke
import XMLParsing

class MasterViewController: UITableViewController {

	// MARK: IBOutlets
	
	@IBOutlet var noDataView: UIView!
	
	var detailViewController: DetailViewController? = nil
	
	// MARK: Variables
	
	var exhibitsList: [Exhibit] = []
	var currentDate = Date()
	let dateFormatter = ISO8601DateFormatter()
	let timeDateFormatter = DateFormatter()
	var hasBeenLoaded = false
	var segmentedController: UISegmentedControl!
	let searchController = UISearchController(searchResultsController: nil)
	var searchResults = [Exhibit]()
	var activityIndicator = UIActivityIndicatorView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		let items = ["Smithsonian Exhibits", "My Reminders"]
		segmentedController = UISegmentedControl(items: items)
		segmentedController.tintColor = UIColor(red:1.00, green:0.58, blue:0.00, alpha:1.0)
		segmentedController.selectedSegmentIndex = 0
		navigationItem.titleView = segmentedController
		segmentedController.addTarget(self, action: #selector(segmentSelected), for: .valueChanged)
		
		NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name(rawValue: "reload"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(reminderEdited), name: NSNotification.Name(rawValue: "reminderEdited"), object: nil)
		
		// search setup
		searchController.delegate = self
		searchController.searchResultsUpdater = self
		searchController.obscuresBackgroundDuringPresentation = false
		self.definesPresentationContext = true
		searchController.searchBar.placeholder = "Type to search . . ."
		navigationItem.searchController = searchController
		navigationItem.hidesSearchBarWhenScrolling = false
		
		timeDateFormatter.dateFormat = "yyyy-MM-dd 'at' hh:mm a"
		//let currentDate = Date()
		
		activityIndicator.color = .gray
		tableView.backgroundView = activityIndicator
		
		if let split = splitViewController {
		    let controllers = split.viewControllers
		    detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
			detailViewController = nil
			
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
	
	// MARK: Custom functions
	
	@objc func segmentSelected() {
		tableView.reloadData()
	}
	
	func loadExhibitions() {
		activityIndicator.startAnimating()
		DataManager<Exhibits>.fetch() { [unowned self] result in
			switch result {
			case .success(let response):
				DispatchQueue.main.async {
					guard let response = response.first?.exhibits else {
						self.showAlert(title: "Connection failed", message: "XML response failed, please try again later.")
						return
					}
					
					for exhibit in response {
						// disclude museums outside of Washington DC
						if exhibit.museum != "Cooper Hewitt, Smithsonian Design Museum" && exhibit.museum != "Air and Space Museum Udvar-Hazy Center" && exhibit.museum != "American Indian Museum Heye Center" {
							self.exhibitsList.append(exhibit)
						}
						
						/*guard let openDate = self.getDate(from: exhibit.attributes.openDate), let closeDate = self.getDate(from: exhibit.attributes.closeDate) else {
							return
						}
						
						if openDate <= self.currentDate && closeDate >= self.currentDate {
							self.exhibitsList.append(exhibit)
						} else if openDate > self.currentDate {
							ReminderManager.upcomingExhibits.append(exhibit)
						}*/
						
						if ReminderManager.reminders.contains(where: { $0.id == exhibit.id }) {
							ReminderManager.exhibitsWithReminders.append(exhibit)
						} else {
							// not
						}
					}
					self.hasBeenLoaded = true
					self.tableView.reloadData()
					
					self.activityIndicator.stopAnimating()
				}
			case .failure(let error):
				DispatchQueue.main.async {
					switch error {
					case Errors.networkError:
						self.showAlert(title: "Networking failed", message: "\(Errors.networkError.localizedDescription)")
						self.activityIndicator.stopAnimating()
					default:
						self.showAlert(title: "Networking failed", message: "\(Errors.otherError.localizedDescription)")
						self.activityIndicator.stopAnimating()
					}
				}
			}
		}
	}
	
	@objc func reload() {
		loadReminders()
	}
	
	// use to reload list of exhibits with reminders when a reminder has been edited
	@objc func reminderEdited() {
		if segmentedController.selectedSegmentIndex == 1 {
			tableView.reloadData()
		}
	}

	func deleteExpiredReminders() {
		let managedContext = CoreDataManager.shared.managedObjectContext
		let fetchRequest = NSFetchRequest<Reminder>(entityName: "Reminder")
		let now = Date()
		
		fetchRequest.predicate = NSPredicate(format: "invalidDate < %@", now as CVarArg)
		
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
	
		// if section 1 (where deletion occurs) is selected, don't reload table view as it breaks fade animation
		if segmentedController.selectedSegmentIndex != 1 {
			tableView.reloadData()
		}
	}
	
	func resave() {
		let managedContext = CoreDataManager.shared.managedObjectContext
		
		do {
			try managedContext.save()
			print("resave successful")
		} catch {
			// this should never be displayed but is here to cover the possibility
			showAlert(title: "Save failed", message: "Notice: Data has not successfully been saved.")
		}
	}
	
	func fullDelete(result: Reminder) {
		let managedContext = CoreDataManager.shared.managedObjectContext
		
		clearNotification(result: result)
		endLocationMonitoring(result: result)
		
		managedContext.delete(result)
		
		do {
			try managedContext.save()
			print("delete successful")
		} catch {
			print("Failed to save")
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
	}
	
	
	// turn date into string to pass into search
	func getDate(from stringDate: String) -> Date? {
		guard let createdDate = dateFormatter.date(from: stringDate) else {
			print("date conversion failed")
			return nil
		}
		return createdDate
	}
	
	// get string from date
	func getStringDate(from date: Date) -> String {
		let createdDate = timeDateFormatter.string(from: date)
		return createdDate
	}

	// MARK: - Segues

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
		    if let indexPath = tableView.indexPathForSelectedRow {
				
				var object: Exhibit
				if isFilteringBySearch() {
					object = searchResults[indexPath.row]
				} else if segmentedController.selectedSegmentIndex == 0 {
					object = exhibitsList[indexPath.row]
				} else {
					object = ReminderManager.exhibitsWithReminders[indexPath.section]
				}
				
				if let result = ReminderManager.reminders.first(where: { Int($0.id) == object.id }) {
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
		if exhibitsList.isEmpty {
			tableView.backgroundView = activityIndicator
			tableView.separatorStyle = .none
			return 1
		} else if isFilteringBySearch() && segmentedController.selectedSegmentIndex == 1 {
			tableView.separatorStyle = .singleLine
			return searchResults.count
		} else if segmentedController.selectedSegmentIndex == 1 {
			if ReminderManager.reminders.count == 0 {
				tableView.backgroundView = noDataView
				tableView.separatorStyle = .none
			} else {
				tableView.separatorStyle = .singleLine
				tableView.backgroundView = nil
			}
			return ReminderManager.exhibitsWithReminders.count
		} else {
			tableView.separatorStyle = .singleLine
			tableView.backgroundView = nil
			return 1
		}
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if isFilteringBySearch() && segmentedController.selectedSegmentIndex == 1 {
			return searchResults[section].exhibit
		} else if isFilteringBySearch() {
			return nil
		} else if segmentedController.selectedSegmentIndex == 1 {
			return ReminderManager.exhibitsWithReminders[section].exhibit
		} else {
			return nil
		}
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if isFilteringBySearch() && segmentedController.selectedSegmentIndex == 1 {
			let result = ReminderManager.reminders.first(where: { $0.id == searchResults[section].id })
			if result?.time != nil && result?.location != nil {
				return 2
			} else {
				return 1
			}
		} else if isFilteringBySearch() {
			return searchResults.count
		} else if segmentedController.selectedSegmentIndex == 0 {
			return exhibitsList.count
		} else {
			let result = ReminderManager.reminders.first(where: { $0.id == ReminderManager.exhibitsWithReminders[section].id })
			if result?.time != nil && result?.location != nil {
				return 2
			} else {
				return 1
			}
		}
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "exhibitCell", for: indexPath) as! ExhibitTableViewCell

		var object: Exhibit
		
		// check if items are being filtered or not, and use appropriate array
		if isFilteringBySearch() && segmentedController.selectedSegmentIndex == 1 {
			object = searchResults[indexPath.section]
		} else if isFilteringBySearch() && segmentedController.selectedSegmentIndex == 0 {
			object = searchResults[indexPath.row]
		} else if segmentedController.selectedSegmentIndex == 0 {
			object = exhibitsList[indexPath.row]
		} else {
			object = ReminderManager.exhibitsWithReminders[indexPath.section]
		}
		
		// change cell title color if reminders segment
		if segmentedController.selectedSegmentIndex == 1 {
			cell.title.textColor = UIColor(red:0.44, green:0.44, blue:0.47, alpha:1.0)
		} else {
			cell.title.textColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:1.0)
		}
		
		if let title = object.exhibit {
			let decoded = title.decodingHTMLEntities()
			cell.title.text = String.removeHTMLWithoutSpacing(from: decoded)
		} else {
			cell.title.text = "No title"
		}
		
		cell.activityIndicator.startAnimating()
		if let urlString = object.imgUrl, let urlToLoad = URL(string: urlString) {
			// load image with Nuke
			Nuke.loadImage(with: urlToLoad, options: NukeOptions.options, into: cell.cellImage) { response, _ in
				cell.cellImage?.image = response?.image
				cell.activityIndicator.stopAnimating()
			}
		}
		
		cell.musuem.text = object.museum ?? "No museum listed"
		
		if let data = object.infoBrief {
			let decoded = data.decodingHTMLEntities()
			cell.briefInfo.text = String.removeHTMLWithoutSpacing(from: decoded)
		} else {
			cell.briefInfo.text = "No description available"
		}
		
		if let close = object.closingDate?.dropLast(11) {
			cell.closeDate.text = "\(close)"
		} else if (object.closeText?.contains("Indefinitely")) != nil {
			cell.closeDate.text = "Permanent exhibit"
		}
		
		// set text to show reminder if one matches
		if let result = ReminderManager.reminders.first(where: { $0.id == object.id }) {
			if segmentedController.selectedSegmentIndex == 1 {
				if (result.time != nil && result.location != nil && indexPath.row == 0) || (result.time != nil && result.location == nil) {
					// configure time reminder cell
					cell.hasReminder.text = "Time"
					cell.reminderImage.image = UIImage(named: "clockicon25")
					if let date = result.time {
						let calendar = Calendar.current
						let components = DateComponents(year: Int(date.year), month: Int(date.month), day: Int(date.day), hour: Int(date.hour), minute: Int(date.minute))
						
						if let dateToUse = calendar.date(from: components), let invalid = result.invalidDate {
							if dateToUse < currentDate || invalid < currentDate {
								cell.title.text = "This reminder has expired"
							} else {
								let stringDate = getStringDate(from: dateToUse)
								cell.title.text = "For \(stringDate)"
							}
						}
					}
				} else if (result.time != nil && result.location != nil && indexPath.row == 1) || (result.time == nil && result.location != nil) {
					// configure location reminder cell
					cell.hasReminder.text = "Location"
					cell.reminderImage.image = UIImage(named: "locationicon25")
					if let invalid = result.invalidDate {
						if invalid < currentDate {
							cell.title.text = "This reminder has expired"
						} else {
							if let radius = result.location?.radius {
								cell.title.text = "Within \(Int(radius)) foot radius of museum"
							}
						}
					}
				}
			} else {
				// for non-reminder view, show if a reminder exists
				cell.hasReminder.text = "Reminder"
				if result.time != nil && result.location != nil {
					cell.reminderImage.image = UIImage(named: "both25")
				} else if result.time != nil && result.location == nil {
					cell.reminderImage.image = UIImage(named: "clockicon25")
				} else if result.time == nil && result.location != nil {
					cell.reminderImage.image = UIImage(named: "locationicon25")
				}
			}
		} else {
			// otherwise reminder does not exist
			cell.hasReminder.text = "No Reminder"
			cell.reminderImage.image = nil
		}

		return cell
	}

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		if segmentedController.selectedSegmentIndex == 0 {
			return false
		} else {
			return true
		}
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			var result: Reminder?
			
			if isFilteringBySearch() {
				if let reminder = ReminderManager.reminders.first(where: { $0.id == searchResults[indexPath.section].id }) {
					result = reminder
				}
			} else {
				if let reminder = ReminderManager.reminders.first(where: { $0.id == ReminderManager.exhibitsWithReminders[indexPath.section].id }) {
					result = reminder
				}
			}
				
			if isFilteringBySearch() && tableView.numberOfRows(inSection: indexPath.section) == 1 {
				// remove exhibit from list of exhibits with reminders
				guard let result = result else { return }
				let new = ReminderManager.exhibitsWithReminders.filter({ $0.id != result.id })
				ReminderManager.exhibitsWithReminders = new
				ReminderManager.currentReminder = nil
				
				fullDelete(result: result)
				searchResults.remove(at: indexPath.section)
				
				tableView.deleteSections([indexPath.section], with: .fade)
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
			} else if isFilteringBySearch() == false && tableView.numberOfRows(inSection: indexPath.section) == 1 {
				guard let result = result else { return }
				// if there is only one reminder shown, delete it
					fullDelete(result: result)
					
					ReminderManager.exhibitsWithReminders.remove(at: indexPath.section)
					ReminderManager.currentReminder = nil
					
					// delete entire section to prevent '0 row in section' warning
					tableView.deleteSections([indexPath.section], with: .fade)
					NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
			} else {
				guard let result = result else { return }
				if indexPath.row == 0 {
					result.time = nil
					clearNotification(result: result)
				} else if indexPath.row == 1 { // if second, remove location based reminder
					endLocationMonitoring(result: result)
					result.location = nil
				}
				
				resave()
				tableView.deleteRows(at: [indexPath], with: .fade)
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
			}
			
		} else if editingStyle == .insert {
		    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
		}
	}
}

// MARK: Extensions

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
		var exhibitions: [Exhibit]
		
		if segmentedController.selectedSegmentIndex == 0 {
			exhibitions = exhibitsList
		} else {
			exhibitions = ReminderManager.exhibitsWithReminders
		}
		
		searchResults = exhibitions.filter({(exhibit: Exhibit) -> Bool in
			return (exhibit.exhibit?.lowercased().contains(searchText.lowercased()))! || (exhibit.info?.lowercased().contains(searchText.lowercased()))!
		})
		
		tableView.reloadData()
		
		// scroll to top upon showing results
		if searchResults.count != 0 {
			let indexPath = IndexPath(row: 0, section: 0)
			self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
		}
	}
	
	func isFilteringBySearch() -> Bool {
		return searchController.isActive && !searchBarIsEmpty()
	}
	
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		searchBar.endEditing(true)
	}
}
