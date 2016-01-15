//
//  PinDetailViewCell.swift
//  VirtualTourist
//
//  Created by Sergei on 04/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation
import UIKit

class PinDetailViewCell: UICollectionViewCell {
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var cellImageView: UIImageView!
	
	// Cancel initiated download task when cell is reused
	var taskToCancelifCellIsReused: NSURLSessionTask? {
		didSet {
			if let taskToCancel = oldValue { taskToCancel.cancel() }
		}
	}
}
