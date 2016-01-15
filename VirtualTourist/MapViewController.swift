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
	@IBOutlet weak var tapPinstoDelete: UILabel!
	@IBOutlet var tapRecognizer: UITapGestureRecognizer!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Adding editButtonItem() to change editing state.
		// Even though MapView does not have "editing" state the implemantation is cleaner than custom solutions.
		navigationItem.rightBarButtonItem = editButtonItem()
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "OK", style: .Plain, target: nil, action: nil)
		navigationItem.title = "Virtual Tourist"
		
		// Set initial editing mode
		setEditing(false, animated: false)
		
		// Set touch and hold duration
		longPressRecognizer.minimumPressDuration = 1.0
		tapRecognizer.numberOfTapsRequired = 1
		
		mapView.delegate = self
		
		// Restore last saved map region using NSKeyedArchiver/Unarchiever
		restoreMapRegion(false)
		// Perform fetch of CoreData objects
		if fetchPins() {
			mapView.addAnnotations(getAnnotationsFromFetchedResuls())
		}
	}
	
	// MARK: - Actions
	
	@IBAction func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
		// Do not allow to place pins while in edit mode or in wrong gestureRecognizer state.
		if editing { return }
		if gestureRecognizer.state != .Began { return }
		
		let touchPoint = gestureRecognizer.locationInView(mapView)
		let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
		
		// Create dictionary of latitude/longitude to initialize Pin object
		let dictionary = [
			Keys.Latitude: touchMapCoordinate.latitude as NSNumber,
			Keys.Longitude: touchMapCoordinate.longitude as NSNumber
		]
		
		// Pin is conformed to MKAnnotation protocol hence setting it as annotation point
		let annotation = Pin(dictionary: dictionary, context: sharedContext)
		
		mapView.addAnnotation(annotation)
		/*
		// Prefetch photos for location. Task may interfere with Pin Detail View if Pin is placed and tapped in quick succession.
		Queue.UserInitiated.execute { () -> Void in
			FlickrManager.sharedInstance.getFlickrPhotoByLatLon(
				latitude: touchMapCoordinate.latitude as NSNumber,
				longitude: touchMapCoordinate.longitude as NSNumber) { data, error in
					guard let response = data as? [[String : AnyObject]] else {
						print("Photos. \(error)")
						return
					}
					
					let photosDictionary = FlickrManager.sharedInstance.parsePhotosDictionary(response)
					
					photosDictionary.forEach { (dictionary: [String : NSString]) -> () in
						let photo = Photo(dictionary: dictionary, context: self.sharedContext)
						photo.location = annotation
					}
					
					Queue.Main.execute { self.saveContext() }
			}
		}
		*/
	}
	
	@IBAction func handleTap(tapRecognizer: UITapGestureRecognizer) {
		let touchPoint = tapRecognizer.locationInView(mapView)
		// Check if we hit annotation on the map
		guard let view = mapView.hitTest(touchPoint, withEvent: nil) as? MKAnnotationView else {
			// Deselect currently selected annotation if we miss
			if !mapView.selectedAnnotations.isEmpty {
				mapView.deselectAnnotation(mapView.selectedAnnotations.first, animated: true)
			}
			return
		}
		
		guard let annotation = view.annotation else {
			return
		}
		
		// Get Managed Object
		let latitude = annotation.coordinate.latitude as NSNumber
		managedObject = getManagedObject(forKey: latitude)
		guard let pin = managedObject else {
			return
		}
		
		switch editing {
		case true:
			// Delete image files from disk cache
			pin.photos?.forEach { $0.image = nil }
			// Delete Pin Photos
			pin.photos = nil
			// Delete Pin
			sharedContext.deleteObject(pin)
			// Delete annotation from the map
			mapView.removeAnnotation(annotation)
			// Save context
			CoreDataStackManager.sharedInstance.saveContext()
		default:
			// If not in editing mode open Pin Detail View controller
			guard let
				controller = storyboard?.instantiateViewControllerWithIdentifier("PinDetailViewController") as? PinDetailViewController else {
					break
			}
			controller.location = pin
			showViewController(controller, sender: self)
		}
	}
	
	// MARK: - NSKeyedArchiver and CoreData convinience properties
	
	// Initilize managedObject as nil. Will be used in delegate methods
	var managedObject: Pin? = nil
	
	// FilePath property
	var filePath: String? {
		let manager = NSFileManager.defaultManager()
		guard let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL? else {
			return nil
		}
		return url.URLByAppendingPathComponent("mapRegionArchieve").path
	}
	
	// Managed Object Context property
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
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
			managedObjectContext: self.sharedContext,
			sectionNameKeyPath: nil,
			cacheName: nil)
		
		return fetchedResultsController
	}()
	
	
	// MARK: - Helpers
	
	// Switch editing state and show tapPinstoDelete label
	override func setEditing(editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		// Show/hide TapPinstoDelete label according to editing state.
		editing ? (tapPinstoDelete.hidden = false) : (tapPinstoDelete.hidden = true)
		if tapPinstoDelete.hidden {
			mapView.frame.origin.y += tapPinstoDelete.frame.height
		} else {
			mapView.frame.origin.y -= tapPinstoDelete.frame.height
		}
	}
	
	func saveContext() {
		CoreDataStackManager.sharedInstance.saveContext()
	}
	
	// NSKeyedArchiver
	// Save Map Region
	func saveMapRegion() {
		guard let filePath = filePath else {
			return
		}
		// Place the "center" and "span" of the map into a dictionary
		// The "span" is the width and height of the map in degrees.
		// It represents the zoom level of the map.
		let dictionary = [
			Keys.Latitude : mapView.region.center.latitude as NSNumber,
			Keys.Longitude : mapView.region.center.longitude as NSNumber,
			Keys.LatitudeDelta : mapView.region.span.latitudeDelta as NSNumber,
			Keys.LongitudeDelta : mapView.region.span.longitudeDelta as NSNumber
		]
		// Archive the dictionary into the filePath
		NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
	}
	
	// NSKeyedUnarchiver
	// Restore Map Region
	func restoreMapRegion(animated: Bool) {
		// Check filePath
		guard let filePath = filePath else {
			return
		}
		
		// If present, unarchive a dictionary
		guard let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : NSNumber] else {
			return
		}
		
		guard let
			latitude = regionDictionary[Keys.Latitude],
			longitude = regionDictionary[Keys.Longitude],
			latitudeDelta = regionDictionary[Keys.LatitudeDelta],
			longitudeDelta = regionDictionary[Keys.LongitudeDelta] else {
				return
		}
		
		// Create coordinates for restored region
		let center = CLLocationCoordinate2D(latitude: latitude as CLLocationDegrees, longitude: longitude as CLLocationDegrees)
		let span = MKCoordinateSpan(latitudeDelta: latitudeDelta as CLLocationDegrees, longitudeDelta: longitudeDelta as CLLocationDegrees)
		let region = MKCoordinateRegion(center: center, span: span)
		
		// Set map coordinates to restored region
		mapView.setRegion(region, animated: animated)
	}
	
	// Fetch Pins
	func fetchPins() -> Bool {
		do {
			try fetchedResultsController.performFetch()
		} catch {
			return false
		}
		return true
	}
	
	// Get managed object for Key by executing fetch with predicate
	func getManagedObject(forKey latitude: NSNumber) -> Pin? {
		do {
			fetchedResultsController.fetchRequest.fetchLimit = 1
			fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "latitude = %@", latitude)
			try fetchedResultsController.performFetch()
		} catch {
			return nil
		}
		
		guard let fetchedObject = fetchedResultsController.fetchedObjects?.first as? Pin else {
			return nil
		}
		
		return fetchedObject
	}
	
	// Create Annotations Array
	func getAnnotationsFromFetchedResuls() -> [MKPointAnnotation] {
		// Check if we have fetched objects, else return empty array
		guard let locations = fetchedResultsController.fetchedObjects as? [Pin] else {
			return []
		}
		
		// Add annotations to array
		let annotations = locations.map { (location: (Pin)) -> MKPointAnnotation in
			let coordinate = CLLocationCoordinate2D(latitude: location.latitude as CLLocationDegrees, longitude: location.longitude as CLLocationDegrees)
			let annotation = MKPointAnnotation()
			
			annotation.coordinate = coordinate
			
			return annotation
		}
		
		return annotations
	}
}