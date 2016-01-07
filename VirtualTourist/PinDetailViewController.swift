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
	
	var location: Pin? = nil
	var photos: [[String : AnyObject]]? = nil
	
	// delegate and data source delegate set in storyboard to PinDetailViewController
	// depending on complexity separate to different files
	@IBOutlet weak var collectionView: UICollectionView!
	
	// MARK: - Core Data Convenience
	lazy var sharedContext: NSManagedObjectContext =  {
		return CoreDataStackManager.sharedInstance.managedObjectContext
	}()
	func saveContext() {
		CoreDataStackManager.sharedInstance.saveContext()
	}
	lazy var fetchedResultsController: NSFetchedResultsController = {
		
		let fetchRequest = NSFetchRequest(entityName: "Photo")
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
		
		let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
		
		return fetchResultController
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		getPhotos()
	}
	
	// TODO: - break to modules with ability to configure parameters.
	func getPhotos() {
		guard let latitude = location?.valueForKey(Pin.Keys.Latitude) as? Double,
			let longitude = location?.valueForKey(Pin.Keys.Longitude) as? Double else {
				print("No Pin!")
				return
		}
		FlickrManager.sharedInstance.getFlickrPlaceIdByLatLon(latitude, longitude: longitude) { data, error in
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
}