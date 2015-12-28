//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Sergei on 23/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController {
	
	struct Keys {
		static let Latitude = "latitude"
		static let Longitude = "longitude"
		static let LatitudeDelta = "latitudeDelta"
		static let LongitudeDelta = "longitudeDelta"
	}
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet var longPressRecognizer: UILongPressGestureRecognizer!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		longPressRecognizer.minimumPressDuration = 1.0
		mapView.delegate = self
		restoreMapRegion(false)
		do {
			try fetchedResultsController.performFetch()
		} catch {
			print("Unresolved error \(error)")
			abort()
		}
		mapView.addAnnotations(getAnnotationsFromFetchedResuls())
		
	}
	
	@IBAction func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
		if gestureRecognizer.state != .Began { return }
		let touchPoint = gestureRecognizer.locationInView(mapView)
		let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
		
		let dictionary = [
			Keys.Latitude: touchMapCoordinate.latitude,
			Keys.Longitude: touchMapCoordinate.longitude
		]
		let annotation = Pin(dictionary: dictionary, context: sharedContext)
		
		mapView.addAnnotation(annotation)
		
		CoreDataStackManager.sharedInstance.saveContext()
	}
	
	
	// MARK: - NSKeyedArchiver CoreData Convinience
	
	// FilePath property
	var filePath: String? {
		let manager = NSFileManager.defaultManager()
		guard let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL? else {
			print("Unable to access Documents Directory")
			return nil
		}
		return url.URLByAppendingPathComponent("mapRegionArchieve").path
	}
	
	// Manged Object Context property
	lazy var sharedContext: NSManagedObjectContext  = {
		return CoreDataStackManager.sharedInstance.managedObjectContext
	}()
	
	// Fetched Results Controller property
	lazy var fetchedResultsController: NSFetchedResultsController = {
		// Create the fetch request
		let fetchRequest = NSFetchRequest(entityName: "Pin")
		// Add a sort descriptor.
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: Keys.Latitude, ascending: true)]
		// Create the Fetched Results Controller
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
		return fetchedResultsController
	}()
	
	// MARK: - Helpers
	
	// Restore Map Region
	func restoreMapRegion(animated: Bool) {
		// TODO: - Remove print statements. Either implement error message or silent return.
		// Check filePath
		guard let filePath = filePath else {
			print("File does not exist")
			return
		}
		// Unarchive a dictionary
		guard let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String: AnyObject] else {
			print("Unable to access stored map region")
			return
		}
		// Downcast dictionary elements to correct type
		guard let latitude = regionDictionary[Keys.Latitude] as? CLLocationDegrees,
			let longitude = regionDictionary[Keys.Longitude] as? CLLocationDegrees,
			let latitudeDelta = regionDictionary[Keys.LatitudeDelta] as? CLLocationDegrees,
			let longitudeDelta = regionDictionary[Keys.LongitudeDelta] as? CLLocationDegrees else {
				print("Downcast from dictionary coordinates to CLLocationDegrees failed")
				return
		}
		// Create coordinates for restored region
		let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
		let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
		let savedRegion = MKCoordinateRegion(center: center, span: span)
		
		// Set map coordinates to restored region
		mapView.setRegion(savedRegion, animated: animated)
	}
	
	// Create Annotations Array
	func getAnnotationsFromFetchedResuls() -> [MKPointAnnotation] {
		// Check if we have fetched objects, else return empty array
		guard let locations = fetchedResultsController.fetchedObjects as? [Pin] else {
			return []
		}
		// Initialize empty annotations array
		var annotations: [MKPointAnnotation] = []
		// Add annotations to array
		for location in locations {
			let latitude = CLLocationDegrees(location.latitude)
			let longitude = CLLocationDegrees(location.longitude)
			let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
			
			let annotation = MKPointAnnotation()
			annotation.coordinate = coordinate
			annotations.append(annotation)
		}
		// Return annotations
		return annotations
	}

}