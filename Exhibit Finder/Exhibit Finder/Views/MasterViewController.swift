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

class MasterViewController: UITableViewController, ExhibitLoadDelegate, AlertDisplayDelegate {

	// MARK: IBOutlets
	
	@IBOutlet var noDataView: UIView!
    @IBOutlet var loadingView: UIView!
    
	// MARK: Variables
	
	var hasBeenLoaded = false
	var segmentedController: UISegmentedControl!
	var searchController = UISearchController(searchResultsController: nil)
    
    weak var reminderDelegate: ReminderDelegate?
    
    private let reminderViewModel = ReminderViewModel()
    private let exhibitsViewModel = ExhibitsViewModel()
    private let refreshController = UIRefreshControl()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		let items = ["Smithsonian Exhibits", "My Reminders"]
		segmentedController = UISegmentedControl(items: items)
		segmentedController.tintColor = UIColor(red: 1.00, green: 0.58, blue: 0.00, alpha: 1.0)
		segmentedController.selectedSegmentIndex = 0
		segmentedController.addTarget(self, action: #selector(segmentSelected), for: .valueChanged)
        navigationItem.titleView = segmentedController
		
        view.addSubview(loadingView)
        loadingView.center = CGPointMake(view.frame.width/2, view.frame.height/3)
        
		NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name(rawValue: "reload"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(reminderEdited), name: NSNotification.Name(rawValue: "reminderEdited"), object: nil)
    
        exhibitsViewModel.exhibitDelegate = self
        exhibitsViewModel.alertDelegate = self
        reminderViewModel.alertDelegate = self
        
        tableView.addSubview(refreshController)
        refreshController.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refreshController.tintColor = UIColor(red: 1.00, green: 0.58, blue: 0.00, alpha: 1.0)
        
        // search setup
		searchController.delegate = self
		searchController.searchResultsUpdater = self
		searchController.obscuresBackgroundDuringPresentation = false
		self.definesPresentationContext = true
		searchController.searchBar.placeholder = "Type to search . . ."
		navigationItem.searchController = searchController
		navigationItem.hidesSearchBarWhenScrolling = false
        
        exhibitsViewModel.setUpNetworkMonitor()
        
        if #available(iOS 16.0, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        } else {
            // Fallback on earlier versions
        }
	}
	
	override func viewWillAppear(_ animated: Bool) {
		clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
		super.viewWillAppear(animated)
		
		if hasBeenLoaded {
			return
		} else {
            reminderViewModel.deleteExpiredReminders()
            view.addSubview(loadingView)
            loadingView.center = CGPointMake(view.frame.width/2, view.frame.height/3)
            exhibitsViewModel.loadExhibitions()
		}
		
        reminderViewModel.loadReminders()
	}
	
	// MARK: Custom functions
	
	@objc func segmentSelected() {
        exhibitsViewModel.setSource(index: segmentedController.selectedSegmentIndex)
		
        tableView.reloadData()
        
		// return to top of table if new section has been loaded
		if tableView.visibleCells.isEmpty != true {
            self.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
		}
	}
    
    @objc func refresh() {
        if exhibitsViewModel.isListEmpty() && exhibitsViewModel.hasConnection() {
            tableView.reloadData()
            exhibitsViewModel.loadExhibitions()
        } else {
            print("end refreshing")
            refreshController.endRefreshing()
        }
    }
	
	@objc func reload() {
        reminderViewModel.loadReminders()
        tableView.reloadData()
	}
	
	// use to reload list of exhibits with reminders when a reminder has been edited
	@objc func reminderEdited() {
		if segmentedController.selectedSegmentIndex == 1 {
			tableView.reloadData()
		}
    }
    

	// MARK: - Segues

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
		    if let indexPath = tableView.indexPathForSelectedRow {
				let destinationViewController = (segue.destination as? UINavigationController)?.topViewController as? DetailViewController
				destinationViewController?.selection = indexPath
                exhibitsViewModel.setCurrentIndex(index: indexPath)
                print("segue index \(indexPath)")
		    }
		}
	}

	
	// MARK: IBActions
	
	@IBAction func viewAppInfoTapped(_ sender: UIButton) {
		performSegue(withIdentifier: "goToInfo", sender: Any?.self)
	}
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        var data = exhibitsViewModel.retrieveSource()
        
        if isFilteringBySearch() && segmentedController.selectedSegmentIndex == 1 {
            if data.isEmpty {
                tableView.separatorStyle = .none
            } else {
                tableView.separatorStyle = .singleLine
            }
            
            return data.count
        } else if segmentedController.selectedSegmentIndex == 1 {
            // no reminders
            if reminderViewModel.reminderCount() == 0 || data.isEmpty {
                tableView.backgroundView = noDataView
                tableView.separatorStyle = .none
            } else {
                tableView.separatorStyle = .singleLine
                tableView.backgroundView = nil
            }
            
            return data.count
        } else {
            tableView.separatorStyle = .singleLine
            tableView.backgroundView = nil
            
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let title = exhibitsViewModel.hasTitle(section: section) {
            return title
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // exhibit section, return count
        return exhibitsViewModel.getRows(isFiltering: isFilteringBySearch(), segment: segmentedController.selectedSegmentIndex, section: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "exhibitCell", for: indexPath) as! ExhibitTableViewCell
        
        cell.configure(index: indexPath, segment: segmentedController.selectedSegmentIndex, searchText: searchController.searchBar.text)
    
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
            reminderViewModel.setCurrentReminder(indexPath: indexPath)
            
            if tableView.numberOfRows(inSection: indexPath.section) == 1 {
                // there is only one reminder shown, delete it
                reminderViewModel.fullDelete()
                
                if isFilteringBySearch() {
                    exhibitsViewModel.deleteFromSearch(index: indexPath.section)
                }
                
                // delete entire section to prevent '0 row in section' warning
                tableView.deleteSections([indexPath.section], with: .fade)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
            } else {
                if indexPath.row == 0 {
                    reminderViewModel.resave(removing: .time)
                } else if indexPath.row == 1 { // if second, remove location based reminder
                    reminderViewModel.resave(removing: .location)
                }
                
                tableView.deleteRows(at: [indexPath], with: .fade)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
            }
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
}

// MARK: Extensions

extension MasterViewController {
    // delegate methods
    
    func displayAlert(with title: String, message: String) {
        showAlert(title: title, message: message)
    }
    
    func loadExhibits(success: Bool) {
        print("exhibit delegate called")
        if success {
            hasBeenLoaded = true
            tableView.reloadData()
            refresh()
        } else {
            tableView.separatorStyle = .singleLine
            tableView.backgroundView = nil
        }
       
        loadingView.removeFromSuperview()
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
        
        var type: DataType
        
        if segmentedController.selectedSegmentIndex == 0 {
            type = .exhibitsOnly
        } else {
            type = .exhibitsWithReminders
        }
        
        exhibitsViewModel.setData(type: type, searchText: searchController.searchBar.text)
		
		tableView.reloadData()
        
		// scroll to top upon showing results
        if !exhibitsViewModel.isSearchEmpty() {
            self.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
		}
	}
	
	func isFilteringBySearch() -> Bool {
		return searchController.isActive && !searchBarIsEmpty()
	}
	
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		searchBar.endEditing(true)
	}
}
