//
//  ReminderViewModel.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 8/21/20.
//  Copyright © 2020 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import CoreData
import MapKit
import CoreLocation

public class ReminderViewModel {
    
    weak var alertDelegate: AlertDisplayDelegate?
    let defaultMinTime = 8.0
    let defaultMaxTime = 17.0
    let defaultRadius = 125.0
    
    public func reminderCount() -> Int {
        return ReminderManager.reminders.count
    }
    
    func getReminder(id: Int64) {
        ReminderManager.currentReminder = ReminderManager.reminderDictionary[id]
    }
    
    func getExhibitForReminder(index: IndexPath) -> Exhibit? {
        return ExhibitManager.exhibitsList[index.row]
    }
    
    public func getAddress() -> String? {
        return ReminderManager.currentReminder?.location?.address
    }
    
    public func getRowCount(section: Int) -> Int {
        let exhibitsViewModel = ExhibitsViewModel()
        var data = exhibitsViewModel.retrieveSource()
        
        let result = ReminderManager.reminderDictionary[data[section].id]
        
        if result?.time != nil && result?.location != nil {
            return 2
        } else {
            return 1
        }
    }
    
    func hasLocation() -> Bool {
        if let reminder = ReminderManager.currentReminder, let location = reminder.location {
            return true
        } else {
            return false
        }
    }
    
    func getDate() -> Date? {
        guard let date = ReminderManager.currentReminder?.time else { return nil }
       
        let calendar = Calendar.current
        let components = DateComponents(year: Int(date.year), month: Int(date.month), day: Int(date.day), hour: Int(date.hour), minute: Int(date.minute))
        
        guard let dateToUse = calendar.date(from: components) else { return nil }
        return dateToUse
    }
    
    func getMinTime() -> Double {
        if let reminder = ReminderManager.currentReminder, let min = reminder.location?.minTime {
            print("min time")
            print(min)
            return min
        } else {
            return defaultMinTime
        }
    }
    
    func getMaxTime() -> Double {
        if let reminder = ReminderManager.currentReminder, let max = reminder.location?.maxTime {
            return max
        } else {
            return defaultMaxTime
        }
    }
    
    func getRadius() -> Double {
        if let reminder = ReminderManager.currentReminder, let radius = reminder.location?.radius {
            return radius
        } else {
            return defaultRadius
        }
    }
    
    func getLat() -> Double {
        if let reminder = ReminderManager.currentReminder, let lat = reminder.location?.latitude {
            return lat
        } else {
            return LocationManager.defaultLat
        }
    }
    
    func getLong() -> Double {
        if let reminder = ReminderManager.currentReminder, let long = reminder.location?.longitude {
            return long
        } else {
            return LocationManager.defaultLong
        }
    }
    
    func getReminderType() -> WithReminder? {
        guard let reminder = ReminderManager.currentReminder else { return nil }
        
        if let time = reminder.time, let location = reminder.location {
            return .both
        } else if let time = reminder.time {
            return .time
        } else {
            return .location
        }
    }
    
    public func exhibitsWithRemindersCount() -> Int {
        return ReminderManager.exhibitsWithReminders.count
    }
    
    // MARK: Loads
    
    // load reminders from core data
    public func loadReminders() {
        var managedContext = CoreDataManager.shared.managedObjectContext
        var fetchRequest = NSFetchRequest<Reminder>(entityName: "Reminder")
        
        do {
            ReminderManager.reminders = try managedContext.fetch(fetchRequest)
            print("reminders loaded")
            
            // remove all from dictionary to prevent empty keys
            if ReminderManager.reminderDictionary.isEmpty != true {
                ReminderManager.reminderDictionary.removeAll()
            }
            
            for reminder in ReminderManager.reminders {
                ReminderManager.reminderDictionary[reminder.id] = reminder
                print(reminder)
            }
            
        } catch let error as NSError {
            alertDelegate?.displayAlert(with: "Could not retrieve data", message: "\(error.userInfo)")
        }
        
        // Why is this here loading doesn't delete anything
        // if section 1 (where deletion occurs) is selected, don't reload table view as it breaks fade animation
        /*if segmentedController.selectedSegmentIndex != 1 {
            tableView.reloadData()
        }*/
    }
    
