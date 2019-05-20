//
//  JSONDecoder.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/6/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import XMLParsing
// decoder for snakecase conversion
extension XMLParser {
	static var smithsonianDecoder: XMLDecoder {
		let decoder = XMLDecoder()
		return decoder
	}
}
