//
//  MasterViewController.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/6/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

	var detailViewController: DetailViewController? = nil
	
	// MARK: Variables
	
	var exhibitsList: [Exhibition] = []
	var upcomingExhibits: [Exhibition] = []
	var currentDate = Date()
	let dateFormatter = ISO8601DateFormatter()
	var hasBeenLoaded = false
	

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		navigationItem.leftBarButtonItem = editButtonItem

		let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
		navigationItem.rightBarButtonItem = addButton
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
			loadExhibitions()
		}
	}
	
	@objc
	func insertNewObject(_ sender: Any) {
		//objects.insert(NSDate(), at: 0)
		//let indexPath = IndexPath(row: 0, section: 0)
		//tableView.insertRows(at: [indexPath], with: .automatic)
	}
	
	// MARK: Custom functions
	
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
		        let object = exhibitsList[indexPath.row]
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
		return exhibitsList.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "exhibitCell", for: indexPath) as! ExhibitTableViewCell

		let object = exhibitsList[indexPath.row]
		cell.title.text = object.attributes.title
		cell.musuem.text = object.attributes.museum ?? "No museum listed"
		let open = object.attributes.openDate.dropLast(14)
		cell.openDate.text = "\(open)"
		let close = object.attributes.closeDate.dropLast(14)
		cell.closeDate.text = "\(close)"
		return cell
	}

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		return true
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
		    exhibitsList.remove(at: indexPath.row)
		    tableView.deleteRows(at: [indexPath], with: .fade)
		} else if editingStyle == .insert {
		    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
		}
	}


}

