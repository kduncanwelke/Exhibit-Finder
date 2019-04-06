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
		return URL(string: "https://api.si.edu/saam/v1/")!
	}
	
	private var key: String {
		return "xOMCoRA95NTF3Mnced80jpDUGA0WImSdAYNnCsHW"
	}
	
	// generate url based on type
	func url(with page: Int?) -> URL {
		switch self {
		case .exhibit:
			var components = URLComponents(url: baseURL.appendingPathComponent("exhibitions"), resolvingAgainstBaseURL: false)
			components!.queryItems = [URLQueryItem(name: "api_key", value: "\(key)"), URLQueryItem(name: "sort", value: "-close_date,-open_date")]
			return components!.url!
		}
	}
}
