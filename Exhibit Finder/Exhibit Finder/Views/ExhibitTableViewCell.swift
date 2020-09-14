//
//  ExhibitTableViewCell.swift
//  Exhibit Finder
//
//  Created by Kate Duncan-Welke on 4/8/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import Nuke

class ExhibitTableViewCell: UITableViewCell {
    
    private let exhibitsViewModel = ExhibitsViewModel()
	
	// MARK: IBOutlets
	
	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var musuem: UILabel!
	@IBOutlet weak var closeDate: UILabel!
	@IBOutlet weak var hasReminder: UILabel!
	@IBOutlet weak var briefInfo: UILabel!
	@IBOutlet weak var reminderImage: UIImageView!
	@IBOutlet weak var cellImage: UIImageView!
	
	static let reuseIdentifier = "exhibitCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		cellImage.layer.cornerRadius = cellImage.frame.height / 2
		cellImage.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(index: IndexPath, segment: Int, searchText: String?) {
        var type: DataType
        
        // get type based on segment selection, change cell title color if reminders segment
        if segment == 0 {
            title.textColor = UIColor(red:0.00, green:0.00, blue:0.00, alpha:1.0)
            type = .exhibitsOnly
        } else {
            title.textColor = UIColor(red:0.44, green:0.44, blue:0.47, alpha:1.0)
            type = .exhibitsWithReminders
        }
        
        var data = exhibitsViewModel.setData(type: type, searchText: searchText)
        
        DispatchQueue.main.async {
            if let url = self.exhibitsViewModel.getImageUrl(index: index) {
                let request = ImageRequest(
                    url: url,
                    targetSize: CGSize(width: 140, height: 140),
                    contentMode: .aspectFill)
                
                Nuke.loadImage(with: request, options: NukeOptions.options, into: self.cellImage) { response, err in
                    if err != nil {
                        self.cellImage.image = NukeOptions.options.failureImage
                    } else {
                        self.cellImage?.image = response?.image
                    }
                }
            }
        }
        
        title.text = exhibitsViewModel.getTitle(index: index)
        musuem.text = exhibitsViewModel.getMuseum(index: index)
        briefInfo.text = exhibitsViewModel.getInfo(index: index)
        closeDate.text = exhibitsViewModel.getCloseDate(index: index)
        
        hasReminder.text = exhibitsViewModel.hasReminder(index: index)
        reminderImage.image = exhibitsViewModel.reminderImage(index: index)
    }
}
