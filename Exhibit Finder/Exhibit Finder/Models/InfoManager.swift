//
//  ReminderManager.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/15/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation

struct ReminderManager {

	static var reminders: [Reminder] = []

	static var currentReminder: Reminder?
	
	static var exhibitsWithReminders: [Exhibit] = []
	
	static var exhibitDictionary: [Int64: Exhibit] = [:]
	
	static var reminderDictionary: [Int64: Reminder] = [:]
	
	static var urls: [Int64: URL] = [:]
}

struct ExhibitManager {
    
    static var currentIndex: IndexPath?
    static var currentType: DataType = .exhibitsOnly
    static var currentSource: [Exhibit] = ExhibitManager.exhibitsList
    static var isSearching = false
    
    static var exhibitsList: [Exhibit] = []
    static var searchResults: [Exhibit] = []
}

enum Removing {
    case time
    case location
}

enum Section {
    case exhibits
    case reminders
}

enum WithReminder {
    case time
    case location
    case both
}
