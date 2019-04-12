//
//  Exhibit.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/6/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation

struct Exhibit: SearchType {
	let data: [Exhibition]
	static var endpoint = Endpoint.exhibit
}

struct Exhibition: Codable {
	let attributes: Attribute
}

struct Attribute: Codable {
	let title: String
	let description: Description
	let closeDate: String
	let openDate: String
	var museum: String?
	let permanentExhibition: Bool
	let offeredForTour: Bool
	var traveling: Bool
	var path: Path
}

struct Description: Codable {
	let processed: String
}

struct Path: Codable {
	let alias: String
	let pid: Int
}
