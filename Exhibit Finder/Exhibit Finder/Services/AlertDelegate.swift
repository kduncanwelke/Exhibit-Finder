//
//  AlertDelegate.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 8/21/20.
//  Copyright © 2020 Kate Duncan-Welke. All rights reserved.
//

import Foundation

protocol AlertDisplayDelegate: class {
    func displayAlert(with title: String, message: String)
}
