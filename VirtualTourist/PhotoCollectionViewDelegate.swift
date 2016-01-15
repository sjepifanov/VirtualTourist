//
//  PhotoCollectionViewDelegate.swift
//  VirtualTourist
//
//  Created by Sergei on 07/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import UIKit

extension PinDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	
	// MARK: - Delegate Methods
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		// Get number of sections
		return fetchedResultsController.sections?.count ?? 0
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		// Get number of objects in fetchedResultsController section
		return fetchedResultsController.sections?[section].numberOfObjects ?? 0
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PinDetailViewCell
		
		// check if cell is selected and set alpha appropriatelly. otherwise reused cells may appear as selected though actually not
		cell.selected ? (cell.alpha = 0.5) : (cell.alpha = 1.0)
		
		// configure cell
		configureCell(cell, photo: photo)
		
		return cell
	}
	
	// Manage cell selection
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
			cell.alpha = 0.5
		}
		
		removeRefreshButtonState()
	}
	
	func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
		if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
			cell.alpha = 1
		}

		removeRefreshButtonState()
	}
	
	// MARK: - Configure Cell
	
	func configureCell(cell: PinDetailViewCell, photo: Photo) {
		var image = UIImage(named: "placeHolder")
		cell.layer.borderColor = UIColor.whiteColor().CGColor
		cell.layer.borderWidth = 1
		
		// Set image to nil so reused cell won't appear with the same image
		cell.cellImageView.image = nil
		
		// If image is cached, set it as cell image else download an image
		if photo.image != nil {
			image = photo.image
		} else {
			cell.activityIndicator.startAnimating()
			Queue.UserInitiated.execute { () -> Void in
				let task = FlickrManager.sharedInstance.downloadImage(photo.imageURL as String) { imageData, error in
					guard let imageData = imageData as? NSData else {
						print(error)
						return
					}
					
					let image = UIImage(data: imageData)
					photo.image = image
					
					Queue.Main.execute { () -> Void in
						cell.activityIndicator.stopAnimating()
						cell.cellImageView.image = image
					}
				}
				
				cell.taskToCancelifCellIsReused = task
			}
		}
		
		cell.cellImageView?.image = image
	}
}