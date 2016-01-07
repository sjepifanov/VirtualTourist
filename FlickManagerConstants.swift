//
//  FlickManagerConstants.swift
//  VirtualTourist
//
//  Created by Sergei on 30/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import Foundation

extension FlickrManager {
	
	struct Keys {
		static let APIKey = "af0c69e2c479f79fc67156af7f85947e"
		static let HTTPS = "https://api.flickr.com/services/rest/"
		static let MethodSearch = "flickr.photos.search"
		static let MethodPlacesByLatLon = "flickr.places.findByLatLon"
		static let SafeSearch = "1"
		static let Accuracy = "11"
		static let Extras = "url_m"
		static let DataFormat = "json"
		static let NoJSONCallback = "1"
		static let ContentType = "1"
	}
	
	struct MethodArguments {
		static let Method = "method"
		static let ApiKey = "api_key"
		static let SafeSearch = "safe_search"
		static let Accuracy = "accuracy"
		static let Extras = "extras"
		static let DataFormat = "format"
		static let NoJSONCallback = "nojsoncallback"
		static let Latitude = "lat"
		static let Longitude = "lon"
		static let Radius = "radius"
		static let Tags = "tags"
		static let ContentType = "content_type"
	}
	
}