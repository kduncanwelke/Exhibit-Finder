//
//  SeeOnlineViewController.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/9/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import WebKit

class SeeOnlineViewController: UIViewController, WKNavigationDelegate {
	
	// MARK: IBOutlets
	
	@IBOutlet weak var webView: WKWebView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var dismissButton: UIButton!
	
	// MARK: Variables
	
	var urlToDisplay: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		dismissButton.layer.cornerRadius = 10
		webView.navigationDelegate = self
		
		activityIndicator.startAnimating()
		
		guard let url = urlToDisplay else { return }
		let urlRequest = URLRequest(url: url)
		webView.load(urlRequest)
    }
	
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		activityIndicator.stopAnimating()
	}
	
	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		activityIndicator.stopAnimating()
		showAlert(title: "Loading Error", message: "The webpage could not be loaded. Please check your network connection and try again.")
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
	
	@IBAction func dismissButtonTapped(_ sender: UIButton) {
		self.dismiss(animated: true, completion: nil)
	}
	
}

