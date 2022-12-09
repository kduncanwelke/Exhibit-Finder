//
//  NetworkMonitor.swift
//  Exhibit Finder
//
//  Created by Katherine Duncan-Welke on 12/9/22.
//  Copyright © 2022 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import Network

struct NetworkMonitor {
    
    static let monitor = NWPathMonitor()
    static var connection = true
}
