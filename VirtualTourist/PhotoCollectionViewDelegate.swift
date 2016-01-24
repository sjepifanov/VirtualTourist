//
//  PhotoCollectionViewDelegate.swift
//  VirtualTourist
//
//  Created by Sergei on 07/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import UIKit

extension PinDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	
	// MARK: - Photo Collection View Delegate
	
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
		
		configureCell(cell, photo: photo)
		
		return cell
	}
	
	// Manage cell selection
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		
		collectionView.cellForItemAtIndexPath(indexPath)!.alpha = 0.5
		
		setButtonTitle()
	}
	
	func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
		
		collectionView.cellForItemAtIndexPath(indexPath)!.alpha = 1
		
		setButtonTitle()
	}
	
	// MARK: - Configure Cell
	
	func configureCell(cell: PinDetailViewCell, photo: Photo) {
		// Set place holder image
		var image = UIImage(named: "placeHolder")
		
		cell.layer.borderColor = UIColor.whiteColor().CGColor
		cell.layer.borderWidth = 1
		// check if cell is selected and set alpha appropriatelly.
		cell.selected ? (cell.alpha = 0.5) : (cell.alpha = 1.0)
	
		// Get the image from Caches if exist. Otherwise download via URL.
		switch photo.image {
		case .Some:
			guard let image = photo.image else { break }
			
			cell.cellImageView.image = image
			
		case nil:
			guard let imageURL = photo.imageURL as? String else { break }

			cell.activityIndicator.startAnimating()
			cell.cellImageView.image = image
			
			Queue.UserInitiated.execute {
				let task = FlickrManager.sharedInstance.downloadImage(imageURL) { imageData, error in
					guard let imageData = imageData as? NSData else {
						return
					}
					
					image = UIImage(data: imageData)
					
					Queue.Main.execute {
						cell.activityIndicator.stopAnimating()
						cell.cellImageView.image = image
						
						guard let _ = photo.id else { return }
						photo.image = image
					}
				}
				Queue.Main.execute { cell.taskToCancelifCellIsReused = task }
			}
		}
	}
}