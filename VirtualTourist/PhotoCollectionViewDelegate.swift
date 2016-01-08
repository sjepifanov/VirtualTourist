//
//  PhotoCollectionViewDelegate.swift
//  VirtualTourist
//
//  Created by Sergei on 07/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import UIKit

extension PinDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		// replace with actual data
		return location?.photos.count ?? 0
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PinDetailViewCell
		// check if cell is selected and set alpha appropriatelly. otherwise reused cells may appear as selected though actually not
		cell.selected ? (cell.alpha = 0.5) : (cell.alpha = 1.0)
		
		// add image to cell
		
		return cell
	}
	
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		
		// TODO: - when at least one item is selected update UIButton title to "Delete Photos"(implement)
		
		if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
			cell.alpha = 0.5
		}
	}
}