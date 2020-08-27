//
//  ReminderViewModel.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 8/21/20.
//  Copyright © 2020 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import CoreData

public class ReminderViewModel {
    
    weak var alertDelegate: AlertDisplayDelegate?
    
    public func reminderCount() -> Int {
        return ReminderManager.reminders.count
    }
    
    func getReminder(id: Int64) {
        ReminderManager.currentReminder = ReminderManager.reminderDictionary[id]
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
    
    // MARK: Saves
    
    func resave(result: Reminder, removing: Removing) {
        var managedContext = CoreDataManager.shared.managedObjectContext
        
        switch removing {
        case .time:
            result.time = nil
            NotificationManager.clearNotification(result: result)
        case .location:
            LocationManager.endLocationMonitoring(result: result)
            result.location = nil
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
    
    public func fullDelete(result: Reminder) {
        var managedContext = CoreDataManager.shared.managedObjectContext
        
        let new = ReminderManager.exhibitsWithReminders.filter({ $0.id != result.id })
        ReminderManager.exhibitsWithReminders = new
        
        NotificationManager.clearNotification(result: result)
        LocationManager.endLocationMonitoring(result: result)
        
        managedContext.delete(result)
        
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
