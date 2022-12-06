//
//  TimeReminderViewController.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/10/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import UserNotifications

class TimeReminderViewController: UIViewController, AlertDisplayDelegate {

	// MARK: IBOutlets
	
	@IBOutlet weak var datePicker: UIDatePicker!
	@IBOutlet weak var exhibitName: UILabel!
	@IBOutlet weak var museumName: UILabel!
	@IBOutlet weak var time: UILabel!
	@IBOutlet weak var reminderSelected: UILabel!
	@IBOutlet weak var confirmButton: UIButton!
	
	// MARK: Variables
	
	let dateFormatter = DateFormatter()
	let timeDateFormatter = DateFormatter()
    
    private let reminderViewModel = ReminderViewModel()
    private let exhibitsViewModel = ExhibitsViewModel()
    private let timeReminderViewModel = TimeReminderViewModel()
	
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
		UNUserNotificationCenter.current().getNotificationSettings() { [unowned self] (settings) in
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
        guard let index = exhibitsViewModel.getCurrentIndex() else { return }
		exhibitName.text = exhibitsViewModel.getTitleForTimeReminder(index: index)
		museumName.text = exhibitsViewModel.getMuseum(index: index)
		
		let minDate = Date()
		datePicker.minimumDate = minDate

		let close = exhibitsViewModel.getCloseDate(index: index)
        if close != "Indefinite" {
            let maxDate = timeReminderViewModel.getDate(from: close)
			datePicker.maximumDate = maxDate
		}
		
		time.text = "Today to \(close)"
        reminderSelected.text = timeReminderViewModel.getStringDate(from: datePicker.date)
		
        if exhibitsViewModel.getReminderForExhibit(indexPath: index) != nil {
            guard let dateToUse = reminderViewModel.getDate() else { return }
            
            // if loading an old reminder, set its past date as the minimum picker date
            if dateToUse < minDate {
                datePicker.minimumDate = dateToUse
            }
            
            reminderSelected.text = timeReminderViewModel.getStringDate(from: dateToUse)
            datePicker.date = dateToUse
            confirmButton.setTitle("Save Changes", for: .normal)
        }
	}
	
	@objc func datePickerChanged(picker: UIDatePicker) {
        reminderSelected.text = timeReminderViewModel.getStringDate(from: datePicker.date)
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
            guard let index = exhibitsViewModel.getCurrentIndex() else { return }
            
            reminderViewModel.saveTime(date: datePicker.date, index: index)
			
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateButton"), object: nil)
			dismiss(animated: true, completion: nil)
		}
	}
	
	@IBAction func cancelButtonTapped(_ sender: UIButton) {
		dismiss(animated: true, completion: nil)
	}
	
}

extension TimeReminderViewController {
    // delegate methods
    
    func displayAlert(with title: String, message: String) {
        showAlert(title: title, message: message)
    }
}
