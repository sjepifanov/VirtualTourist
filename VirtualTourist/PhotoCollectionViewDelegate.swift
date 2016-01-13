//
//  PhotoCollectionViewDelegate.swift
//  VirtualTourist
//
//  Created by Sergei on 07/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import UIKit

extension PinDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return fetchedResultsController.sections?.count ?? 0
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		// Get number of objects in fetchedResultsController section
		return fetchedResultsController.sections?[section].numberOfObjects ?? 0
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		// TODO: - Force unwrap!!!
		let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PinDetailViewCell
		
		// TODO: - move cell configuration to separate method
		// check if cell is selected and set alpha appropriatelly. otherwise reused cells may appear as selected though actually not
		cell.selected ? (cell.alpha = 0.5) : (cell.alpha = 1.0)
		// TODO: - add image to cell through cache
		
		FlickrManager.sharedInstance.getFlickrPhoto(photo.imageURL) {data, error in
			let image = UIImage(data: data!)
			Queue.Main.execute { cell.cellImageView.image = image }
		}
		
		return cell
	}
	
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		
		// TODO: - when at least one item is selected update UIButton title to "Delete Photos"(implement)
		print("Select cell at: \(indexPath)")
		
		if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
			cell.alpha = 0.5
		}
		
		removeRefreshButtonState()
	}
	
	func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
		print("Deselect cell at: \(indexPath)")
		if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
			cell.alpha = 1
		}
		// TODO: - Button state inconsitent! Verify!
		removeRefreshButtonState()
	}
}