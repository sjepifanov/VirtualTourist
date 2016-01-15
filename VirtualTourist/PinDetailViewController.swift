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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// collectionView Delegate and Data Source delegates are set in storyboard to PinDetailViewController
		// enable multiple cells selection
		collectionView.allowsMultipleSelection = true
		// Switch off automatic inset on top of collectionView
		automaticallyAdjustsScrollViewInsets = false
		configureMapView(location)
		removeRefreshButton.enabled = false
		removeRefreshButton.setTitle("New Collection", forState: .Normal)
		fetchedResultsController.delegate = self
		fetchPhotos()
		print("Fetched objects: \(fetchedResultsController.fetchedObjects?.count)")
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		if let photos = location?.photos where photos.isEmpty {
			print("Empty")
			getPhotosByLatLon(location)
		} else {
			print("Some")
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
		print("ViewWillDisappear")
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
		// REplace sort descriptor with ENum key
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: Photo.Keys.id, ascending: true)]
		let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest,
			managedObjectContext: self.sharedContext,
			sectionNameKeyPath: nil,
			cacheName: nil)
		
		return fetchResultController
	}()
	
	func saveContext() {
		CoreDataStackManager.sharedInstance.saveContext()
	}
	
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
	
	func deleteAllPhotos() {
		guard let photos = fetchedResultsController.fetchedObjects as? [Photo] else {
			return
		}
		photos.forEach { (photo: (Photo)) -> Void in
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
	
	// MARK: - Methods
	
	func configureMapView(location: Pin?) {
		guard let
			pin = location,
			lat = location?.valueForKey(Pin.Keys.Latitude) as? NSNumber,
			lon = location?.valueForKey(Pin.Keys.Longitude) as? NSNumber else {
				print("No Pin!")
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
				print("No Pin!")
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
	
	func removeRefreshButtonState() {
		if let selectedItems = collectionView.indexPathsForSelectedItems() where !selectedItems.isEmpty {
			self.removeRefreshButton.setTitle("Remove Selected Pictures", forState: .Normal)
		} else {
			self.removeRefreshButton.setTitle("New Collection", forState: .Normal)
		}
	}
	
	// MARK: - Collection view helpers
	
	func fetchPhotos() -> Bool {
		guard let pin = location else {
			return false
		}
		do {
			fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "location = %@", pin)
			try fetchedResultsController.performFetch()
		} catch {
			print("Perform fetch. Unresolved error \(error)")
			return false
		}
		return true
	}
	
//EOF
}