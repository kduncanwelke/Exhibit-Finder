//
//  DataManager.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/6/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation

// takes generic searchtype conforming object
struct DataManager<T: SearchType> {
	private static func fetch(url: URL, completion: @escaping (Result<T>) -> Void) {
		Networker.fetchData(url: url) { result in
			switch result {
			case .success(let data):
				guard let response = try? XMLParser.smithsonianDecoder.decode(T.self, from: data) else {
					return
				}
				completion(.success(response))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	static func fetch(completion: @escaping (Result<[T]>) -> Void) {
		fetch(url: URL(string: "https://d.asp6.si.edu/si-exhibits/exhibits.xml")!) { result in
			switch result {
			case .success(let result):
				var data: [T] = []
				data.append(result)
				completion(.success(data))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
}

// old url: http://logs2.smithsonian.museum/si-exhibits/exhibits.xml
