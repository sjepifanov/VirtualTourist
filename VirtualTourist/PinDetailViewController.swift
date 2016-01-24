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
	
	lazy var pin: Pin = Pin()
	
	// initializing array of NSBlockOperation to control collectionView objects deletion/updates
	// with PinDetailViewControllerFRCDelegate
	var blockOperations: [NSBlockOperation] = []
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var removeRefreshButton: UIButton!
	@IBOutlet weak var noPhotosLabel: UILabel!
	
	// MARK: - Initializing Views and Layout
	
	override func viewDidLoad() {
		super.viewDidLoad()
		configureView()
		
		sharedContext.shouldDeleteInaccessibleFaults = true
		fetchedResultsController.delegate = self
		
		// Add observer on sharedContext did Save Notification
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSaveContext:", name: NSManagedObjectContextDidSaveNotification, object: nil)

		fetchPhotos()
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		collectionView.layoutIfNeeded()
		removeRefreshButton.enabled = true
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
		
		// Remove observer
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	// MARK: - Actions
	
	@IBAction func removeRefreshButtonAction(sender: AnyObject) {
		if let selectedItems  = collectionView.indexPathsForSelectedItems() where selectedItems.isEmpty {
			FlickrManager.sharedInstance.session.invalidateAndCancel()
			deleteAllPhotos()
			getPhotosByLatLon()
		} else {
			deleteSelectedPhotos()
			// Deselect cells. Sometimes cell selections are not cleared when done through FRC with delegate.
			collectionView.selectItemAtIndexPath(nil, animated: false, scrollPosition: .None)
			saveContextAndRefresh()
			setButtonTitle()
		}
	}
	
	// MARK: - Helpers
	
	// MARK: Core Data
	
	// Shared Context
	lazy var sharedContext: NSManagedObjectContext = CoreDataStackManager.sharedInstance.managedObjectContext
	
	// Fetched Result Controller for "Photo" entity.
	lazy var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest = NSFetchRequest(entityName: Photo.Keys.EntityName)
		let sortDescriptor = NSSortDescriptor(key: Photo.Keys.Id, ascending: true)
		fetchRequest.sortDescriptors = [sortDescriptor]
		
		let fetchResultController = NSFetchedResultsController(
			fetchRequest: fetchRequest,
			managedObjectContext: self.sharedContext,
			sectionNameKeyPath: nil,
			cacheName: Photo.Keys.CacheName
		)
		
		return fetchResultController
	}()
	
	func saveContextAndRefresh() {
		do {
			try CoreDataStackManager.sharedInstance.saveContext()
		} catch let error as NSError {
			self.showAlert(error.localizedDescription)
		}
		
		sharedContext.refreshAllObjects()
	}
	
	// MARK: Photo Management
	
	// Get JSON data for Flickr search request by Latitude and Longitude
	// Parse data to retrieve no more than 21 records
	func getPhotosByLatLon() {
		
		removeRefreshButton.enabled = false
		noPhotosLabel.hidden = true
		noPhotosLabel.textColor = .whiteColor()
		
		guard let
			lat = pin.valueForKey(Pin.Keys.Latitude) as? NSNumber,
			lon = pin.valueForKey(Pin.Keys.Longitude) as? NSNumber else {
				return
		}
		
		FlickrManager.sharedInstance.getFlickrPhotoByLatLon(latitude: lat, longitude: lon) { data, error in
			// Delay context save and interface update untill method is done
			guard let data = data as? [[String : AnyObject]] else {
				self.showAlert(error!)
				return
			}
			
			// Parse JSON responce, prepare array of photo records.
			let photosDictionary = FlickrManager.sharedInstance.parsePhotosDictionary(data)
			
			// Add photo objects from parsed array to Core Data
			defer {
				Queue.Main.execute {
					for dictionary in photosDictionary {
						let photo = Photo(dictionary: dictionary, context: self.sharedContext)
						photo.location = self.pin
					}
					self.saveContextAndRefresh()
					
					self.removeRefreshButton.enabled = true
					
					if let photos = self.pin.photos where photos.isEmpty {
						self.noPhotosLabel.hidden = false
						self.noPhotosLabel.textColor = .grayColor()
					}
				}
			}
		}
	}
	
	// Fetch photos with predicate. Get photos for respective location
	func fetchPhotos() {
		NSFetchedResultsController.deleteCacheWithName(Photo.Keys.CacheName)
		do {
			self.fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "location = %@", self.pin)
			try self.fetchedResultsController.performFetch()
		} catch {
			return
		}
	}

	func deleteAllPhotos() {
		guard let photos  = fetchedResultsController.fetchedObjects as? [Photo] else {
			return
		}
		for photo in photos{
			sharedContext.deleteObject(photo)
		}
	}
	
	func deleteSelectedPhotos() {
		guard let selectedItems = collectionView.indexPathsForSelectedItems() else {
			return
		}
		
		for indexPath in selectedItems {
			if let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Photo {
				self.sharedContext.deleteObject(photo)
			}
		}
	}
	
	// MARK: View
	
	func configureView() {
		// collectionView Delegate and Data Source delegates are set in storyboard to PinDetailViewController
		
		// enable multiple cells selection
		collectionView.allowsMultipleSelection = true
		
		// Switch off automatic inset on top of collectionView
		automaticallyAdjustsScrollViewInsets = false
		
		// Render Map region in Pin Detail View
		configureMapView()
		
		noPhotosLabel.hidden = true
		noPhotosLabel.textColor = .whiteColor()
		
		removeRefreshButton.enabled = false
		removeRefreshButton.setTitle("New Collection", forState: .Normal)
	}
	
	// Setup mapView region and annotation point
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
	
	func setButtonTitle() {
		// Change button title depending on cells selection
		if let selectedItems = collectionView.indexPathsForSelectedItems() where selectedItems.isEmpty {
			self.removeRefreshButton.setTitle("New Collection", forState: .Normal)
		} else {
			self.removeRefreshButton.setTitle("Remove Selected Pictures", forState: .Normal)
		}
	}
	
	
	// MARK: - contextDidSaveContext Observer
	
	func contextDidSaveContext (notification: NSNotification) {
	}
}