//
//  TimeReminderViewModel.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 9/14/20.
//  Copyright © 2020 Kate Duncan-Welke. All rights reserved.
//

import Foundation

public class TimeReminderViewModel {
    
    // turn date into string to display
    func getDate(from stringDate: String) -> Date? {
        guard let createdDate = dateFormatter.date(from: stringDate) else {
            print("date conversion failed")
            return nil
        }
        return createdDate
    }
    
    // get string from date
    func getStringDate(from date: Date) -> String {
        let createdDate = timeDateFormatter.string(from: date)
        return createdDate
    }
}
