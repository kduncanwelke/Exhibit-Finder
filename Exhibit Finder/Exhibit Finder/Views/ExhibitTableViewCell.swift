//
//  ExhibitTableViewCell.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/8/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit

class ExhibitTableViewCell: UITableViewCell {
	
	// MARK: IBOutlets
	
	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var musuem: UILabel!
	@IBOutlet weak var openDate: UILabel!
	@IBOutlet weak var closeDate: UILabel!
	@IBOutlet weak var hasReminder: UILabel!
	@IBOutlet weak var briefInfo: UILabel!
	@IBOutlet weak var reminderImage: UIImageView!
	
	static let reuseIdentifier = "exhibitCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
