//
//  PhotoBrowserTableViewCell.swift
//  LevelMoney500pxBrowser
//
//  Created by Michael Dautermann on 2/18/16.
//  Copyright © 2016 Michael Dautermann. All rights reserved.
//

import UIKit

class PhotoBrowserTableViewCell: UITableViewCell {

    @IBOutlet var titleLabel : UILabel!
    @IBOutlet var userNameLabel : UILabel!
    @IBOutlet var photoImageView : UIImageView!
    @IBOutlet var userThumbnailImageView : CircleImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
