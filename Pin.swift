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

@objc (Pin)

class Pin: NSManagedObject {
	
	struct Keys {
		static let Latitude = "latitude"
		static let Longitude = "longitude"
		static let Photo = "photo"
	}
	
	@NSManaged var latitude: CLLocationDegrees
	@NSManaged var longitude: CLLocationDegrees
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
		
		latitude = dictionary[Keys.Latitude] as! CLLocationDegrees
		longitude = dictionary[Keys.Longitude] as! CLLocationDegrees
		photos = dictionary[Keys.Photo] as! [Photo]
		
	}
	
	
}