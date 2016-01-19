//
//  Photo.swift
//  VirtualTourist
//
//  Created by Sergei on 23/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Photo: NSManagedObject {
	
	struct Keys {
		static let entityName = "Photo"
		static let farm = "farm"
		static let server = "server"
		static let id = "id"
		static let secret = "secret"
		static let size = "q"
		static let imageURL = "imageURL"

	}
	
	@NSManaged var farm: NSString?
	@NSManaged var server: NSString?
	@NSManaged var id: NSString?
	@NSManaged var secret: NSString?
	@NSManaged var identifier: NSString?
	@NSManaged var imageURL: NSString?
	@NSManaged var location: Pin
	@NSManaged var image: ImageData?

	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init (dictionary: [String : NSString] , context: NSManagedObjectContext) {
		guard let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) else {
			fatalError("Unable to load context")
		}
		super.init(entity: entity, insertIntoManagedObjectContext: context)
		
		guard let
			farm = dictionary[Keys.farm],
			server = dictionary[Keys.server],
			id = dictionary[Keys.id],
			secret = dictionary[Keys.secret] else {
			return
		}
		
		self.farm = farm
		self.server = server
		self.id = id
		self.secret = secret
		self.identifier = "\(id)_\(secret).jpg"
		self.imageURL = "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_\(Keys.size).jpg"
		
	}
	
	
	// Image property with { get set } to retrieve/save files from/to Image Cache
	/*
	var image: UIImage? {
		get {
			return FlickrManager.Caches.imageCache.imageWithIdentifier(identifier as String)
		}
		set {
			FlickrManager.Caches.imageCache.storeImage(newValue, withIdentifier: identifier as String)
		}
	}
	*/
}