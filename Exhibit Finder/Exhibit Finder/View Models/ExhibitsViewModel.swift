//
//  ExhibitsViewModel.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 8/21/20.
//  Copyright © 2020 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import UIKit

public class ExhibitsViewModel {
  
    weak var alertDelegate: AlertDisplayDelegate?
    weak var exhibitDelegate: ExhibitLoadDelegate?

    var dateFormatter = DateFormatter()
    var currentType: DataType = .exhibitsOnly
    var currentSource: [Exhibit] = ExhibitManager.exhibitsList
    var isSearching = false
    
    // get string from date
    func getStringDate(from date: Date) -> String {
        var timeDateFormatter = DateFormatter()
        timeDateFormatter.dateFormat = "yyyy-MM-dd 'at' hh:mm a"
        
        let createdDate = timeDateFormatter.string(from: date)
        return createdDate
    }
    
    // turn date into string to pass into search
    func getDate(from stringDate: String?) -> Date {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var currentDate = Date()
        
        guard let shortenedDate = stringDate?.dropLast(11), let createdDate = dateFormatter.date(from: String(shortenedDate)) else {
            return currentDate
        }
        return createdDate
    }
    
    public func loadExhibitions() {
        DataManager<Exhibits>.fetch() { [unowned self] result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    guard let response = response.first?.exhibits else {
                        self.alertDelegate?.displayAlert(with: "Connection failed", message: "Data response failed, please try again later.")
                        return
                    }
                   
                    for exhibit in response {
                        let closeDate = self.getDate(from: exhibit.closingDate)
                        // disclude museums outside of Washington DC
                        if exhibit.museum != "Cooper Hewitt, Smithsonian Design Museum" && exhibit.museum != "Air and Space Museum Udvar-Hazy Center" && exhibit.museum != "American Indian Museum Heye Center" {
                            
                            // only add exhibit if closedate is in the future
                            if closeDate >= Date() || exhibit.closingDate == nil {
                                ExhibitManager.exhibitsList.append(exhibit)
                                
                                // add exhibit to exhibit dictionary
                                ReminderManager.exhibitDictionary[exhibit.id] = exhibit
                                
                                // if exhibit is in reminder dictionary, add to list of exhibits that have reminders
                                if ReminderManager.reminderDictionary[exhibit.id] != nil {
                                    
                                    // add to array of exhibits that have reminder
                                    ReminderManager.exhibitsWithReminders.append(exhibit)
                                } else {
                                    // nothing
                                }
                            }
                        }
                    }
                    
                    for exhibit in ExhibitManager.exhibitsList {
                        if let urlString = exhibit.imgUrl, let url = URL(string: urlString) {
                            ReminderManager.urls[exhibit.id] = url
                        }
                    }
                   
                    self.exhibitDelegate?.loadExhibits(success: true)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    switch error {
                    case Errors.networkError:
                        self.alertDelegate?.displayAlert(with: "Networking failed", message: "\(Errors.networkError.localizedDescription)")
                    default:
                        self.alertDelegate?.displayAlert(with: "Networking failed", message: "\(Errors.otherError.localizedDescription)")
                    }
                    
                    self.exhibitDelegate?.loadExhibits(success: false)
                }
            }
        }
    }
    
    func setData(type: DataType, searchText: String?) {
        print(type)
        currentType = type
        if searchText != "" {
            if let search = searchText {
                print("search")
                isSearching = true
               
                switch type {
                case .exhibitsOnly:
                    currentSource = ExhibitManager.exhibitsList
                case .exhibitsWithReminders:
                    currentSource = ReminderManager.exhibitsWithReminders
                }
                
                ExhibitManager.searchResults = currentSource.filter({(exhibit: Exhibit) -> Bool in
                    return (exhibit.exhibit?.lowercased().contains(search.lowercased()))! || (exhibit.info?.lowercased().contains(search.lowercased()))! || (exhibit.closingDate?.contains(search.lowercased()) ?? false)
                })
            }
            
            currentSource = ExhibitManager.searchResults
        } else {
            isSearching = false
            print("not search")
            
            switch type {
            case .exhibitsOnly:
                currentSource = ExhibitManager.exhibitsList
            case .exhibitsWithReminders:
                currentSource = ReminderManager.exhibitsWithReminders
            }
        }
    }
    
    func retrieveSource() -> [Exhibit] {
        if isSearching {
            return ExhibitManager.searchResults
        } else {
            switch currentType {
            case .exhibitsOnly:
                return ExhibitManager.exhibitsList
            case .exhibitsWithReminders:
                return ReminderManager.exhibitsWithReminders
            }
        }
    }
    
    public func setCurrentIndex(index: IndexPath) {
        ExhibitManager.currentIndex = index
    }
    
    public func getCurrentIndex() -> IndexPath? {
        return ExhibitManager.currentIndex
    }
    
    public func isListEmpty() -> Bool {
        return ExhibitManager.exhibitsList.isEmpty
    }
    
    public func isSearchEmpty() -> Bool {
        return ExhibitManager.searchResults.isEmpty
    }
    
    public func searchCount() -> Int {
        return ExhibitManager.exhibitsList.count 
    }
    
    public func getReminderForExhibit(index: IndexPath) -> Reminder? {
        ReminderManager.currentReminder = ReminderManager.reminderDictionary[currentSource[index.row].id]
        return ReminderManager.currentReminder
    }
    
    public func hasTitle(section: Int) -> String? {
        switch currentType {
        case .exhibitsOnly:
            return nil
        case .exhibitsWithReminders:
            if !currentSource.isEmpty {
                return currentSource[section].exhibit
            } else {
                return nil
            }
        }
    }
    
    public func getImageUrl(index: IndexPath) -> URL? {
        var selection: Int
        switch currentType {
        case .exhibitsOnly:
            selection = index.row
        case .exhibitsWithReminders:
            selection = index.section
        }
        
        if let url = ReminderManager.urls[currentSource[selection].id] {
            return url
        } else {
            return nil
        }
    }
    
    public func getTitle(index: IndexPath) -> String {
        switch currentType {
        case .exhibitsOnly:
            if let title = currentSource[index.row].exhibit {
                let decoded = title.decodingHTMLEntities()
                return String.removeHTMLWithoutSpacing(from: decoded)
            } else {
                return "No title"
            }
        case .exhibitsWithReminders:
            guard let result = ReminderManager.reminderDictionary[currentSource[index.section].id] else { return "" }
            var currentDate = Date()
            
            if (result.time != nil && result.location != nil && index.row == 0) || (result.time != nil && result.location == nil) {
                guard let date = result.time else { return "" }
                    let calendar = Calendar.current
                    let components = DateComponents(year: Int(date.year), month: Int(date.month), day: Int(date.day), hour: Int(date.hour), minute: Int(date.minute))
                    
                guard let dateToUse = calendar.date(from: components) else { return "" }
                    if let invalid = result.invalidDate {
                        if dateToUse < currentDate || invalid < currentDate {
                            return "This reminder has expired"
                        } else {
                            let stringDate = getStringDate(from: dateToUse)
                            return "For \(stringDate)"
                        }
                    } else {
                        if dateToUse < currentDate {
                            return "This reminder has expired"
                        } else {
                            let stringDate = getStringDate(from: dateToUse)
                            return "For \(stringDate)"
                        }
                    }
                } else {
                    if let radius = result.location?.radius {
                        return "Within \(Int(radius)) foot radius of museum"
                    } else {
                        return ""
                    }
                }
            }
    }
    
    public func getMuseum(index: IndexPath) -> String {
        var selection: Int
        switch currentType {
        case .exhibitsOnly:
            selection = index.row
        case .exhibitsWithReminders:
            selection = index.section
        }
        
        if let museum = currentSource[selection].museum {
            return museum
        } else {
            return "No museum listed"
        }
    }
    
    public func getInfo(index: IndexPath) -> String {
        var selection: Int
        switch currentType {
        case .exhibitsOnly:
            selection = index.row
        case .exhibitsWithReminders:
            selection = index.section
        }
        
        if let data = currentSource[selection].infoBrief {
            let decoded = data.decodingHTMLEntities()
            return String.removeHTMLWithoutSpacing(from: decoded)
        } else {
            return "No description available"
        }
    }
    
    public func getVerboseInfo(index: IndexPath) -> String {
        var selection: Int
        switch currentType {
        case .exhibitsOnly:
            selection = index.row
        case .exhibitsWithReminders:
            selection = index.section
        }
        
        if let data = currentSource[selection].info {
            let decoded = data.decodingHTMLEntities()
            return String.removeHTML(from: decoded)
        } else {
            return "No description available"
        }
    }
    
    public func getOpenDate(index: IndexPath) -> String {
        var selection: Int
        switch currentType {
        case .exhibitsOnly:
            selection = index.row
        case .exhibitsWithReminders:
            selection = index.section
        }
        
        if let open = currentSource[selection].openingDate?.dropLast(11) {
            return "\(open)"
        } else {
            return "No info"
        }
    }
    
    public func getCloseDate(index: IndexPath) -> String {
        var selection: Int
        switch currentType {
        case .exhibitsOnly:
            selection = index.row
        case .exhibitsWithReminders:
            selection = index.section
        }
        
        if let close = currentSource[selection].closingDate?.dropLast(11) {
            return "\(close)"
        } else if (currentSource[selection].closeText?.contains("Indefinitely")) != nil {
            return "Indefinite"
        } else {
            return "No info"
        }
    }
    
    public func getLocation(index: IndexPath) -> String {
        var selection: Int
        switch currentType {
        case .exhibitsOnly:
            selection = index.row
        case .exhibitsWithReminders:
            selection = index.section
        }
        
        if let location = currentSource[selection].location {
            return "Location: \(location)"
        } else {
            return "No specific location"
        }
    }
    
    public func hasReminder(index: IndexPath) -> String {
        var selection: Int
        switch currentType {
        case .exhibitsOnly:
            selection = index.row
        case .exhibitsWithReminders:
            selection = index.section
        }
        
        // there is a reminder
        if let result = ReminderManager.reminderDictionary[currentSource[selection].id] {
            switch currentType {
            case .exhibitsOnly:
                return "Reminder"
            case .exhibitsWithReminders:
                if (result.time != nil && result.location != nil && index.row == 0) || (result.time != nil && result.location == nil) {
                    return "Time"
                } else if (result.time != nil && result.location != nil && index.row == 1) || (result.time == nil && result.location != nil) {
                    return "Location"
                } else {
                    return ""
                }
            }
        } else { // there is no reminder
            switch currentType {
            case .exhibitsOnly:
                return "No reminder"
            case .exhibitsWithReminders:
                return ""
            }
        }
    }
    
    public func reminderImage(index: IndexPath) -> UIImage? {
        var selection: Int
        switch currentType {
        case .exhibitsOnly:
            selection = index.row
        case .exhibitsWithReminders:
            selection = index.section
        }
        
        // there is a reminder
        if let result = ReminderManager.reminderDictionary[currentSource[selection].id] {
            switch currentType {
            case .exhibitsOnly:
                if result.time != nil && result.location != nil {
                    return UIImage(named: "both25")
                } else if result.time != nil && result.location == nil {
                    return UIImage(named: "clockicon25")
                } else if result.time == nil && result.location != nil {
                    return UIImage(named: "locationicon25")
                } else {
                    return nil
                }
            case .exhibitsWithReminders:
                if (result.time != nil && result.location != nil && index.row == 0) || (result.time != nil && result.location == nil) {
                    return UIImage(named: "clockicon25")
                } else if (result.time != nil && result.location != nil && index.row == 1) || (result.time == nil && result.location != nil) {
                    return UIImage(named: "locationicon25")
                } else {
                    return nil
                }
            }
        } else { // there's no reminder and therefore no image
            return nil
        }
    }
    
    public func getURL(index: IndexPath) -> URL? {
        var selection: Int
        switch currentType {
        case .exhibitsOnly:
            selection = index.row
        case .exhibitsWithReminders:
            selection = index.section
        }
        
        if let stringUrl = currentSource[selection].exhibitURL, let generatedUrl = URL(string: stringUrl) {
            return generatedUrl
        } else {
            return nil
        }
    }
    
}
