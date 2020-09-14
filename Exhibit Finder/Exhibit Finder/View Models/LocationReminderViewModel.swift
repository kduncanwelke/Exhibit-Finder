//
//  LocationReminderViewModel.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 9/14/20.
//  Copyright © 2020 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import MapKit

public class LocationReminderViewModel {
    
    private let exhibitsViewModel = ExhibitsViewModel()
    
    // return time to display on labels, converting 24-hour time used in stepper to 12-hour time
    func returnTime(inputValue: Double) -> String {
        if inputValue < 12 {
            let value = Int(inputValue)
            return "\(value)am"
        } else if inputValue == 12 {
            let value = Int(inputValue)
            return "\(value)pm"
        } else if inputValue == 24 {
            let value = Int(inputValue) - 12
            return "\(value)am"
        } else {
            let value = Int(inputValue) - 12
            return "\(value)pm"
        }
    }
    
    func checkForLocation(mapView: MKMapView, selection: IndexPath?, withOverlay: Bool) {
        mapView.setRegion(LocationManager.getRegion(), animated: true)
        
        guard let index = selection else { return }
        let museum = exhibitsViewModel.getMuseum(index: index)
        
        if museum == "No museum listed" {
            return
        }
        
        // perform local search for museum by name, if it exists
        LocationManager.performSearch(museum: museum, mapView: mapView, withOverlay: withOverlay)
    }
}
