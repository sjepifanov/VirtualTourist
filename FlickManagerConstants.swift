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
		static let Search = "flickr.photos.search"
		static let FindByLatLon = "flickr.places.findByLatLon"
		static let PhotosForLocation = "flickr.photos.geo.photosForLocation"
		static let TagsForPlace = "flickr.places.tagsForPlace"
		static let SafeSearch = "1"
		static let AccuracyRegion = "6"
		static let AccuracyCity = "11"
		static let AccuracyStreet = "16"
		static let Extras = "url_q"
		static let DataFormat = "json"
		static let NoJSONCallback = "1"
		static let ContentType = "1"
		static let Photos = "photos"
		static let Photo = "photo"
		static let Places = "places"
		static let Place = "place"
		static let Tag = "tag"
		static let Tags = "tags"
		static let Content = "_content"
		static let Date = "2010-01-01"
		static let PlaceID = "place_id"
		static let WOE = "woeid"
		static let SortBy = "interestingness-desc,relevance,date-posted-desc"
		static let NumberOfPages = "4"
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
		static let PerPage = "per_page"
		static let Page = "page"
		static let PlaceID = "place_id"
		static let WOE = "woeid"
		static let MinUploadDat = "min_upload_date"
		static let Sort = "sort"
	}
	
}