    private func getTimeForReminder(time: Time?, date: Date) -> Time? {
        // set date components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        guard let year = components.year, let month = components.month, let day = components.day, let hour = components.hour, let minute = components.minute else { return nil }
        
        // assign to time for reminder
        time?.year = Int32(year)
        time?.month = Int32(month)
        time?.day = Int32(day)
        time?.hour = Int32(hour)
        time?.minute = Int32(minute)
        
        return time
    }
    
    private func getLocationForReminder(location: Location?, museumLocation: MKPointAnnotation?, min: Double, max: Double, circle: MKCircle?, index: IndexPath) -> Location? {
        guard let pin = museumLocation, let address = pin.title, let exhibit = self.getExhibitForReminder(index: index) else {
            print("guard falling through")
            return nil }
        
        location?.address = address
        location?.museum = exhibit.museum
        location?.latitude = pin.coordinate.latitude
        location?.longitude = pin.coordinate.longitude
        location?.name = exhibit.exhibit
        location?.minTime = min
        location?.maxTime = max
       
        guard let overlay = circle else { return nil }
        location?.radius = overlay.radius
        
        return location
    }
    
    private func getExhibitData(reminder: Reminder, index: IndexPath) -> Reminder? {
        guard let exhibit = self.getExhibitForReminder(index: index), let open = exhibit.openingDate else { return nil }
        
        reminder.name = exhibit.exhibit
        reminder.museum = exhibit.museum
        reminder.id = Int64(exhibit.id)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        reminder.startDate = dateFormatter.date(from: open)
        if let close = exhibit.closingDate {
            reminder.invalidDate = dateFormatter.date(from: close)
        } else {
            reminder.invalidDate = nil
        }
        
        return reminder
    }
    
    // MARK: Saves
    
