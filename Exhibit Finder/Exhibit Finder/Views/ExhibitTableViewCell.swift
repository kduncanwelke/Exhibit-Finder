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
            title.textColor = UIColor.label
            type = .exhibitsOnly
        } else {
            title.textColor = UIColor.secondaryLabel
            type = .exhibitsWithReminders
        }
        
        exhibitsViewModel.setData(type: type, searchText: searchText)
        
        DispatchQueue.main.async {
            if let url = self.exhibitsViewModel.getImageUrl(index: index) {
                let request = ImageRequest(url: url, processors: [ImageProcessors.Resize(size: CGSize(width: 140, height: 140), contentMode: ImageProcessors.Resize.ContentMode.aspectFill)])
                
                Nuke.loadImage(with: request, options: NukeOptions.options, into: self.cellImage) { response, completed, total in
                    if response != nil {
                        self.cellImage?.image = response?.image
                    } else {
                        self.cellImage.image = NukeOptions.options.failureImage
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
