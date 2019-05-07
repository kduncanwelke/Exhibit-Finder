//
//  Endpoint.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/6/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation

enum Endpoint {
	case exhibit
	
	private var baseURL: URL {
		return URL(string: "http://logs2.smithsonian.museum/si-exhibits/exhibits.xml")!
	}
	
	// generate url
	func url() -> URL {
		switch self {
		case .exhibit:
			return baseURL
		}
	}
}
