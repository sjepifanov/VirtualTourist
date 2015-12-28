//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Sergei on 23/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

	// MARK: - Declarations
	
	struct Region {
		static let Latitude = "latitude"
		static let Longitude = "longitude"
		static let LatitudeDelta = "latitudeDelta"
		static let LongitudeDelta = "longitudeDelta"
	}
	
	// Convinient property for File Path
	var filePath: String {
		let manager = NSFileManager.defaultManager()
		guard let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL? else {
			print("Unable to access Documents Directory")
			return ""
		}
		return url.URLByAppendingPathComponent("mapRegionArchieve").path ?? ""
	}
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet var longPressRecognizer: UILongPressGestureRecognizer!
	
	// MARK: - View
	override func viewDidLoad() {
		super.viewDidLoad()
		
		longPressRecognizer.minimumPressDuration = 1.0
		// Assign mapView delegate
		mapView.delegate = self
		
		restoreMapRegion(false)
	}
	
	@IBAction func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
		if gestureRecognizer.state != .Began { return }
		let touchPoint = gestureRecognizer.locationInView(mapView)
		let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)

		let annotation = MKPointAnnotation()

		annotation.coordinate = touchMapCoordinate
		
		mapView.addAnnotation(annotation)
	}
	
	
	// MARK: - Restore Map Region
	func restoreMapRegion(animated: Bool) {
		// TODO: - Remove print statements. Either implement error message or silent return.
		// Unarchive a dictionary,
		guard let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String: AnyObject] else {
			print("Unable to access stored map region")
			return
		}
		// Downcast dictionary elements to correct type
		guard let latitude = regionDictionary[Region.Latitude] as? CLLocationDegrees,
			let longitude = regionDictionary[Region.Longitude] as? CLLocationDegrees,
			let latitudeDelta = regionDictionary[Region.LatitudeDelta] as? CLLocationDegrees,
			let longitudeDelta = regionDictionary[Region.LongitudeDelta] as? CLLocationDegrees else {
				print("Downcast from dictionary coordinates to CLLocationDegrees failed")
				return
		}
		// Create coordinate region for saved region
		let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
		let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
		let savedRegion = MKCoordinateRegion(center: center, span: span)
		
		// Set map coordinates for saved region
		mapView.setRegion(savedRegion, animated: animated)
	}
}