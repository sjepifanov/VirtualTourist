//
//  ImageData.swift
//  VirtualTourist
//
//  Created by Sergei on 18/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class ImageData: NSManagedObject {
	
	struct Keys {
		static let Entity = "ImageBinary"
		static let SectionNameKeyPath = "photo.image"
		static let CacheName = "imageBinaryCache"
		static let Identifier = "identifier"
	}
	
	@NSManaged var imageData: NSData?
	@NSManaged var identifier: String
	@NSManaged var photo: Photo
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init(identifier: String, data: NSData, context: NSManagedObjectContext) {
		guard let entity = NSEntityDescription.entityForName(Keys.Entity, inManagedObjectContext: context) else {
			fatalError("Unable to load context")
		}
		super.init(entity: entity, insertIntoManagedObjectContext: context)
		self.identifier = identifier
		guard let data = imageDataJPGRepresentation(data) else {
			return
		}
		self.imageData = data
	}
	
	// MARK: - Helpers
	
	func imageDataJPGRepresentation(imageData: NSData) -> NSData? {
		guard let
			image = UIImage(data: imageData),
			imageJPGRepresentation = UIImageJPEGRepresentation(image, 1.0) else {
				return nil
		}
		return imageJPGRepresentation
	}
}