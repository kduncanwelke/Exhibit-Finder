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
	
	var exhibit: Exhibit?
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
		
		configureView()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		// check if notifications are enabled, as this is the first point of use
		UNUserNotificationCenter.current().getNotificationSettings(){ [unowned self] (settings) in
			switch settings.alertSetting {
			case .enabled:
				break
			case .disabled:
				DispatchQueue.main.async {
				self.showSettingsAlert(title: "Notifications disabled", message: "Time-based reminders require access to notification sevices to provide notifications of exhibits. These notifications will not be displayed unless settings are adjusted.")
				}
			case .notSupported:
				DispatchQueue.main.async {
				self.showSettingsAlert(title: "Notifications not supported", message: "Notifications will not be displayed, as the service is not available on this device.")
				}
			@unknown default:
				return
			}
		}
	}
	

	// MARK: Custom functions
	
	func configureView() {
		guard let selectedExhibit = exhibit, let close = closeDate else { return }
		exhibitName.text = selectedExhibit.exhibit
		museumName.text = selectedExhibit.museum ?? "Not applicable"
		
		let minDate = Date()
		datePicker.minimumDate = minDate

		if close != "Indefinite" {
			let maxDate = getDate(from: close)
			datePicker.maximumDate = maxDate
		}
		
		time.text = "Today to \(close)"
		
		reminderSelected.text = getStringDate(from: datePicker.date)
		
		if let result = ReminderManager.reminderDictionary[selectedExhibit.id] {
			guard let date = result.time else { return }
			ReminderManager.currentReminder = result
			
			let calendar = Calendar.current
			let components = DateComponents(year: Int(date.year), month: Int(date.month), day: Int(date.day), hour: Int(date.hour), minute: Int(date.minute))
			
			guard let dateToUse = calendar.date(from: components) else { return }
			
			// if loading an old reminder, set its past date as the minimum picker date
			if dateToUse < minDate {
				datePicker.minimumDate = dateToUse
			}
			
			reminderSelected.text = getStringDate(from: dateToUse)
			datePicker.date = dateToUse
			confirmButton.setTitle("Save Changes", for: .normal)
		} else {
			ReminderManager.currentReminder = nil
		}
	}
	
	
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
		var managedContext = CoreDataManager.shared.managedObjectContext
		
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
		
		// otherwise rewrite data to selected reminder
		if let time = currentReminder.time {
			// resave current time if it already exists
			getTimeForReminder(time: time)
			currentReminder.time = time
		} else {
			// time was not set before but one is being added
			var time: Time?
			time = Time(context: managedContext)
			getTimeForReminder(time: time)
			currentReminder.time = time
		}
		
		do {
			try managedContext.save()
			print("resave successful")
		} catch {
			// this should never be displayed but is here to cover the possibility
			showAlert(title: "Save failed", message: "Notice: Data has not successfully been saved.")
		}
		
		// notification will be overwritten if it already exists
		NotificationManager.addTimeBasedNotification(for: currentReminder)
	}
	
	func getExhibitData(reminder: Reminder) {
		guard let currentExhibit = exhibit, let open = openDate, let close = closeDate else { return }
		reminder.name = currentExhibit.exhibit
		reminder.museum = currentExhibit.museum
		reminder.id = Int64(currentExhibit.id)
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
		if datePicker.date <= currentDate {
			showAlert(title: "Cannot save reminder", message: "Please select a date that is in the future - the current date and time cannot be used.")
			return
		} else {
			saveEntry()
			
			guard let exhibitWithReminder = exhibit else { return }
			if ReminderManager.reminderDictionary[exhibitWithReminder.id] != nil {
				// reminder existed but was edited
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reminderEdited"), object: nil)
			} else {
				// reminder did not exist, add to array
				ReminderManager.exhibitsWithReminders.append(exhibitWithReminder)
			}
			
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateButton"), object: nil)
			dismiss(animated: true, completion: nil)
		}
	}
	
	@IBAction func cancelButtonTapped(_ sender: UIButton) {
		dismiss(animated: true, completion: nil)
	}
	
}
