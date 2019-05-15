//
//  Errors.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/6/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation

// error to be used in the case of bad access to network
enum Errors: Error {
	case networkError
	case otherError
	
	var localizedDescription: String {
		switch self {
		case .networkError:
			return "The Smithsonian data could not be reached successfully at this time - please try again later."
		case .otherError:
			return "The network could not be reached successfully - please check your network connection and try again."
		}
	}
}
