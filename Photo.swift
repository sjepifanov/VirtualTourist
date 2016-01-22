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
		static let EntityName = "Photo"
		static let Server = "server"
		static let Farm = "farm"
		static let Id = "id"
		static let Size = "q"
		static let Secret = "secret"
		static let ImageURL = "imageURL"
		static let CacheName = "photoCache"
	}
	
	@NSManaged var farm: NSString?
	@NSManaged var server: NSString?
	@NSManaged var id: NSString?
	@NSManaged var secret: NSString?
	@NSManaged var imageURL: NSString?
	
	@NSManaged var location: Pin
	@NSManaged var image: ImageData?

	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init (dictionary: [String : NSString] , context: NSManagedObjectContext) {
		guard let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) else {
			fatalError("Unable to initialize Photo entity")
		}
		super.init(entity: entity, insertIntoManagedObjectContext: context)
		
		guard let
			newFarm = dictionary[Keys.Farm],
			newServer = dictionary[Keys.Server],
			newId = dictionary[Keys.Id],
			newSecret = dictionary[Keys.Secret] else {
			return
		}
		
		farm = newFarm
		server = newServer
		id = newId
		secret = newSecret
		imageURL = "https://farm\(newFarm).staticflickr.com/\(newServer)/\(newId)_\(newSecret)_\(Keys.Size).jpg"
	}
}