//
//  TimeReminderViewController.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/10/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class TimeReminderViewController: UIViewController {

	// MARK: IBOutlets
	
	@IBOutlet weak var datePicker: UIDatePicker!
	@IBOutlet weak var exhibitName: UILabel!
	@IBOutlet weak var museumName: UILabel!
	@IBOutlet weak var time: UILabel!
	@IBOutlet weak var reminderSelected: UILabel!
	@IBOutlet weak var confirmButton: UIButton!
	
	// MARK: Variables
	
	var exhibit: Exhibition?
	var openDate: String?
	var closeDate: String?
	let dateFormatter = DateFormatter()
	let timeDateFormatter = DateFormatter()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
        // Do any additional setup after loading the view.
		datePicker.addTarget(self, action: #selector(datePickerChanged(picker:)), for: .valueChanged)
		confirmButton.layer.cornerRadius = 10
		dateFormatter.dateFormat = "yyyy-MM-dd"
		timeDateFormatter.dateFormat = "yyyy-MM-dd 'at' hh:mm a"
		
		guard let selectedExhibit = exhibit, let open = openDate, let close = closeDate else { return }
			exhibitName.text = selectedExhibit.attributes.title
			museumName.text = selectedExhibit.attributes.museum ?? "Not applicable"
		
			let minDate = Date()
		
			guard let convertedOpenDate = dateFormatter.date(from: open) else { return }
				if convertedOpenDate > minDate {
					time.text = "\(open) to \(close)"
				} else {
					time.text = "Today to \(close)"
				}
		
				let maxDate = getDate(from: close)
		
				datePicker.minimumDate = minDate
				datePicker.maximumDate = maxDate
		
				reminderSelected.text = getStringDate(from: datePicker.date)
		
			if let result = ReminderManager.reminders.first(where: { $0.id == selectedExhibit.attributes.path.pid }) {
				guard let date = result.time else { return }
				ReminderManager.currentReminder = result
				
				let calendar = Calendar.current
				let components = DateComponents(year: Int(date.year), month: Int(date.month), day: Int(date.day), hour: Int(date.hour), minute: Int(date.minute))
		
				guard let dateToUse = calendar.date(from: components) else { return }
				reminderSelected.text = getStringDate(from: dateToUse)
				datePicker.date = dateToUse
				confirmButton.setTitle("Save Changes", for: .normal)
			} else {
				ReminderManager.currentReminder = nil
			}
    }
	

	// MARK: Custom functions
	@objc func datePickerChanged(picker: UIDatePicker) {
		reminderSelected.text = getStringDate(from: datePicker.date)
	}
	
	
	// turn date into string to display
	func getDate(from stringDate: String) -> Date? {
		guard let createdDate = dateFormatter.date(from: stringDate) else {
			print("date conversion failed")
			return nil
		}
		return createdDate
	}
	
	func getStringDate(from date: Date) -> String {
		let createdDate = timeDateFormatter.string(from: date)
		return createdDate
	}
	
	func saveEntry() {
		let managedContext = CoreDataManager.shared.managedObjectContext
		
		// save new entry if no reminder is being edited
		guard let currentReminder = ReminderManager.currentReminder else {
			let newReminder = Reminder(context: managedContext)
			
			var time: Time?
			time = Time(context: managedContext)
			
			getTimeForReminder(time: time)
			newReminder.time = time
			getExhibitData(reminder: newReminder)
			
			do {
				try managedContext.save()
				print("saved")
			} catch {
				// this should never be displayed but is here to cover the possibility
				showAlert(title: "Save failed", message: "Notice: Data has not successfully been saved.")
			}
			
			// add notification
			NotificationManager.addTimeBasedNotification(for: newReminder)
			
			return
		}
	
		// otherwise overwrite existing item with new time selection
		guard let time = currentReminder.time else { return }
		getTimeForReminder(time: time)
		currentReminder.time = time
	
		do {
			try managedContext.save()
			print("resave successful")
		} catch {
			// this should never be displayed but is here to cover the possibility
			showAlert(title: "Save failed", message: "Notice: Data has not successfully been saved.")
		}
		
		// remove existing notification, so notifs aren't doubled
		let notificationCenter = UNUserNotificationCenter.current()
		//notificationCenter.removePendingNotificationRequests(withIdentifiers: ["\(currentReminder.id)"])
		
		// add notification anew
		NotificationManager.addTimeBasedNotification(for: currentReminder)
		
		notificationCenter.getPendingNotificationRequests(completionHandler: { requests in
			for request in requests {
				print(request)
			}
		})
	}
	
	func getExhibitData(reminder: Reminder) {
		guard let currentExhibit = exhibit, let open = openDate, let close = closeDate else { return }
		reminder.name = currentExhibit.attributes.title
		reminder.id = Int64(currentExhibit.attributes.path.pid)
		reminder.startDate = dateFormatter.date(from: open)
		reminder.invalidDate = dateFormatter.date(from: close)
	}
	
	func getTimeForReminder(time: Time?) {
		let date = datePicker.date
		let calendar = Calendar.current
		let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
		
		guard let year = components.year, let month = components.month, let day = components.day, let hour = components.hour, let minute = components.minute else { return }
		time?.year = Int32(year)
		time?.month = Int32(month)
		time?.day = Int32(day)
		time?.hour = Int32(hour)
		time?.minute = Int32(minute)
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
	
	@IBAction func confirmButtonTapped(_ sender: UIButton) {
		let currentDate = Date()
		if datePicker.date <= currentDate.addingTimeInterval(500) {
			showAlert(title: "Cannot save reminder", message: "Please select a date that is in the future - the current date and time cannot be used")
			return
		} else {
			saveEntry()
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateButton"), object: nil)
			guard let exhibitWithReminder = exhibit else { return }
			ReminderManager.exhibitsWithReminders.append(exhibitWithReminder)
			dismiss(animated: true, completion: nil)
		}
	}
	
	@IBAction func cancelButtonTapped(_ sender: UIButton) {
		dismiss(animated: true, completion: nil)
	}
	
}
