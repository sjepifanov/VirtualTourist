//
//  Photo.swift
//  VirtualTourist
//
//  Created by Sergei on 23/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import Foundation
import CoreData

@objc (Photo)

class Photo: NSManagedObject {
	
	struct Keys {
		static let Title = "title"
		static let Path = "imagePath"
		static let Pin = "location"
	}
	
	@NSManaged var title: String
	@NSManaged var imagePath: String
	@NSManaged var location: [Pin]
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init (dictionary: [String:AnyObject], context: NSManagedObjectContext) {
		guard let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) else {
			// TODO: - Handle the error properly!
			print("Unable to load context")
			abort()
		}
		super.init(entity: entity, insertIntoManagedObjectContext: context)
		
		title = dictionary[Keys.Title] as! String
		imagePath = dictionary[Keys.Path] as! String
		location = dictionary[Keys.Pin] as! [Pin]
	}
	
}