    func saveTime(date: Date, index: IndexPath) {
        var managedContext = CoreDataManager.shared.managedObjectContext
        
        // save new entry if no reminder is being edited
        guard let currentReminder = ReminderManager.currentReminder else {
            let newReminder = Reminder(context: managedContext)
            
            guard let exhibitData = getExhibitData(reminder: newReminder, index: index) else { return }
            newReminder.id = exhibitData.id
            newReminder.invalidDate = exhibitData.invalidDate
            newReminder.museum = exhibitData.museum
            newReminder.name = exhibitData.name
            newReminder.startDate = exhibitData.startDate
            
            var time: Time?
            time = Time(context: managedContext)
            
            guard let timeData = getTimeForReminder(time: time, date: date) else { return }
            time?.day = timeData.day
            time?.hour = timeData.hour
            time?.minute = timeData.minute
            time?.month = timeData.month
            time?.year = timeData.year
            
            newReminder.time = time
            
            do {
                try managedContext.save()
                print("saved")
            } catch {
                // this should never be displayed but is here to cover the possibility
                alertDelegate?.displayAlert(with: "Save failed", message: "Notice: Data has not successfully been saved.")
            }
            
            // reminder did not exist, add to array
            if let exhibit = getExhibitForReminder(index: index) {
                ReminderManager.exhibitsWithReminders.append(exhibit)
            }
            // add notification
            NotificationManager.addTimeBasedNotification(for: newReminder)
    
            return
        }
        
        // otherwise rewrite data to selected reminder
        if let time = currentReminder.time {
            // resave current time if it already exists
            guard let timeData = getTimeForReminder(time: time, date: date) else { return }
            time.day = timeData.day
            time.hour = timeData.hour
            time.minute = timeData.minute
            time.month = timeData.month
            time.year = timeData.year
            
            currentReminder.time = time
        } else {
            // time was not set before but one is being added
            var time: Time?
            time = Time(context: managedContext)
            
            guard let timeData = getTimeForReminder(time: time, date: date) else { return }
            time?.day = timeData.day
            time?.hour = timeData.hour
            time?.minute = timeData.minute
            time?.month = timeData.month
            time?.year = timeData.year
            
            currentReminder.time = time
        }
        
        do {
            try managedContext.save()
            print("resave successful")
        } catch {
            // this should never be displayed but is here to cover the possibility
            alertDelegate?.displayAlert(with: "Save failed", message: "Notice: Data has not successfully been saved.")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reminderEdited"), object: nil)
        // notification will be overwritten if it already exists
        NotificationManager.addTimeBasedNotification(for: currentReminder)
    }
    
    func saveLocation(museumLocation: MKPointAnnotation?, min: Double, max: Double, circle: MKCircle?, index: IndexPath) {
        var managedContext = CoreDataManager.shared.managedObjectContext
        
        // save new entry if no reminder is being edited
        guard let currentReminder = ReminderManager.currentReminder else {
            // if there's no reminder selected, create a new one
            let newReminder = Reminder(context: managedContext)
            
            var location: Location?
            location = Location(context: managedContext)
            
            guard let locationData = getLocationForReminder(location: location, museumLocation: museumLocation, min: min, max: max, circle: circle, index: index) else { return }
            location?.name = locationData.name
            location?.museum = locationData.museum
            location?.address = locationData.address
            location?.latitude = locationData.latitude
            location?.longitude = locationData.longitude
            location?.maxTime = locationData.maxTime
            location?.minTime = locationData.minTime
            newReminder.location = location
            
            guard let exhibitData = getExhibitData(reminder: newReminder, index: index) else { return }
            newReminder.id = exhibitData.id
            newReminder.invalidDate = exhibitData.invalidDate
            newReminder.museum = exhibitData.museum
            newReminder.name = exhibitData.name
            newReminder.startDate = exhibitData.startDate
            
            do {
                try managedContext.save()
                print("saved")
            } catch {
                // this should never be displayed but is here to cover the possibility
                alertDelegate?.displayAlert(with: "Save failed", message: "Notice: Data has not successfully been saved.")
            }
            
            // reminder did not exist, add to array
            if let exhibit = getExhibitForReminder(index: index) {
                ReminderManager.exhibitsWithReminders.append(exhibit)
            }
            
            return
        }
        
        // otherwise rewrite data to selected reminder
        if let location = currentReminder.location {
            // resave current location if it already exists
            guard let locationData = getLocationForReminder(location: location, museumLocation: museumLocation, min: min, max: max, circle: circle, index: index) else { return }
            
            location.name = locationData.name
            location.museum = locationData.museum
            location.address = locationData.address
            location.latitude = locationData.latitude
            location.longitude = locationData.longitude
            location.maxTime = locationData.maxTime
            location.minTime = locationData.minTime
            
            currentReminder.location = location
        } else {
            // location was not set before but one is being added
            var location: Location?
            location = Location(context: managedContext)
            guard let locationData = getLocationForReminder(location: location, museumLocation: museumLocation, min: min, max: max, circle: circle, index: index) else { return }
            
            location?.name = locationData.name
            location?.museum = locationData.museum
            location?.address = locationData.address
            location?.latitude = locationData.latitude
            location?.longitude = locationData.longitude
            location?.maxTime = locationData.maxTime
            location?.minTime = locationData.minTime
           
            currentReminder.location = location
        }
        
        do {
            try managedContext.save()
            print("resave successful")
        } catch {
            // this should never be displayed but is here to cover the possibility
            alertDelegate?.displayAlert(with: "Save failed", message: "Notice: Data has not successfully been saved.")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reminderEdited"), object: nil)
    }
    
    func resave(removing: Removing) {
        guard let reminder = ReminderManager.currentReminder else { return }
        var managedContext = CoreDataManager.shared.managedObjectContext
        
        switch removing {
        case .time:
            reminder.time = nil
            NotificationManager.clearNotification(result: reminder)
        case .location:
            LocationManager.endLocationMonitoring(result: reminder)
            reminder.location = nil
        }
        
        do {
            try managedContext.save()
            print("resave successful")
        } catch {
            // this should never be displayed but is here to cover the possibility
            alertDelegate?.displayAlert(with: "Save failed", message: "Notice: Data has not successfully been saved.")
        }
    }
    
    // MARK: Deletions
    
    public func fullDelete() {
        guard let reminder = ReminderManager.currentReminder else { return }
        var managedContext = CoreDataManager.shared.managedObjectContext
        
        let new = ReminderManager.exhibitsWithReminders.filter({ $0.id != reminder.id })
        ReminderManager.exhibitsWithReminders = new
        
        NotificationManager.clearNotification(result: reminder)
        LocationManager.endLocationMonitoring(result: reminder)
        
        managedContext.delete(reminder)
        
        do {
            try managedContext.save()
            print("delete successful")
        } catch {
            print("Failed to save")
        }
                
        ReminderManager.currentReminder = nil
    }
    
    public func deleteExpiredReminders() {
        var managedContext = CoreDataManager.shared.managedObjectContext
        var fetchRequest = NSFetchRequest<Reminder>(entityName: "Reminder")
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
                NotificationManager.clearNotification(result: reminder)
                LocationManager.endLocationMonitoring(result: reminder)
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
}
