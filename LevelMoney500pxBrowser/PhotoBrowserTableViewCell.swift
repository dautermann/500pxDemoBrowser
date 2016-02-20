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
    @IBOutlet var photoImageView : LMImageView!
    @IBOutlet var userThumbnailImageView : CircleImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        photoImageView.image = nil
        photoImageView.imageURL = nil
        userThumbnailImageView.image = nil
        userThumbnailImageView.imageURL = nil
    }
}
