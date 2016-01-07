//
//  Photo.swift
//  VirtualTourist
//
//  Created by Sergei on 23/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import Foundation
import CoreData

class Photo: NSManagedObject {
	
	struct Keys {
		static let imageURL = "imageURL"
	}
	
	@NSManaged var imageURL: NSString
	@NSManaged var location: Pin
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init (dictionary: [String : NSString] , context: NSManagedObjectContext) {
		guard let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) else {
			fatalError("Unable to load context")
		}
		super.init(entity: entity, insertIntoManagedObjectContext: context)
		guard let path = dictionary[Keys.imageURL] else {
			return
		}
		self.imageURL = path
	}
}
