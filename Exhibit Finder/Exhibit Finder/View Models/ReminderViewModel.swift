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
    
    public func reminderCount() -> Int {
        return ReminderManager.reminders.count
    }
    
    func getReminder(id: Int64) {
        ReminderManager.currentReminder = ReminderManager.reminderDictionary[id]
    }
    
    func getExhibitForReminder(index: IndexPath) -> Exhibit? {
        return ReminderManager.exhibitDictionary[Int64(index.row)].id
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
            return min
        } else {
            return 8.0
        }
    }
    
    func getMaxTime() -> Double {
        if let reminder = ReminderManager.currentReminder, let max = reminder.location?.maxTime {
            return max
        } else {
            return 17.0
        }
    }
    
    func getRadius() -> Double {
        if let reminder = ReminderManager.currentReminder, let radius = reminder.location?.radius {
            return radius
        } else {
            return 125.0
        }
    }
    
    func getLat() -> Double {
        if let reminder = ReminderManager.currentReminder, let lat = reminder.location?.latitude {
            return lat
        }
    }
    
    func getLong() -> Double {
        if let reminder = ReminderManager.currentReminder, let long = reminder.location?.longitude {
            return long
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
                print(reminder.id)
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
    
    private func getTimeForReminder(time: Time?, date: Date) {
        // set date components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        guard let year = components.year, let month = components.month, let day = components.day, let hour = components.hour, let minute = components.minute else { return }
        
        // assign to time for reminder
        time?.year = Int32(year)
        time?.month = Int32(month)
        time?.day = Int32(day)
        time?.hour = Int32(hour)
        time?.minute = Int32(minute)
    }
    
    private func getLocationForReminder(location: Location?, museumLocation: MKPointAnnotation?, min: Double, max: Double, circle: MKCircle?, index: IndexPath) {
        guard let pin = museumLocation, let address = pin.title, let exhibit = self.getExhibitForReminder(index: index) else { return }
        
        location?.address = address
        location?.museum = exhibit.museum
        location?.latitude = pin.coordinate.latitude
        location?.longitude = pin.coordinate.longitude
        location?.name = exhibit.exhibit
        location?.minTime = min
        location?.maxTime = max
       
        guard let overlay = circle else { return }
        location?.radius = overlay.radius
    }
    
    private func getExhibitData(reminder: Reminder, index: IndexPath) {
        guard let exhibit = self.getExhibitForReminder(index: index), let open = exhibit.openingDate, let close = exhibit.closingDate else { return }
        
        reminder.name = exhibit.exhibit
        reminder.museum = exhibit.museum
        reminder.id = Int64(exhibit.id)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        reminder.startDate = dateFormatter.date(from: open)
        reminder.invalidDate = dateFormatter.date(from: close)
    }
    
    // MARK: Saves
    
    func saveTime(date: Date, index: IndexPath) {
        var managedContext = CoreDataManager.shared.managedObjectContext
        
        // save new entry if no reminder is being edited
        guard let currentReminder = ReminderManager.currentReminder else {
            let newReminder = Reminder(context: managedContext)
            
            var time: Time?
            time = Time(context: managedContext)
            
            getTimeForReminder(time: time, date: date)
            newReminder.time = time
            
            getExhibitData(reminder: newReminder, index: index)
            
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
            getTimeForReminder(time: time, date: date)
            currentReminder.time = time
        } else {
            // time was not set before but one is being added
            var time: Time?
            time = Time(context: managedContext)
            getTimeForReminder(time: time, date: date)
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
            
            getLocationForReminder(location: location, museumLocation: museumLocation, min: min, max: max, circle: circle, index: index)
            newReminder.location = location
            getExhibitData(reminder: newReminder, index: index)
            
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
            getLocationForReminder(location: location, museumLocation: museumLocation, min: min, max: max, circle: circle, index: index)
            currentReminder.location = location
        } else {
            // location was not set before but one is being added
            var location: Location?
            location = Location(context: managedContext)
            getLocationForReminder(location: location, museumLocation: museumLocation, min: min, max: max, circle: circle, index: index)
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
