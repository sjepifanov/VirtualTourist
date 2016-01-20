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
			MethodArguments.Sort : Keys.SortBy,
			MethodArguments.Page : Keys.NumberOfPages
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
		let dictionary = dictionary.map {(object: [String : AnyObject]) -> [String : NSString] in
			guard let
				id = object[Photo.Keys.id] as? NSString,
				server = object[Photo.Keys.server] as? NSString,
				secret = object[Photo.Keys.secret] as? NSString,
				farm = object[Photo.Keys.farm] as? NSNumber else {
					return [:]
			}
			let dictionary = [
				Photo.Keys.farm : "\(farm)",
				Photo.Keys.server : server,
				Photo.Keys.id : id,
				Photo.Keys.secret : secret
			]
			return dictionary }.filter { $0 != [:] } // Filter empty arrays
		
		// In case all elements will be empty after map.filter, stop execution
		if dictionary.isEmpty { return [] }
		
		var photosDictionary = [[String : NSString]]()
		
		// A bit of randomization in search results in case large number of photos returned
		// Return 21 elements from Photos Dictionary to be displayed in Collection View
		switch dictionary.count {
		case 0...150:
			dictionary
				.prefix(21)
				.forEach { photosDictionary.append($0) }
			
		default:
			var i = 0
			repeat {
				let randomIndex = Int(arc4random_uniform(UInt32(dictionary.count)))
				let dictionary = dictionary[randomIndex]
				photosDictionary.append(dictionary)
				i++
			} while  i < 21
		}
		
		return photosDictionary
	}
}