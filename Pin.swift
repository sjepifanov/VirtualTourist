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
	}
	
	@NSManaged var latitude: NSNumber
	@NSManaged var longitude: NSNumber
	@NSManaged var photos: [Photo]
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
		guard let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) else {
			// TODO - Add proper error handling!
			print("Can not initialize Pin entity!")
			abort()
		}
		super.init(entity: entity, insertIntoManagedObjectContext: context)
		latitude = dictionary[Keys.Latitude] as! NSNumber
		longitude = dictionary[Keys.Longitude] as! NSNumber
	}
}


// MARK: Class Pin extension to conform to MKAnnotation protocol

extension Pin: MKAnnotation {
	var coordinate: CLLocationCoordinate2D {
			return CLLocationCoordinate2D(latitude: latitude as CLLocationDegrees, longitude: longitude as CLLocationDegrees)
	}
}