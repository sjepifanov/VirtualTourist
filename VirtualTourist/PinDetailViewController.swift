//
//  PinDetailViewController.swift
//  VirtualTourist
//
//  Created by Sergei on 03/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PinDetailViewController: UIViewController {
	
	let cellIdentifier = "PinPhotoCollectionCell"
	
	lazy var pin: Pin = {
		return Pin()
	}()
	
	// initializing array of NSBlockOperation to control collectionView objects deletion/updates
	// with PinDetailViewControllerFRCDelegate
	var blockOperations: [NSBlockOperation] = []
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var removeRefreshButton: UIButton!
	
	// MARK: - Initializing Views and Layout
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// collectionView Delegate and Data Source delegates are set in storyboard to PinDetailViewController
		
		// enable multiple cells selection
		collectionView.allowsMultipleSelection = true
		
		// Switch off automatic inset on top of collectionView
		automaticallyAdjustsScrollViewInsets = false
		
		// Render Map region in Pin Detail View
		configureMapView()
		
		sharedContext.shouldDeleteInaccessibleFaults = true
		
		// Set button title and initial state
		removeRefreshButton.enabled = false
		removeRefreshButton.setTitle("New Collection", forState: .Normal)
		
		fetchedResultsController.delegate = self
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSaveContext:", name: NSManagedObjectContextDidSaveNotification, object: nil)
		
		self.fetchPhotos()
		//if let photos = self.pin.photos {
		//	self.fetchBinaryData(photos)
		//}
		
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		// If there is no fetched photos request a new batch from Flickr
		if let photos = pin.photos where photos.isEmpty {
			self.getPhotosByLatLon()
		} else {
			removeRefreshButton.enabled = true
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		// Lay out the collection view so that cells take up 1/3 of the width,
		// with no space in between.
		let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
		
		layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		layout.minimumLineSpacing = 0
		layout.minimumInteritemSpacing = 0
		let width = floor(self.collectionView.frame.size.width/3)
		layout.itemSize = CGSize(width: width, height: width)
		
		collectionView.collectionViewLayout = layout
	}
	
	override func viewWillDisappear(animated: Bool) {
		// Deselect selected cells when view disappears
		collectionView.selectItemAtIndexPath(nil, animated: false, scrollPosition: .None)
		NSNotificationCenter.defaultCenter().removeObserver(self)
		saveContext()
	}
	
	// MARK: - Actions
	
	@IBAction func removeRefreshButtonAction(sender: AnyObject) {
		if let selectedItems  = collectionView.indexPathsForSelectedItems() where selectedItems.isEmpty {
			FlickrManager.sharedInstance.session.invalidateAndCancel()
			
			deleteAllPhotos()
			getPhotosByLatLon()
			
		} else {
			FlickrManager.sharedInstance.session.invalidateAndCancel()
			
			deleteSelectedPhotos()
			collectionView.selectItemAtIndexPath(nil, animated: false, scrollPosition: .None)
			removeRefreshButtonState()
		}
	}
	
	
	// MARK: - Core Data convenience properties
	
	lazy var sharedContext: NSManagedObjectContext =  {
		return CoreDataStackManager.sharedInstance.managedObjectContext
	}()
	
	// Fetched Result Controller for "Photo" entity
	lazy var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest = NSFetchRequest(entityName: Photo.Keys.entityName)
		
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: Photo.Keys.id, ascending: true)]
		
		let fetchResultController = NSFetchedResultsController(
			fetchRequest: fetchRequest,
			managedObjectContext: self.sharedContext,
			sectionNameKeyPath: nil,
			cacheName: "rootCache"
		)
		
		return fetchResultController
	}()
	
	// Fetched Result Controller for "ImageBinary" entity with cache
	/*
	lazy var fetchedResultsControllerImageBinary: NSFetchedResultsController = {
		let fetchRequest = NSFetchRequest(entityName: ImageData.Keys.Entity)
		
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: ImageData.Keys.Identifier, ascending: true)]
		
		let fetchResultController = NSFetchedResultsController(
			fetchRequest: fetchRequest,
			managedObjectContext: self.sharedContext,
			sectionNameKeyPath: nil,
			cacheName: ImageData.Keys.CacheName
		)
		
		return fetchResultController
	}()
	*/
	
	// MARK: - Methods
	
	func configureMapView() {
		guard let
			lat = pin.valueForKey(Pin.Keys.Latitude) as? CLLocationDegrees,
			lon = pin.valueForKey(Pin.Keys.Longitude) as? CLLocationDegrees else {
				return
		}
		
		let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
		let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0))
		
		self.mapView.setCenterCoordinate(center, animated: false)
		self.mapView.setRegion(region, animated: false)
		
		let annotation = MKPointAnnotation()
		annotation.coordinate = center
		
		self.mapView.addAnnotation(annotation)
	}
	
	func getPhotosByLatLon() {
		guard let
			lat = pin.valueForKey(Pin.Keys.Latitude) as? NSNumber,
			lon = pin.valueForKey(Pin.Keys.Longitude) as? NSNumber else {
				return
		}
		
		removeRefreshButton.enabled = false
		
		FlickrManager.sharedInstance.getFlickrPhotoByLatLon(latitude: lat, longitude: lon) { data, error in
			defer {
				Queue.Main.execute {
					self.saveContext()
					self.sharedContext.refreshAllObjects()
				}
			}
			
			guard let data = data as? [[String : AnyObject]] else {
				return
			}
			
			let photosDictionary = FlickrManager.sharedInstance.parsePhotosDictionary(data)
			
			photosDictionary.forEach { (dictionary: [String : NSString]) -> () in
				let photo = Photo(dictionary: dictionary, context: self.sharedContext)
				photo.location = self.pin
			}
		}
	}
	
	func deleteAllPhotos() {
		guard let photos = fetchedResultsController.fetchedObjects as? [Photo] else {
			return
		}
		
		photos.forEach {
			self.sharedContext.deleteObject($0)
		}
		saveContext()
		sharedContext.refreshAllObjects()
		
	}
	
	func deleteSelectedPhotos() {
		guard let selectedItems = collectionView.indexPathsForSelectedItems() else {
			return
		}
		selectedItems.forEach { (indexPath:(NSIndexPath)) -> Void in
			if let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Photo {
				self.sharedContext.deleteObject(photo)
			}
		}
		saveContext()
		sharedContext.refreshAllObjects()
		
	}
	
	
	// MARK: - Helpers
	
	// Fetch photos with predicate. Get photos for respective location
	func fetchPhotos() {
		NSFetchedResultsController.deleteCacheWithName("rootCache")
		do {
			self.fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "location = %@", self.pin)
			try self.fetchedResultsController.performFetch()
		} catch {
			return
		}
		collectionView.reloadData()
	}
	
	// Fetch image binary date for location photos
	/*
	func fetchBinaryData(photos: [Photo]) {
		// Clear cache before making another fetch request
		NSFetchedResultsController.deleteCacheWithName(ImageData.Keys.CacheName)
		photos.forEach { (photo: (Photo)) -> Void in
			do {
				self.fetchedResultsControllerImageBinary.fetchRequest.predicate = NSPredicate(format: "photo = %@", photo)
				try self.fetchedResultsControllerImageBinary.performFetch()
			} catch {
				return
			}
		}
	}
	*/
	func contextDidSaveContext (notification: NSNotification) {
		print("!!!!!CONTEXT SAVED!!!!!!")
		if !removeRefreshButton.enabled {
			removeRefreshButton.enabled = true
		}
	}
	
	func saveContext() {
		CoreDataStackManager.sharedInstance.saveContext()
	}
	
	func removeRefreshButtonState() {
		// Change button title depending on cells selection
		if let selectedItems = collectionView.indexPathsForSelectedItems() where selectedItems.isEmpty {
			self.removeRefreshButton.setTitle("New Collection", forState: .Normal)
		} else {
			self.removeRefreshButton.setTitle("Remove Selected Pictures", forState: .Normal)
		}
	}
}