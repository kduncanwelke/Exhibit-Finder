//
//  Extensions.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/8/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import UIKit

extension UISplitViewController {
	var primaryViewController: MasterViewController? {
		let navController = self.viewControllers.first as? UINavigationController
		return navController?.topViewController as? MasterViewController
	}
}

// add reusable alert functionality
extension UIViewController {
	func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
		alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
		self.present(alert, animated: true, completion: nil)
	}
	
	func showSettingsAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
		alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
		alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { value in
			let path = UIApplication.openSettingsURLString
			if let settingsURL = URL(string: path), UIApplication.shared.canOpenURL(settingsURL) {
				UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
			}
		})
		self.present(alert, animated: true, completion: nil)
	}
}

extension String {
	static func removeHTMLWithoutSpacing(from string: String) -> String {
		let newString = string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil).replacingOccurrences(of: "&nbsp;", with: "").replacingOccurrences(of: "&mdash;", with: "—").replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "&apos;", with: "\'").replacingOccurrences(of: "&amp;", with: "&").replacingOccurrences(of: "&rsquo;", with: "\'")
		return newString
	}
	
	static func removeHTML(from string: String) -> String {
		let newString = string.replacingOccurrences(of: "</p>", with: "\n").replacingOccurrences(of: "<li>", with: "-").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil).replacingOccurrences(of: "&nbsp;", with: "").replacingOccurrences(of: "&mdash;", with: "—").replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "&apos;", with: "\'").replacingOccurrences(of: "&amp;", with: "&").replacingOccurrences(of: "<li>", with: "-").replacingOccurrences(of: "&rsquo;", with: "\'")
		return newString
	}
}
