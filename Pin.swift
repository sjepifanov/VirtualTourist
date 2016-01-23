//
//  Pin.swift
//  VirtualTourist
//
//  Created by Sergei on 23/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Pin: NSManagedObject {
	
	struct Keys {
		static let Latitude = "latitude"
		static let Longitude = "longitude"
		static let CacheName = "pinCache"
	}
	
	@NSManaged var latitude: NSNumber
	@NSManaged var longitude: NSNumber
	
	@NSManaged var photos: [Photo]?
	
	// Initilalize private var innerCoordinates.
	// We will use it in Pin class extension for conformance with MKAnnotation protocol
	private var innerCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init(dictionary: [String : NSNumber], context: NSManagedObjectContext) {
		guard let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) else {
			fatalError("Unable to initialize Pin entity!")
		}
		super.init(entity: entity, insertIntoManagedObjectContext: context)
		guard let
			lat = dictionary[Keys.Latitude],
			lon = dictionary[Keys.Longitude] else {
				return
		}
		
		latitude = lat
		longitude = lon
	}
}

extension Pin: MKAnnotation {
	// Conformance to MKAnnotation protocol
	var coordinate: CLLocationCoordinate2D {
		return innerCoordinate
	}
	
	func setCoordinate(newCoordinate: CLLocationCoordinate2D) {
		innerCoordinate = newCoordinate
	}
}