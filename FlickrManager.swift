//
//  FlickrManager.swift
//  VirtualTourist
//
//  Created by Sergei on 30/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import CoreData
import SystemConfiguration

public class FlickrManager {
	
	public typealias completionClosure = (AnyObject?, String?) -> Void
	
	static let sharedInstance = FlickrManager()
	
	var session: NSURLSession
	var sessionConfiguration: NSURLSessionConfiguration
	
	private init() {
		session = NSURLSession.sharedSession()
		sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
	}
	
	public func sendRequest(request: NSMutableURLRequest, handler: completionClosure) {
		let urlSession = NSURLSession(configuration: sessionConfiguration, delegate: nil, delegateQueue: nil)
		let sessionTask = urlSession.dataTaskWithRequest(request) {
			(data, response, error) in
			//print(response)
			guard let data = data else {
				if let error = error {
					return handler(nil, error.localizedDescription)
				} else {
					return handler(nil, "Empty request")
				}
			}
			guard let parsedData = self.parse(fromData: data) else {
				return handler(nil, "Error serializing data")
			}
			handler(parsedData, nil)
		}
		sessionTask.resume()
	}

	
	private func parse(fromData data: NSData) -> AnyObject? {
		var parsedData: AnyObject?
		do {
			parsedData = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
		} catch {
			return nil
		}
		return parsedData
	}
	
	// Taken from http://stackoverflow.com/questions/27148100/how-to-escape-the-http-params-in-swift/27151324#27151324
	private func dictionaryToQueryString(dictionary: [String : AnyObject]) -> String {
		let queryItems = dictionary.map { NSURLQueryItem(name: $0, value: $1 as? String) }
		let components = NSURLComponents()
		components.queryItems = queryItems
		return components.percentEncodedQuery ?? ""
	}
	
	public func prepareRequest(dictionary: [String : String]) -> NSMutableURLRequest? {
		// Mutable dictionary of method arguments
		var methodArguments = [
			MethodArguments.ApiKey : Keys.APIKey,
			MethodArguments.SafeSearch : Keys.SafeSearch,
			MethodArguments.Extras : Keys.Extras,
			MethodArguments.DataFormat : Keys.DataFormat,
			MethodArguments.NoJSONCallback : Keys.NoJSONCallback,
		]
		// add values from dictionary to mutable methodArguments dictionary
		for (key, value) in dictionary {
			methodArguments.updateValue(value, forKey: key)
		}
		let urlString = Keys.HTTPS + "?" + dictionaryToQueryString(methodArguments)
		guard let url = NSURL(string: urlString) else {
			return nil
		}
		return NSMutableURLRequest(URL: url)
	}
	
	// Taken from Mastering Swift 2.0 book - https://www.packtpub.com/application-development/mastering-swift-2
	// TODO: - Implement!
	// Check Network Connection
	public enum ConnectionType {
		case NONETWORK
		case MOBILE3GNETWORK
		case WIFINETWORK
	}
	
	public func networkConnectionType(hostname: NSString) -> ConnectionType {
		let reachabilityRef = SCNetworkReachabilityCreateWithName(nil, hostname.UTF8String)
		var flags = SCNetworkReachabilityFlags()
		SCNetworkReachabilityGetFlags(reachabilityRef!, &flags)
		let reachable: Bool = (flags.rawValue & SCNetworkReachabilityFlags.Reachable.rawValue) != 0
		let needsConnection: Bool = (flags.rawValue & SCNetworkReachabilityFlags.ConnectionRequired.rawValue) != 0
		if reachable && needsConnection {
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