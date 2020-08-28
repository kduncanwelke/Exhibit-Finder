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
    
    static let locationManager = CLLocationManager()
    
    static func getGeofenceCount() -> Int {
        return locationManager.monitoredRegions.count
    }
    
    static func showMuseum(museumLocation: MKPointAnnotation, mapView: MKMapView, region: MKCoordinateRegion) {
        mapView.addAnnotation(location)
        mapView.setRegion(region, animated: true)
        
        let circle = MKCircle(center: location.coordinate, radius: 125)
        mapView.addOverlay(circle)
    }
    
    static func addItemToMap(title: String, coordinate: CLLocationCoordinate2D, radius: Double, regionRadius: CLLocationDistance, mapView: MKMapView) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        mapView.addAnnotation(annotation)
        
        // recenter map on added annotation
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(region, animated: true)
        
        // add overlay for region
        let circle = MKCircle(center: coordinate, radius: radius)
        mapView.addOverlay(circle)
    }
    
    static func performSearch(museum: String, mapView: MKMapView) {
        // perform local search for museum by name, if it exists
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = museum
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        
        search.start { response, _ in
            guard let response = response else {
                return
            }
            
            guard let result = response.mapItems.first?.placemark else { return }
            // add to map
            self.addItemToMap(title: "\(museum) \n \(result.title ?? "")", coordinate: result.coordinate, radius: 125, regionRadius: 1000, mapView: mapView)
        }
    }
    
    static func updateLocation(location: MKPlacemark, mapView: MKMapView, radius: Double) {
        // wipe annotations if location was updated
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let locale = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        // parse address to assign it to title for pin
        geocoder.reverseGeocodeLocation(locale, completionHandler: { (placemarks, error) in
            if error == nil {
                guard let firstLocation = placemarks?[0] else { return }
                // add to map
                LocationManager.addItemToMap(title: "\(firstLocation.name ?? "") \n \(LocationManager.parseAddress(selectedItem: firstLocation))", coordinate: coordinate, radius: radius, regionRadius: 1000, mapView: mapView)
            }
            else {
                // an error occurred during geocoding
                print("not work")
            }
        })
    }
    
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
    
    // stop monitoring location based on reminder
    static func endLocationMonitoring(result: Reminder) {
        if let location = result.location, let name = result.name {
            LocationManager.stopMonitoringRegion(latitude: location.latitude, longitude: location.longitude, exhibitName: name, radius: location.radius)
            print("stopped monitoring")
        }
    }
    
    static func addGeofence(museumLocation: MKPointAnnotation?, exhibit: Exhibit?, map: MKMapView) {
        // create geofence and start monitoring
        if let pin = museumLocation, let title = exhibit?.exhibit, let circle = map.overlays.first as? MKCircle {
            
            let annotation = MKPointAnnotation()
            let coordinate = CLLocationCoordinate2D(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
            annotation.coordinate = coordinate
            
            let geofenceArea = LocationManager.getMonitoringRegion(for: annotation, exhibitName: title, radius: circle.radius)
            
            locationManager.startMonitoring(for: geofenceArea)
            print("\(annotation.coordinate.latitude), \(annotation.coordinate.longitude)")
            print("started monitoring")
        }
    }
	
	// add location based notification
	static func showLocationBasedNotification(for region: CLRegion) {
		print("location event handled")
		let identifier = region.identifier
		
		var managedContext = CoreDataManager.shared.managedObjectContext
		var fetchRequest = NSFetchRequest<Reminder>(entityName: "Reminder")
		fetchRequest.predicate = NSPredicate(format: "name == %@", identifier)
		
		// load particular reminder for triggered geofence using predicate
		var reminders: [Reminder] = []
		do {
			reminders = try managedContext.fetch(fetchRequest)
		} catch let error as NSError {
			print("could not fetch, \(error), \(error.userInfo)")
		}
	
		guard let retrievedReminder = reminders.first, let title = retrievedReminder.location?.name, let museum = retrievedReminder.location?.museum, let minHour = retrievedReminder.location?.minTime, let maxHour = retrievedReminder.location?.maxTime else { return }
		
		let notificationCenter = UNUserNotificationCenter.current()
		let notificationContent = UNMutableNotificationContent()
		
		// set up notification
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
		
		// show only if current time is in notification timeframe
		guard let hour = components.hour, let startDate = retrievedReminder.startDate else { return }
		
		// check if invalid date exists - if not exhibit is permanent
		if let invalidDate = retrievedReminder.invalidDate {
			if (hour >= min && hour <= max) && (date >= startDate && date <= invalidDate) {
				notificationCenter.add(request) { (error) in
					if error != nil {
						print("Error adding notification with identifier: \(identifier)")
					}
				}
				
				print("notification added")
			}
		} else {
			if (hour >= min && hour <= max) && date >= startDate {
				notificationCenter.add(request) { (error) in
					if error != nil {
						print("Error adding notification with identifier: \(identifier)")
					}
				}
				
				print("notification added")
			}
		}
		
	}
	
	static func parseAddress(selectedItem: CLPlacemark) -> String {
		// put a space between "4" and "Melrose Place"
		let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
		// put a comma between street and city/state
		let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
		// put a space between "Washington" and "DC"
		let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
		let addressLine = String(
			format:"%@%@%@%@%@%@%@",
			// street number
			selectedItem.subThoroughfare ?? "",
			firstSpace,
			// street name
			selectedItem.thoroughfare ?? "",
			comma,
			// city
			selectedItem.locality ?? "",
			secondSpace,
			// state
			selectedItem.administrativeArea ?? ""
		)
	
		return addressLine
	}
}
