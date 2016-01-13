//
//  FlickrManagerConvinience.swift
//  VirtualTourist
//
//  Created by Sergei on 30/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import Foundation

extension FlickrManager {
	
	func getFlickrPhotosForLocation(latitude latitude: NSNumber, longitude: NSNumber, handler: CompletionClosure){
		let methodArguments = [
			MethodArguments.Method : Keys.PhotosForLocation,
			MethodArguments.Accuracy : Keys.AccuracyStreet,
			MethodArguments.PerPage : "21",
			MethodArguments.Latitude : String(latitude),
			MethodArguments.Longitude : String(longitude)
		]
		guard let request = FlickrManager.sharedInstance.prepareRequest(methodArguments) else {
			return handler(nil, "Error preparng request")
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
	
	func getFlickrPlaceIdByLatLon(latitude latitude: NSNumber, longitude: NSNumber, handler: CompletionClosure) {
		let methodArguments = [
			MethodArguments.Method : Keys.FindByLatLon,
			MethodArguments.Accuracy : Keys.AccuracyStreet,
			MethodArguments.Latitude : String(latitude),
			MethodArguments.Longitude : String(longitude)
		]
		guard let request = FlickrManager.sharedInstance.prepareRequest(methodArguments) else {
			return handler(nil, "Error preparng request")
		}
		FlickrManager.sharedInstance.sendRequest(request) { data, error in
			guard let data = data else {
				return handler(nil, error)
			}
			guard let place = data.valueForKeyPath(Keys.Places + "." + Keys.Place) as? [[String : AnyObject]] else {
				return handler(nil, "No Places found for location.")
			}
			guard let placeId = place.first?[Keys.PlaceID] as? String else {
				return handler(nil, "No PlaceId found for location.")
			}
			
			handler(placeId, nil)
		}
	}
	
	func getFlickrTagsForPlace(placeId: String, handler: CompletionClosure) {
		let methodArguments = [
			MethodArguments.Method : Keys.TagsForPlace,
			MethodArguments.PlaceID : placeId
		]
		guard let request = FlickrManager.sharedInstance.prepareRequest(methodArguments) else {
			return handler(nil, "Error Preparing request")
		}
		FlickrManager.sharedInstance.sendRequest(request) {data, error in
			guard let data = data else {
				return handler(nil, error)
			}
			guard let tags = data.valueForKeyPath(Keys.Tags + "." + Keys.Tag) as? [[String : AnyObject]] else {
				return handler(nil, "No Tags found for location")
			}
			let regEx = "^[a-zA-Z0-9]*$"
			let plainTags = tags
				.prefix(20) // Get first 20 elements or whole array if less
				.map { $0[Keys.Content] as? String } // create array of tag names
				.filter { $0?.rangeOfString(regEx, options: .RegularExpressionSearch) != nil } // filter out names with non AlphaNumeric characters
				.flatMap { $0 } // unwrap optionals, remove nil values
				.joinWithSeparator(",") // create string of names separated with ","
			
			handler(plainTags, nil)
		}
	}
	
	func getFlickPhotosForTags(tags: String, placeId: String, handler: CompletionClosure) {
		let methodArguments = [
			MethodArguments.Method : Keys.Search,
			MethodArguments.MinUploadDat : Keys.Date,
			MethodArguments.Tags : tags,
			MethodArguments.PlaceID : placeId
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
	
	// MARK: - 	Currently using!!! Remove or coment other methods

	func getFlickPhotosForPlaceId(placeId: String, handler: CompletionClosure) {
		let methodArguments = [
			MethodArguments.Method : Keys.Search,
			MethodArguments.MinUploadDat : Keys.Date,
			MethodArguments.PlaceID : placeId,
			MethodArguments.PerPage : "21",
			"sort" : "interestingness-desc,relevance"
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
	
	func getFlickrPhotoByLatLon(latitude latitude: NSNumber, longitude: NSNumber, handler: CompletionClosure) {
		let methodArguments = [
			MethodArguments.Method : Keys.Search,
			MethodArguments.MinUploadDat : Keys.Date,
			MethodArguments.Latitude : "\(latitude)",
			MethodArguments.Longitude : "\(longitude)",
			MethodArguments.Accuracy : Keys.AccuracyRegion,
			MethodArguments.ContentType : Keys.ContentType,
			MethodArguments.PerPage : "21",
			"sort" : "interestingness-desc,relevance"
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
	
	func getFlickrPhoto(url: NSString, handler: (imageData: NSData?, error: String?) -> Void) {
		let url = NSURL(string: url as String)
		let request = NSMutableURLRequest(URL: url!)
		FlickrManager.sharedInstance.downloadImage(request) {data, error in
			guard let data = data as? NSData else {
				return handler(imageData: nil, error: error)
			}
			handler(imageData: data, error: nil)
		}
	}
	
	
	
	
	
	
//EOC
}