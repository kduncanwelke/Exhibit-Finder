//
//  DetailViewModel.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 9/14/20.
//  Copyright © 2020 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import UIKit
import MapKit

public class DetailViewModel {
    
    private var exhibitsViewModel = ExhibitsViewModel()
    private var reminderViewModel = ReminderViewModel()
    
    func loadMapView(mapView: MKMapView, selection: IndexPath?) {
        // coordinates for the national mall
        mapView.setRegion(LocationManager.getRegion(), animated: true)
        
        guard let index = selection else { return }
        
        let museum = exhibitsViewModel.getMuseum(index: index)
        
        if museum == "No museum listed" {
            return
        }
        
        // perform local search for museum by name, if it exists
        LocationManager.performSearch(museum: museum, mapView: mapView, withOverlay: false)
    }
    
    func setSelectedBarViewController(index: IndexPath) -> Int {
        // there is a reminder
        if let reminder = exhibitsViewModel.getReminderForExhibit(indexPath: index) {
            
            var type: WithReminder
            guard let typeOfReminder = reminderViewModel.getReminderType() else { return 0 }
            
            type = typeOfReminder
            
            // set selected view based on which reminders exist
            switch type {
            case .both, .time:
                // go to time reminder if there is a time reminder or both time and location
                return 0
            case .location:
                return 1
            }
        } else {
            // there is no reminder
            // go to time reminder by default if there is no reminder
           return 0
        }
    }
}
