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

// Opt out from using separate method to cache image files in memory and on disk
// Instead created new entity for binary data with external storage optin checked in Core Data,
// and create cache for Photo object when initializing FRC
// In case that is agains project rubric, could reinstate image cache with files, though this solution is much cleaner

class ImageData: NSManagedObject {
	
	struct Keys {
		static let Entity = "ImageBinary"
		static let CacheName = "imageBinaryCache"
		static let Id = "id"
	}
	
	@NSManaged var imageData: NSData?
	@NSManaged var imageId: NSString?
	
	@NSManaged var photo: Photo?
	
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	init(data: NSData, context: NSManagedObjectContext) {
		guard let entity = NSEntityDescription.entityForName(Keys.Entity, inManagedObjectContext: context) else {
			fatalError("Unable to initialize ImageBinary entity")
		}
		super.init(entity: entity, insertIntoManagedObjectContext: context)
		guard let data = imageDataJPGRepresentation(data) else {
			return
		}
		imageData = data
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