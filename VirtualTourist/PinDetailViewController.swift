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
import MapKit

private let entityName = "Photo"

class PinDetailViewController: UIViewController {
	
	let cellIdentifier = "PinPhotoCollectionCell"
	var location: Pin? = nil
	
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
		configureMapView(location)
		
		// Set button title and initial state
		removeRefreshButton.enabled = false
		removeRefreshButton.setTitle("New Collection", forState: .Normal)
		
		fetchedResultsController.delegate = self
		
		fetchPhotos()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		// If there is no fetched photos request a new batch from Flickr
		if let photos = location?.photos where photos.isEmpty {
			getPhotosByLatLon(location)
		} else {
			removeRefreshButton.enabled = true
			collectionView.reloadData()
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
		collectionView.selectItemAtIndexPath(nil, animated: true, scrollPosition: .None)
	}
	
	// MARK: - Action
	
	@IBAction func removeRefreshButtonAction(sender: AnyObject) {
		if let selectedItems  = collectionView.indexPathsForSelectedItems() where selectedItems.isEmpty {
			deleteAllPhotos()
			getPhotosByLatLon(location)
		} else {
			deleteSelectedPhotos()
			collectionView.selectItemAtIndexPath(nil, animated: true, scrollPosition: .None)
			removeRefreshButtonState()
		}
		saveContext()
	}
	
	
	// MARK: - Core Data convenience properties
	
	lazy var sharedContext: NSManagedObjectContext =  {
		return CoreDataStackManager.sharedInstance.managedObjectContext
	}()
	
	lazy var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest = NSFetchRequest(entityName: entityName)
		
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: Photo.Keys.id, ascending: true)]
		
		let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest,
			managedObjectContext: self.sharedContext,
			sectionNameKeyPath: nil,
			cacheName: nil)
		
		return fetchResultController
	}()

	
	// MARK: - Methods
	
	func configureMapView(location: Pin?) {
		guard let
			pin = location,
			lat = location?.valueForKey(Pin.Keys.Latitude) as? NSNumber,
			lon = location?.valueForKey(Pin.Keys.Longitude) as? NSNumber else {
				return
		}
		let center = CLLocationCoordinate2D(latitude: lat as CLLocationDegrees, longitude: lon as CLLocationDegrees)
		let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0))
		self.mapView.setCenterCoordinate(center, animated: true)
		self.mapView.setRegion(region, animated: true)
		pin.setCoordinate(center)
		self.mapView.addAnnotation(pin)
	}
	
	func getPhotosByLatLon(location: Pin?) {
		guard let
			pin = location,
			lat = location?.valueForKey(Pin.Keys.Latitude) as? NSNumber,
			lon = location?.valueForKey(Pin.Keys.Longitude) as? NSNumber else {
				return
		}
		
		self.removeRefreshButton.enabled = false
		
		Queue.UserInitiated.execute { () -> Void in
			FlickrManager.sharedInstance.getFlickrPhotoByLatLon(latitude: lat, longitude: lon) { data, error in
				guard let data = data as? [[String : AnyObject]] else {
					print("Photos. \(error)")
					return
				}
				let photosDictionary = FlickrManager.sharedInstance.parsePhotosDictionary(data)
				photosDictionary.forEach { (dictionary: [String : NSString]) -> () in
					let photo = Photo(dictionary: dictionary, context: self.sharedContext)
					photo.location = pin
				}
				self.removeRefreshButton.enabled = true
				self.saveContext()
			}
			Queue.Main.execute { self.collectionView.reloadData() }
		}
	}
	
	func deleteAllPhotos() {
		guard let photos = fetchedResultsController.fetchedObjects as? [Photo] else {
			return
		}
		
		photos.forEach { (photo: (Photo)) -> Void in
			// delete image files from caches
			photo.image = nil
			sharedContext.deleteObject(photo)
		}
	}
	
	func deleteSelectedPhotos() {
		guard let selectedItems = collectionView.indexPathsForSelectedItems() else {
			return
		}
		selectedItems.forEach { (indexPath:(NSIndexPath)) -> Void in
			if let photo = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo {
				photo.image = nil
				sharedContext.deleteObject(photo)
			}
		}
	}
	
	
	// MARK: - Collection view helpers
	
	// Fetch photos with predicate. Get photos for respective location
	func fetchPhotos() -> Bool {
		guard let pin = location else {
			return false
		}
		
		do {
			fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "location = %@", pin)
			try fetchedResultsController.performFetch()
		} catch {
			return false
		}
		
		return true
	}
	
	func saveContext() {
		CoreDataStackManager.sharedInstance.saveContext()
	}
	
	func removeRefreshButtonState() {
		// Change button title depending on cells selection
		if let selectedItems = collectionView.indexPathsForSelectedItems() where !selectedItems.isEmpty {
			self.removeRefreshButton.setTitle("Remove Selected Pictures", forState: .Normal)
		} else {
			self.removeRefreshButton.setTitle("New Collection", forState: .Normal)
		}
	}

}