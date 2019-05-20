//
//  NukeOptions.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 5/8/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import UIKit
import Nuke
import CoreGraphics

struct NukeOptions {
	// loading options used by Nuke
	static let options = ImageLoadingOptions(placeholder: UIImage(named: "noimage"), transition: .fadeIn(duration: 0.33), failureImage: UIImage(named: "noimage"))
}
