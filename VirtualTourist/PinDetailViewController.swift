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

private let entityName = "Photo"

//TODO: Add photoId to Data Model sort by photoId instead
private let sortDescriptor = "imageURL"

class PinDetailViewController: UIViewController {
	
	let cellIdentifier = "PinPhotoCollectionCell"
	var location: Pin? = nil
	
	// most likelly no need for that array as data will be fetched from core data store
	// var photos: [Photo]? = nil
	// temporary array to keep selected objects for deletion. may no be needed with FRC!
	//var objectsToDelete = [Photo]()
	
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
		getPhotosForPlaceId()
		fetchPhotos()
		print("Fetched objects: \(fetchedResultsController.fetchedObjects?.count)")
		print(" Pin photos: \(location?.photos.count)")
		// for photo in (location?.photos)! {
		//	print("URLS: \(photo.imageURL)")
		// }
		collectionView.reloadData()
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
		//TODO: - Change to struct values
		let fetchRequest = NSFetchRequest(entityName: entityName)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortDescriptor, ascending: true)]
		
		let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
		
		return fetchResultController
	}()
	
	func saveContext() {
		CoreDataStackManager.sharedInstance.saveContext()
	}
	
	// MARK: - Methods
	
	
	func getPhotosForPlaceId() {
		guard let
			pin = location,
			lat = location?.valueForKey(Pin.Keys.Latitude) as? NSNumber,
			lon = location?.valueForKey(Pin.Keys.Longitude) as? NSNumber else {
				print("No Pin!")
				return
		}
		FlickrManager.sharedInstance.getFlickrPlaceIdByLatLon(latitude: lat, longitude: lon) { data, error in
			guard let placeId = data as? String else {
				print("PlaceId. Error: \(error)")
				return
			}
			FlickrManager.sharedInstance.getFlickPhotosForPlaceId(placeId) { data, error in
				guard let photos = data as? [[String : AnyObject]] else {
					print("Photos. \(error)")
					return
				}
				let _ = photos.map { (object: [String : AnyObject]) -> Photo in
					let urlm = object["url_q"] as! NSString
					let dictionary = [Photo.Keys.imageURL : urlm]
					let photo = Photo(dictionary: dictionary, context: self.sharedContext)
					photo.location = pin
					return photo
				}
			}
		}
		CoreDataStackManager.sharedInstance.saveContext()
	}
	
	// MARK: - Experiments with different Flickr searches
	func getPhotosGeoPhotosForLocation() {
		guard let location = location else {
			return
		}
		guard let lat = location.valueForKey(Pin.Keys.Latitude) as? NSNumber,
			lon = location.valueForKey(Pin.Keys.Longitude) as? NSNumber else {
				return
		}

		FlickrManager.sharedInstance.getFlickrPhotosForLocation(latitude: lat, longitude: lon) { data, error in
			guard let photos = data as? [[String : AnyObject]] else {
				print("Photos. \(error)")
				return
			}
			let _ = photos.map { (object: [String : AnyObject]) -> Photo in
				let urlm = object["url_m"] as! NSString
				let dictionary = [Photo.Keys.imageURL : urlm]
				let photo = Photo(dictionary: dictionary, context: self.sharedContext)
				photo.location = location
				return photo
			}
			print("Got photos from handler! \(photos.count)")
		}
		print("Photos to pin: \(location.photos.count)")
	}

	func getPhotosForPlaceIdAndTags() {
		guard let
			pin = location,
			lat = location?.valueForKey(Pin.Keys.Latitude) as? NSNumber,
			lon = location?.valueForKey(Pin.Keys.Longitude) as? NSNumber else {
				print("No Pin!")
				return
		}
		
		FlickrManager.sharedInstance.getFlickrPlaceIdByLatLon(latitude: lat, longitude: lon) { data, error in
			guard let placeId = data as? String else {
				print("PlaceId. Error: \(error)")
				return
			}
			FlickrManager.sharedInstance.getFlickrTagsForPlace(placeId) { data, error in
				guard let tags = data as? String else {
					print("Tags. Error: \(error)")
					return
				}
				print(tags)
				FlickrManager.sharedInstance.getFlickPhotosForTags(tags, placeId: placeId) { data, error in
					guard let photos = data as? [[String : AnyObject]] else {
						print("Photos. \(error)")
						return
					}
					// TODO: - Re check Types in Data Model and get Types from object accordingly
					let _ = photos.map { (object: [String : AnyObject]) -> Photo in
						// Force unwrap will crash if there is no "url_m" key!
						let urlm = object["url_m"] as! NSString
						let dictionary = [Photo.Keys.imageURL : urlm]
						let photo = Photo(dictionary: dictionary, context: self.sharedContext)
						photo.location = pin
						return photo
					}
					
					CoreDataStackManager.sharedInstance.saveContext()
				}
			}
		}
	}
	
	// MARK: - Collection view helpers
	
	func fetchPhotos() -> Bool {
		do {
			try fetchedResultsController.performFetch()
		} catch {
			print("Perform fetch. Unresolved error \(error)")
			return false
		}
		return true
	}
	
	func deleteSelection() {
		// TODO: - verify deletion in accordance with FRC!!!
		
		// Get selected items paths from collectionView
		// If no items selected New Collection is requested.
		// Delete all current objects and reload collectionView/request new collection
		guard let selectedRows = collectionView.indexPathsForSelectedItems() as [NSIndexPath]? else {
			// Delete everything, delete the objects from core data model.
			location?.photos.removeAll(keepCapacity: false)
			collectionView.reloadSections(NSIndexSet(index: 0))
			// TODO: - not the right place to call
			// getPhotos()
			return
		}
		// If some photos are selected - cfeate an array for deletion and remove selected photos
		if !selectedRows.isEmpty {
			for selectedRow in selectedRows {
				let photo = fetchedResultsController.objectAtIndexPath(selectedRow) as? Photo
				sharedContext.deleteObject(photo!)
			}
			collectionView.deleteItemsAtIndexPaths(selectedRows)
		}
		CoreDataStackManager.sharedInstance.saveContext()
	}
}