//
//  PinDetailViewController.swift
//  VirtualTourist
//
//  Created by Sergei on 03/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class PinDetailViewController: UIViewController {

	let cellIdentifier = "PinPhotoCollectionCell"
	var location: Pin? = nil
	var photos: [Photo]? = nil
	// temporary array to keep selected objects for deletion. may no be needed with FRC!
	var objectsToDelete = [Photo]()
	
	// initializing array of NSBlockOperation to control collectionView objects deletion/updates 
	// used in PinDetailViewControllerFRCDelegate
	var blockOperations: [NSBlockOperation] = []
	
	// delegate and data source delegate set in storyboard to PinDetailViewController
	// TODO: - depending on complexity separate to different files
	@IBOutlet weak var collectionView: UICollectionView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// enable multiple cells selection
		collectionView.allowsMultipleSelection = true
		
		getPhotos()
	}
	
	override func viewWillDisappear(animated: Bool) {
		// Deselect cells
		collectionView.selectItemAtIndexPath(nil, animated: true, scrollPosition: .None)
	}
	
	// MARK: - Core Data Convenience
	lazy var sharedContext: NSManagedObjectContext =  {
		return CoreDataStackManager.sharedInstance.managedObjectContext
	}()
	
	lazy var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest = NSFetchRequest(entityName: "Photo")
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
		
		let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
		
		return fetchResultController
	}()
	
	func saveContext() {
		CoreDataStackManager.sharedInstance.saveContext()
	}
	
	// MARK: - Methods
	// TODO: - break to modules with ability to configure parameters.
	func getPhotos() {
		guard let lat = location?.valueForKey(Pin.Keys.Latitude) as? Double,
			lon = location?.valueForKey(Pin.Keys.Longitude) as? Double else {
				print("No Pin!")
				return
		}
		
		FlickrManager.sharedInstance.getFlickrPlaceIdByLatLon(lat, longitude: lon) { data, error in
			guard let placeId = data as? String else {
				print("PlaceId. Error: \(error)")
				return
			}
			FlickrManager.sharedInstance.getFlickrTagsForPlace(placeId) { data, error in
				guard let tags = data as? [String] else {
					print("Tags. Error: \(error)")
					return
				}
				FlickrManager.sharedInstance.getFlickPhotosForTags(tags, placeId: placeId) { data, error in
					guard let photos = data as? [[String : AnyObject]] else {
						print("Photos. \(error)")
						return
					}
					let _ = photos.map { (object: [String : AnyObject]) -> Photo in
						let urlm = object["url_m"] as! NSString
						let dictionary = [Photo.Keys.imageURL : urlm]
						let photo = Photo(dictionary: dictionary, context: self.sharedContext)
						photo.location = self.location!
						return photo
					}
					
					CoreDataStackManager.sharedInstance.saveContext()
					
					print("Got photos!")
					print("Photos count: \(photos.count)")
					print("Pin photos: \(self.location?.photos.count)")
					print("Pin photos path: \(self.location?.photos)")
				}
			}
		}
	}
	
	// MARK: - Collection view helpers
	
	func deleteSelection() {
		// Get selected items paths from collection View
		// Unwrapping here is not really necessary as .indexPathsForSelectedItems() returns empty array if no rows are selected and not nil.
		if let selectedRows = collectionView.indexPathsForSelectedItems() as [NSIndexPath]? {
			// Check if rows are selected
			if !selectedRows.isEmpty {
				// Create temporary array of selected items
				for selectedRow in selectedRows{
					objectsToDelete.append(photos![selectedRow.row])
				}
				// Find objects from temporary array in data source and delete them
				for object in objectsToDelete {
					if let index = photos!.indexOf(object){
						photos!.removeAtIndex(index)
					}
				}
				collectionView.deleteItemsAtIndexPaths(selectedRows)
				// Clear temporary array just in case
				objectsToDelete.removeAll(keepCapacity: false)
			}else{
				// Delete everything, delete the objects from data model.
				photos!.removeAll(keepCapacity: false)
				collectionView.reloadSections(NSIndexSet(index: 0))
			}
		}
	}
}