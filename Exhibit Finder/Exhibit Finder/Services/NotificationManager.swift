//
//  NotificationManager.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/18/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import UserNotifications

struct NotificationManager {
	
	static func addTimeBasedNotification(for reminder: Reminder) {
		let identifier = "\(reminder.id)"
		
		let notificationCenter = UNUserNotificationCenter.current()
		let notificationContent = UNMutableNotificationContent()
		
		guard let title = reminder.name, let time = reminder.time, let museum = reminder.museum else { return }
		notificationContent.title = "\(title)"
		notificationContent.body = "This exhibit is currently on display at the \(museum)."
		notificationContent.sound = UNNotificationSound.default
		
		// convert to calendar date
		var components = DateComponents()
		components.year = Int(time.year)
		components.month = Int(time.month)
		components.day = Int(time.day)
		components.hour = Int(time.hour)
		components.minute = Int(time.minute)
		
		let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
		let request = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: trigger)
		
		notificationCenter.add(request) { (error) in
			if error != nil {
				print("Error adding notification with identifier: \(identifier)")
			}
		}
		
		print("notification added")
	}
    
    static func clearNotification(result: Reminder) {
        // remove existing time-based notification
        let notificationCenter = UNUserNotificationCenter.current()
        let identifier = "\(result.id)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
