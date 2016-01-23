//
//  FlickrManagerConvinience.swift
//  VirtualTourist
//
//  Created by Sergei on 30/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import Foundation

extension FlickrManager {
	
	/**
	Get Flickr photos by Latitude and Longitude with set minimum upload date abd region accuracy
	
	- parameters:
		- dictionary: [String : AnyObject]
	- returns:
		NSMutableURLRequest?
	*/
	func getFlickrPhotoByLatLon(latitude latitude: NSNumber, longitude: NSNumber, handler: CompletionClosure) {
		let methodArguments = [
			MethodArguments.Method : Keys.Search,
			MethodArguments.MinUploadDat : Keys.Date,
			MethodArguments.Latitude : "\(latitude)",
			MethodArguments.Longitude : "\(longitude)",
			MethodArguments.Accuracy : Keys.AccuracyRegion,
			MethodArguments.ContentType : Keys.ContentType,
			MethodArguments.Sort : Keys.SortBy
		]
		
		guard let request = prepareRequest(methodArguments) else {
			return handler(nil, "Error preparing request")
		}
		
		FlickrManager.sharedInstance.sendRequest(request) { data, error in
			guard let data = data else {
				return handler(nil, error)
			}
			
			guard let photos = data.valueForKeyPath(Keys.Photos + "." + Keys.Photo) as? [[String : AnyObject]] else {
				return handler(nil, "No photos found.")
			}
						
			handler(photos, nil)
		}
	}
	
	/**
	Parse Flickr API response from photo search.
	Map elements to dictionary to initialize Photo object.
	
	- parameters:
		- dictionary [[String : AnyObject]]
	- returns:
		[[String : NSString]]
	*/
	func parsePhotosDictionary(dictionary: [[String : AnyObject]]) -> [[String : NSString]] {
		// Map elements replacing nil with empty Array
		let parsedDictionary = dictionary.map {(object: [String : AnyObject]) -> [String : NSString] in
			guard let
				id = object[Photo.Keys.Id] as? NSString,
				server = object[Photo.Keys.Server] as? NSString,
				secret = object[Photo.Keys.Secret] as? NSString,
				farm = object[Photo.Keys.Farm] as? NSNumber else {
					return [:]
			}
			let photo = [
				Photo.Keys.Farm : "\(farm)" as NSString,
				Photo.Keys.Server : server,
				Photo.Keys.Id : id,
				Photo.Keys.Secret : secret
			]
			return photo }.filter { $0 != [:] } // Filter empty arrays
		
		// In case array is empty after .map{}.filter{}, return empty array
		if parsedDictionary.isEmpty { return [] }
		
		switch parsedDictionary.count {
		case 0...105:
			// Return up to 21 elements of parsedDictionary
			return parsedDictionary.prefix(21).map { $0 }
		
		default:
			var indexSet = Set<Int>()
			// A bit of randomization in search results
			repeat {
				let randomIndex = Int(arc4random_uniform(UInt32(dictionary.count)))
				indexSet.insert(randomIndex)
			} while  indexSet.count < 21
			// Return 21 unique random elements of parsedDictionary
			return indexSet.map { parsedDictionary[$0] }
		}
	}
}