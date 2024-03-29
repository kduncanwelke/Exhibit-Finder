//
//  ExhibitLoadDelegate.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 8/21/20.
//  Copyright © 2020 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import CoreData

protocol ExhibitLoadDelegate: AnyObject {
    func loadExhibits(success: Bool)
}

enum DataType {
    case exhibitsOnly
    case exhibitsWithReminders
}

protocol ReminderDelegate: AnyObject {
    func getReminder(id: Int64)
}
