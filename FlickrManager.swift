//
//  FlickrManager.swift
//  VirtualTourist
//
//  Created by Sergei on 30/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import CoreData
import SystemConfiguration

class FlickrManager {
	
	typealias CompletionClosure = (AnyObject?, String?) -> Void
	
	// Initialize FlickrManager shared instance
	static let sharedInstance = FlickrManager()
	
	var session: NSURLSession
	var sessionConfiguration: NSURLSessionConfiguration
	
	private init() {
		session = NSURLSession.sharedSession()
		sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
		sessionConfiguration.timeoutIntervalForRequest = 30
		sessionConfiguration.timeoutIntervalForResource = 120
	}
	
	// MARK: - Tasks
	
	/**
	Send HTTP request to Flickr API
	
	- parameters:
	- request: NSMutableURLRequest
	- handler: (AnyObject?, String?)
	*/
	func sendRequest(request: NSMutableURLRequest, handler: CompletionClosure) {
		let urlSession = NSURLSession(configuration: sessionConfiguration, delegate: nil, delegateQueue: nil)
		
		let sessionTask = urlSession.dataTaskWithRequest(request) { (data, response, error) in
			guard let data = data else {
				if let error = error {
					return handler(nil, error.localizedDescription)
				} else {
					return handler(nil, "No data recieved")
				}
			}
			
			guard let parsedData = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) else {
				return handler(nil, "Error serializing data")
			}
			
			handler(parsedData, nil)
		}
		
		sessionTask.resume()
	}
	
	/**
	Download Image from Flickr
	
	- parameters:
	- url: String
	- handler: (AnyObject?, String?)
	*/
	func downloadImage(url: String, handler: CompletionClosure) -> NSURLSessionTask? {
		guard let url = NSURL(string: url) else {
			return nil
		}
		
		let urlSession = NSURLSession(configuration: sessionConfiguration, delegate: nil, delegateQueue: nil)
		let request = NSMutableURLRequest(URL: url)
		let sessionTask = urlSession.dataTaskWithRequest(request) { (data, response, error) in
			guard let data = data else {
				if let error = error {
					return handler(nil, error.localizedDescription)
				} else {
					return handler(nil, "No data recieved")
				}
			}
			
			handler(data, nil)
		}
		
		sessionTask.resume()
		return sessionTask
	}
	
	// MARK: - Helpers
	
	/**
	Prepare Task Request
	
	- parameters:
		- dictionary: [String : AnyObject]
	- returns:
		NSMutableURLRequest?
	*/
	func prepareRequest(dictionary: [String : String]) -> NSMutableURLRequest? {
		// Mutable dictionary of method arguments
		var methodArguments = [
			MethodArguments.ApiKey : Keys.APIKey,
			MethodArguments.SafeSearch : Keys.SafeSearch,
			MethodArguments.DataFormat : Keys.DataFormat,
			MethodArguments.NoJSONCallback : Keys.NoJSONCallback,
		]
		
		// add values from dictionary to mutable methodArguments dictionary
		dictionary.forEach { methodArguments.updateValue($1, forKey: $0) }

		let urlString = Keys.HTTPS + "?" + dictionaryToQueryString(methodArguments)

		guard let url = NSURL(string: urlString) else {
			return nil
		}
		
		return NSMutableURLRequest(URL: url)
	}
	
	// Taken from http://stackoverflow.com/questions/27148100/how-to-escape-the-http-params-in-swift/27151324#27151324
	/**
	Escape HTTP parameters
	
	- parameters:
		- dictionary: [String : AnyObject]
		- returns:
		String
	*/
	private func dictionaryToQueryString(dictionary: [String : AnyObject]) -> String {
		let queryItems = dictionary.map { NSURLQueryItem(name: $0, value: $1 as? String) }
		let components = NSURLComponents()
		components.queryItems = queryItems
		
		return components.percentEncodedQuery ?? ""
	}
	
	// MARK: - Network Connection Check
	
	// Taken from Mastering Swift 2.0 book - https://www.packtpub.com/application-development/mastering-swift-2
	// Check Network Connection
	enum ConnectionType {
		case NONETWORK
		case MOBILE3GNETWORK
		case WIFINETWORK
	}
	
	func networkConnectionType(hostname: NSString) -> ConnectionType {
		let reachabilityRef = SCNetworkReachabilityCreateWithName(nil, hostname.UTF8String)
		var flags = SCNetworkReachabilityFlags()
		SCNetworkReachabilityGetFlags(reachabilityRef!, &flags)
		let reachable: Bool = (flags.rawValue & SCNetworkReachabilityFlags.Reachable.rawValue) != 0
		let needsConnection: Bool = (flags.rawValue & SCNetworkReachabilityFlags.ConnectionRequired.rawValue) != 0
		if reachable && !needsConnection {
			//what type of connection is available
			let isCellularConnection = (flags.rawValue & SCNetworkReachabilityFlags.IsWWAN.rawValue) != 0
			if isCellularConnection {
				// cellular conection available
				return ConnectionType.MOBILE3GNETWORK
			} else {
				return ConnectionType.WIFINETWORK
			}
		}
		return ConnectionType.NONETWORK // no connection at all
	}
}
