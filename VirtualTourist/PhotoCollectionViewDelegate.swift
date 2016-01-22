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
		
		// check if cell is selected and set alpha appropriatelly.
		// otherwise reused cells may appear as selected though actually not
		cell.selected ? (cell.alpha = 0.5) : (cell.alpha = 1.0)
		// Set image to nil so reused cell won't appear with the same image
		cell.cellImageView.image = nil
		cell.activityIndicator.stopAnimating()
		
		// If image is in Core Data, set it as cell image else download an image
		switch photo.image?.imageData {
		case .Some:
			guard let imageData = photo.image?.imageData else { break }
			image = UIImage(data: imageData)
			
			cell.cellImageView.image = image
			
		case nil:
			guard let imageURL = photo.imageURL as? String else { break }

			cell.activityIndicator.startAnimating()
			
			Queue.UserInitiated.execute {
				let task = FlickrManager.sharedInstance.downloadImage(imageURL) { imageData, error in
					guard let imageData = imageData as? NSData else {
						self.showAlert(error!)
						return
					}
					
					image = UIImage(data: imageData)
					
					Queue.Main.execute {
						cell.activityIndicator.stopAnimating()
						cell.cellImageView.image = image
						
						guard let _ = photo.id else { return }
						
						// Add imageBinary data to Core Data and assign properties
						let imageBinary = ImageData(data: imageData, context: self.sharedContext)
						photo.image = imageBinary
					}
				}
				Queue.Main.execute { cell.taskToCancelifCellIsReused = task }
			}
			cell.cellImageView.image = image
		}
	}
}