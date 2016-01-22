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

extension UIViewController {
	
	func showAlert(message: String, title: String = "") {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
		alertController.addAction(OKAction)
		Queue.Main.execute { self.presentViewController(alertController, animated: true, completion: nil) }
	}
	
}

class MapViewController: UIViewController {
	
	// Pin object property
	lazy var fetchedPin: Pin = {
		return Pin()
	}()
	
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
		
		let connection = FlickrManager.sharedInstance.networkConnectionType(FlickrManager.Keys.HTTPS)
		switch connection {
		case .NONETWORK:
			showAlert("No Internet connection. The functionality of the app will be limited to saved locations")
		case .MOBILE3GNETWORK:
			showAlert("The app will download data from web services. Please switch to WiFi network if possible")
		default:
			break
		}
		
		// Adding editButtonItem() to change editing state.
		// Even though MapView does not have "editing" state the implemantation is cleaner than custom solutions.
		navigationItem.rightBarButtonItem = editButtonItem()
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "OK", style: .Plain, target: nil, action: nil)
		navigationItem.title = "Virtual Tourist"
		
		// Set initial editing mode
		setEditing(false, animated: false)
		
		// Set touch and hold duration
		longPressRecognizer.minimumPressDuration = 0.7
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
		
		// Prefetch photos for location. Task may interfere with Pin Detail View if Pin is placed and tapped in quick succession.
		
		FlickrManager.sharedInstance.getFlickrPhotoByLatLon(
			latitude: touchMapCoordinate.latitude as NSNumber,
			longitude: touchMapCoordinate.longitude as NSNumber) { data, error in
				guard let data = data as? [[String : AnyObject]] else {
					self.showAlert(error!)
					return
				}
				
				defer {
					Queue.Main.execute { self.saveContextAndRefresh() }
				}
				
				let photosDictionary = FlickrManager.sharedInstance.parsePhotosDictionary(data)
				
				for dictionary in photosDictionary {
					let photo = Photo(dictionary: dictionary, context: self.sharedContext)
					photo.location = annotation
				}
		}
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
		
		// Get Pin from Core Data
		let latitude = annotation.coordinate.latitude as NSNumber
		let longitude = annotation.coordinate.longitude as NSNumber
		guard let pin = fetchPin(latitude, longitude: longitude) else {
			return
		}
		
		fetchedPin = pin
		
		switch editing {
		case true:
			deletePin()
			mapView.removeAnnotation(annotation)
			saveContextAndRefresh()
		case false:
			// If not in editing mode open Pin Detail View controller
			guard let
				controller = storyboard?.instantiateViewControllerWithIdentifier("PinDetailViewController") as? PinDetailViewController else {
					break
			}
			controller.pin = fetchedPin
			showViewController(controller, sender: self)
		}
	}
	
	// MARK: - NSKeyedArchiver and CoreData convinience properties
	
	// FilePath property for mapRegionArchieve file
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
		let sortDescriptor = NSSortDescriptor(key: Keys.Latitude, ascending: true)
		// Add a sort descriptor.
		fetchRequest.sortDescriptors = [sortDescriptor]
		
		// Create the Fetched Results Controller
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
			managedObjectContext: self.sharedContext,
			sectionNameKeyPath: nil,
			cacheName: Pin.Keys.CacheName)
		
		return fetchedResultsController
	}()
	
	
	// MARK: - Helpers
	
	// Switch editing state and show tapPinstoDelete label
	override func setEditing(editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		// Show/hide TapPinstoDelete label according to editing state.
		editing ? (tapPinstoDelete.hidden = false) : (tapPinstoDelete.hidden = true)

		// Move mapView up when button appears
		if tapPinstoDelete.hidden {
			mapView.frame.origin.y += tapPinstoDelete.frame.height
		} else {
			mapView.frame.origin.y -= tapPinstoDelete.frame.height
		}
	}
	
	func saveContextAndRefresh() {
		do {
			try CoreDataStackManager.sharedInstance.saveContext()
		} catch let error as NSError {
			self.showAlert(error.localizedDescription)
		}
		
		sharedContext.refreshAllObjects()
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
			lat = regionDictionary[Keys.Latitude] as? CLLocationDegrees,
			lon = regionDictionary[Keys.Longitude] as? CLLocationDegrees,
			latDelta = regionDictionary[Keys.LatitudeDelta] as? CLLocationDegrees,
			lonDelta = regionDictionary[Keys.LongitudeDelta] as? CLLocationDegrees else {
				return
		}
		// Create coordinates for restored region
		let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
		let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
		let region = MKCoordinateRegion(center: center, span: span)
		
		// Set map coordinates to restored region
		mapView.setCenterCoordinate(center, animated: animated)
		mapView.setRegion(region, animated: animated)
	}
	
	// Fetch Pins
	func fetchPins() -> Bool {
		NSFetchedResultsController.deleteCacheWithName(Pin.Keys.CacheName)
		do {
			try fetchedResultsController.performFetch()
		} catch {
			return false
		}
		return true
	}
	
	// Get managed object for Key by executing fetch with predicate
	/**
	Retrieve Pin Object from Core Data. Initialize lazy var fetchedPin: Pin with object. return nil if object not found.
	
	- parameters:
		- latitude: NSNumber
		- longitude: NSNumber
	- returns:
		Pin?
	*/
	func fetchPin(latitude: NSNumber, longitude: NSNumber) -> Pin? {
		do {
			fetchedResultsController.fetchRequest.fetchLimit = 1
			fetchedResultsController.fetchRequest.predicate = NSPredicate(
				format: "(latitude = %@) AND (longitude = %@)", latitude, longitude
			)
			try fetchedResultsController.performFetch()
		} catch {
			return nil
		}
		guard let pin = fetchedResultsController.fetchedObjects?.first as? Pin else {
			return nil
		}
		return pin
	}
	
	/**
	Delete Pin object:
	
	- Delete Pin Photos object
	- Corresponding image binary data should be deleted automatically
	- Delete Pin from Core Data
	*/
	func deletePin() {
		self.sharedContext.deleteObject(fetchedPin)
	}
	
	// Create Annotations Array
	/**
	Create annotations array for mapView
	Use Pin fetched results latitude and longitude to set annotations coordinates
	
	returns:
		[MKPointAnnotation]
	*/
	func getAnnotationsFromFetchedResuls() -> [MKPointAnnotation] {
		// Check if we have fetched objects, else return empty array
		guard let locations = fetchedResultsController.fetchedObjects as? [Pin] else {
			return []
		}
		// Add annotations to array
		let annotations = locations.map { (location: (Pin)) -> MKPointAnnotation in
			let coordinate = CLLocationCoordinate2D(
				latitude: location.latitude as CLLocationDegrees,
				longitude: location.longitude as CLLocationDegrees
			)
			
			let annotation = MKPointAnnotation()
			annotation.coordinate = coordinate
			
			return annotation
		}
		
		return annotations
	}
}