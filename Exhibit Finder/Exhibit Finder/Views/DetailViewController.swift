//
//  DetailViewController.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/6/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

	// MARK: IBOutlets
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var museumLabel: UILabel!
	@IBOutlet weak var openDateLabel: UILabel!
	@IBOutlet weak var closeDateLabel: UILabel!
	@IBOutlet weak var permanentLabel: UILabel!
	@IBOutlet weak var tourLabel: UILabel!
	@IBOutlet weak var travelingLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	
	// MARK: Variables
	
	var detailItem: Exhibition?

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		configureView()
	}

	func configureView() {
		// Update the user interface for the detail item.
		guard let detail = detailItem else { return }
		titleLabel.text = detail.attributes.title
		museumLabel.text = detail.attributes.museum ?? "No museum listed"
		let open = detail.attributes.openDate.dropLast(14)
		openDateLabel.text = "\(open)"
		let close = detail.attributes.closeDate.dropLast(14)
		closeDateLabel.text = "\(close)"
	
		permanentLabel.text = {
			if detail.attributes.permanentExhibition {
				return "Yes"
			} else {
				return "No"
			}
		}()
	
		tourLabel.text = {
			if detail.attributes.offeredForTour {
				return "Yes"
			} else {
				return "No"
			}
		}()
	
		travelingLabel.text = {
			if detail.attributes.traveling {
				return "Yes"
			} else {
				return "No"
			}
		}()
	
		descriptionLabel.text = detail.attributes.description.processed.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil).replacingOccurrences(of: "&nbsp;", with: "")
	}
}

