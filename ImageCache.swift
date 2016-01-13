//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Sergei on 13/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

import Foundation
import UIKit

class ImageCache {
	
	private var inMemoryCache = NSCache()
	
	func imageWithIdentifier(identifier: String?) -> UIImage? {
		// If the identifier is nil, or empty, return nil
		guard let identifier = identifier where identifier != "",
			let path = pathForIdentifier(identifier) else {
				return nil
		}
		// First try the memory cache
		if let image = inMemoryCache.objectForKey(path) as? UIImage {
			return image
		}
		// Next Try the hard drive
		if let data = NSData(contentsOfFile: path) {
			return UIImage(data: data)
		}
		return nil
	}
	
	// MARK: - Saving images
	
	func storeImage(image: UIImage?, withIdentifier identifier: String?) {
		guard let identifier = identifier where identifier != "",
			let path = pathForIdentifier(identifier) else {
				return
		}
		// If the image is nil, remove images from the cache
		guard let image = image else {
			inMemoryCache.removeObjectForKey(path)
			_ = try? NSFileManager.defaultManager().removeItemAtPath(path)
			return
		}
		// Otherwise, keep the image in memory
		inMemoryCache.setObject(image, forKey: path)
		// And in documents directory
		guard let data = UIImagePNGRepresentation(image) else {
			return
		}
		data.writeToFile(path, atomically: true)
	}
	
	// MARK: - Helper
	
	func pathForIdentifier(identifier: String?) -> String? {
		guard let
			identifier = identifier,
			url = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL? else {
				print("Unable to access Documents Directory")
				return nil
		}
		return url.URLByAppendingPathComponent(identifier).path
	}
}
