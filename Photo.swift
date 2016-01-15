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
		static let imageURL = "imageURL"
		static let farm = "farm"
		static let server = "server"
		static let secret = "secret"
		static let id = "id"
		static let size = "q"
	}
	
	@NSManaged var farm: NSString
	@NSManaged var server: NSString
	@NSManaged var id: NSString
	@NSManaged var secret: NSString
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
		self.imageURL = "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_\(Keys.size).jpg"
	}
	
	var identifier: String {
		return "\(id)_\(secret).jpg"
	}

	var image: UIImage? {
		get {
			return FlickrManager.Caches.imageCache.imageWithIdentifier(identifier)
		}
		set {
			FlickrManager.Caches.imageCache.storeImage(newValue, withIdentifier: identifier)
		}
	}
}