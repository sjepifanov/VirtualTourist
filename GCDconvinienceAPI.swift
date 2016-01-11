//
//  GCDconvinienceAPI.swift
//  VirtualTourist
//
//  Created by Sergei on 10/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

// Taken from: http://nshipster.com/new-years-2016/
// Credits to Luo Jie: https://github.com/beeth0ven

import Foundation

protocol ExecutableQueue {
	var queue: dispatch_queue_t { get }
}

extension ExecutableQueue {
	func execute(closure: () -> Void) {
		dispatch_async(queue, closure)
	}
}

enum Queue: ExecutableQueue {
	case Main
	case UserInteractive
	case UserInitiated
	case Utility
	case Background
	
	var queue: dispatch_queue_t {
		switch self {
		case .Main:
			return dispatch_get_main_queue()
		case .UserInteractive:
			return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
		case .UserInitiated:
			return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
		case .Utility:
			return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
		case .Background:
			return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
		}
	}
}

enum SerialQueue: String, ExecutableQueue {
	case DownLoadImage = "VirtualTourist.SerialQueue.DownLoadImage"
	//case UpLoadFile = "VirtualTourist.SerialQueue.UpLoadFile"
	
	var queue: dispatch_queue_t {
		return dispatch_queue_create(rawValue, DISPATCH_QUEUE_SERIAL)
	}
}

// MARK: - Example. Downloading something then could be written like this:
/*
Queue.UserInitiated.execute {
	let url = NSURL(string: "http://image.jpg")!
	let data = NSData(contentsOfURL: url)!
	let image = UIImage(data: data)
	
	Queue.Main.execute {
		imageView.image = image
	}
}
*/
