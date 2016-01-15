//
//  FlickrManagerConvinience.swift
//  VirtualTourist
//
//  Created by Sergei on 30/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import Foundation

extension FlickrManager {
	
	func getFlickrPhotoByLatLon(latitude latitude: NSNumber, longitude: NSNumber, handler: CompletionClosure) {
		let methodArguments = [
			MethodArguments.Method : Keys.Search,
			MethodArguments.MinUploadDat : Keys.Date,
			MethodArguments.Latitude : "\(latitude)",
			MethodArguments.Longitude : "\(longitude)",
			MethodArguments.Accuracy : Keys.AccuracyRegion,
			MethodArguments.ContentType : Keys.ContentType,
			"sort" : "interestingness-desc",
			"pages" : "4"
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
	
	func parsePhotosDictionary(dictionary: [[String : AnyObject]]) -> [[String : NSString]] {
		let dictionary = dictionary
			.map {(object: [String : AnyObject]) -> [String : NSString] in
				guard let
					id = object["id"] as? NSString,
					server = object["server"] as? NSString,
					secret = object["secret"] as? NSString,
					farm = object["farm"] as? NSNumber else {
						return [:]
				}
				let dictionary = [
					"farm" : "\(farm)",
					"server" : server,
					"id" : id,
					"secret" : secret
				]
				return dictionary
			}
			.filter { $0 != [:] }
		
		if dictionary.isEmpty { return [] }
		
		var photosDictionary = [[String : NSString]]()
		
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
	
//EOC
}