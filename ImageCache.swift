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
	
	// MARK: - Retrieve images from Caches
	
	/**
	Try to retrieve images from Caches. Return nil if not available.
	
	- parameters:
		- identifier: String?
	- returns:
	UIImage?
	*/
	func imageWithIdentifier(identifier: String?) -> UIImage? {
		// If the identifier is nil, or empty, return nil
		guard let
			identifier = identifier,
			path = pathForIdentifier(identifier: identifier) else {
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
	
	/**
	Store downloaded images in memeory cache and on disk.
	Remove images from caches if photo.image is set to nil.
	
	- parameters:
		- image: UIImage?
	- withIdentifier: String?
	*/
	func storeImage(image: UIImage?, withIdentifier identifier: String?) {
		guard let
			identifier = identifier,
			path = pathForIdentifier(identifier: identifier) else {
				return
		}
		
		// If the image is nil, remove images from the cache
		guard let image = image else {
			inMemoryCache.removeObjectForKey(path)
			_ =	try? NSFileManager.defaultManager().removeItemAtPath(path)
			return
		}
		
		// Otherwise, keep the image in memory
		inMemoryCache.setObject(image, forKey: path)
		
		// And in documents directory
		guard let data = UIImageJPEGRepresentation(image, 1.0) else {
			return
		}
		data.writeToFile(path, atomically: true)
	}
	
	// MARK: - Helper
	
	/**
	Return path to local storage using identifier as file name.
	
	- parameters:
		- identifier: String?
	- returns: String?
	*/
	private lazy var pathForIdentifier: (identifier: String?) -> String? = { [unowned self] (identifier: String?) -> String? in
		guard let
			identifier = identifier,
			url = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL? else {
				return nil
		}
		return url.URLByAppendingPathComponent(identifier).path
	}
}