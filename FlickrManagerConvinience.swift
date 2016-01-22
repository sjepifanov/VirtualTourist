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
		let dictionary = dictionary
			.map {(object: [String : AnyObject]) -> [String : NSString] in
			guard let
				id = object[Photo.Keys.Id] as? NSString,
				server = object[Photo.Keys.Server] as? NSString,
				secret = object[Photo.Keys.Secret] as? NSString,
				farm = object[Photo.Keys.Farm] as? NSNumber else {
					return [:]
			}
			let dictionary = [
				Photo.Keys.Farm : "\(farm)",
				Photo.Keys.Server : server,
				Photo.Keys.Id : id,
				Photo.Keys.Secret : secret
			]
			return dictionary }
			.filter { $0 != [:] } // Filter empty arrays
		
		// In case all elements will be empty after .map{}.filter{}, return empty array
		if dictionary.isEmpty { return [] }
		
		var photosDictionary = [[String : NSString]]()
		
		// A bit of randomization in search results in case of large number of photos are returned
		// Return no more than 21 elements from Photos Dictionary to insert in Core Data MOC
		switch dictionary.count {
		case 0...100:
			dictionary
				.prefix(21)
				.forEach { photosDictionary.append($0) }
			
		default:
			var indexSet = Set<Int>()
			repeat {
				let randomIndex = Int(arc4random_uniform(UInt32(dictionary.count)))
				indexSet.insert(randomIndex)
			} while  indexSet.count < 21
			
			for index in indexSet {
				let dictionary = dictionary[index]
				photosDictionary.append(dictionary)
			}
		}
		
		return photosDictionary
	}
}