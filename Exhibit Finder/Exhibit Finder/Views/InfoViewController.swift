//
//  InitialViewController.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 5/18/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {
	
	// MARK: IBOutlets
	
	@IBOutlet weak var websiteButton: UIButton!
	@IBOutlet weak var privacyButton: UIButton!
	
	// MARK: Variables
	
	var dateFormatter = DateFormatter()
	var currentDate = Date()
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		websiteButton.layer.cornerRadius = 10
		privacyButton.layer.cornerRadius = 10
    }
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
	
	// MARK: IBActions
	
	@IBAction func websiteButtonPressed(_ sender: UIButton) {
		guard let url = URL(string: "https://www.si.edu") else { return }
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}
	
	@IBAction func privacyButtonPressed(_ sender: UIButton) {
		guard let url = URL(string: "") else { return }
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}

}
