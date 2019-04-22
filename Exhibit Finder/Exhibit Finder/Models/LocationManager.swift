//
//  LocationManager.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/19/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation
import UserNotifications
import CoreData

struct LocationManager {
	// get region to monitor geofence for
	static func getMonitoringRegion(for location: MKPointAnnotation, exhibitName: String, radius: Double) -> CLCircularRegion {
		let coordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
		let region = CLCircularRegion(center: coordinate, radius: radius, identifier: exhibitName)
		return region
	}
	
	// stop monitoring given geofence
	static func stopMonitoringRegion(latitude: Double, longitude: Double, exhibitName: String, radius: Double) {
		let locationManager = CLLocationManager()
		let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
		let selectedRegion = CLCircularRegion(center: coordinate, radius: radius, identifier: exhibitName)

		locationManager.stopMonitoring(for: selectedRegion)
	}
	
	// add location based notification
	static func showLocationBasedNotification(for region: CLRegion) {
		print("location event handled")
		let identifier = region.identifier
		
		let managedContext = CoreDataManager.shared.managedObjectContext
		let fetchRequest = NSFetchRequest<Reminder>(entityName: "Reminder")
		fetchRequest.predicate = NSPredicate(format: "location.name == %@", identifier)
		
		// load particular reminder for triggered geofence using predicate
		var reminders: [Reminder] = []
		do {
			reminders = try managedContext.fetch(fetchRequest)
		} catch let error as NSError {
			print("could not fetch, \(error), \(error.userInfo)")
		}
		
		guard let retrievedReminder = reminders.first, let museum = retrievedReminder.location?.museum, let title = retrievedReminder.location?.name, let minHour = retrievedReminder.location?.minTime, let maxHour = retrievedReminder.location?.maxTime else { return }
		
		let notificationCenter = UNUserNotificationCenter.current()
		let notificationContent = UNMutableNotificationContent()
		
		notificationContent.title = "\(title)"
		notificationContent.body = "You are near the \(museum) where this exhibit is currently on display."
		notificationContent.sound = UNNotificationSound.default
		
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
		let request = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: trigger)
		
		let date = Date()
		let calendar = Calendar.current
		let components = calendar.dateComponents([.hour], from: date)
		
		let min = Int(minHour)
		let max = Int(maxHour)
		guard let hour = components.hour, let startDate = retrievedReminder.startDate, let invalidDate = retrievedReminder.invalidDate else { return }
		
		if (hour >= min && hour <= max) && (date >= startDate && date <= invalidDate) {
			notificationCenter.add(request) { (error) in
				if error != nil {
					print("Error adding notification with identifier: \(identifier)")
				}
			}
			
			print("notification added")
		}
		
	}
}
