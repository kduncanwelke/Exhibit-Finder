//
//  Exhibit.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/6/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation

struct Exhibits: SearchType {
	var exhibits: [Exhibit]
	static var endpoint = Endpoint.exhibit
	
	enum CodingKeys: String, CodingKey {
		case exhibits = "exhibit"
	}
}

struct Exhibit: Codable {
	var id: Int64
	var museum: String?
	var exhibit: String?
	var openingDate: String?
	var closingDate: String?
	var closeText: String?
	var location: String?
	var info: String?
	var infoBrief: String?
	var exhibitURL: String?
	var imgUrl: String?
	
	enum CodingKeys: String, CodingKey {
		case museum, exhibit, location, info
		
		case id = "ID"
		case openingDate = "openingdate"
		case closingDate = "closingdate"
		case closeText = "closetext"
		case infoBrief = "infobrief"
		case exhibitURL = "exhibit_gen_info_url"
		case imgUrl = "img256_url"
	}
}


struct Old {
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
}
