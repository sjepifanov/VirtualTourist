//
//  FlickrManagerConvinience.swift
//  VirtualTourist
//
//  Created by Sergei on 30/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import Foundation

extension FlickrManager {
	
	func getFlickrPlaceIdByLatLon(latitude: Double, longitude: Double, handler: completionClosure) {
		let methodArguments = [
			MethodArguments.Method : Keys.MethodPlacesByLatLon,
			MethodArguments.Latitude : String(latitude),
			MethodArguments.Longitude : String(longitude),
			"accuracy" : "16"
		]
		guard let request = FlickrManager.sharedInstance.prepareRequest(methodArguments) else {
			return handler(nil, "Error preparng request")
		}
		FlickrManager.sharedInstance.sendRequest(request) { data, error in
			guard let data = data else {
				return handler(nil, error)
			}
			guard let place = data.valueForKey("places")?.valueForKey("place") as? [[String : AnyObject]] else {
				return handler(nil, "No Places found for location.")
			}
			guard let placeId = place.first?["woeid"] as? String else {
				return handler(nil, "No PlaceId found for location.")
			}
			handler(placeId, nil)
		}
	}
	
	func getFlickrTagsForPlace(placeId: String, handler: completionClosure) {
		let methodArguments = [
			MethodArguments.Method : "flickr.places.tagsForPlace",
			"place_id" : placeId
		]
		guard let request = FlickrManager.sharedInstance.prepareRequest(methodArguments) else {
			return handler(nil, "Error Preparing request")
		}
		FlickrManager.sharedInstance.sendRequest(request) {data, error in
			guard let data = data else {
				return handler(nil, error)
			}
			guard let tags = data.valueForKey("tags")?.valueForKey("tag") as? [[String : AnyObject]] else {
				return handler(nil, "No Tags found for location")
			}
			let regEx = "^[a-zA-Z0-9]*$"
			let plainTags = tags
				.map { $0["_content"] as? String }
				.filter { $0?.rangeOfString(regEx, options: .RegularExpressionSearch) != nil }
				.flatMap { $0 }
			handler(plainTags, nil)
		}
	}
	
	func getFlickPhotosForTags(tags: [String], placeId: String, handler: completionClosure) {
		let tagsString = tags.joinWithSeparator(",")
		print("Tags String: \(tagsString)")
		let methodArguments = [
			MethodArguments.Method : Keys.MethodSearch,
			//"tag_mode" : "any",
			//"tags" : "seened,fungi,imbivahuri,polyporales,torikulaadsed,taelikulised,basidiomycota,taelikulaadsed,onnia,hymenochaetales,hymenochaetaceae,kandseened,phlebia,pess,lehternahkiselised,vammik,vaabikulised,thelephorales,lehternahkis,vaabik",
			"place_id" : placeId,
			"min_upload_date" : "2005-01-01"
		]
		guard let request = prepareRequest(methodArguments) else {
			return handler(nil, "Error preparing request")
		}
		FlickrManager.sharedInstance.sendRequest(request) { data, error in
			guard let data = data else {
				return handler(nil, error)
			}
			guard let photos = data.objectForKey("photos")?.valueForKey("photo") as? [[String : AnyObject]] else {
				return handler(nil, "No photos found.")
			}
			handler(photos, nil)
		}
	}
}
