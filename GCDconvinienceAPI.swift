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
	
	func executeSync(closure: () -> Void) {
		dispatch_sync(queue, closure)
	}
	
	func barrier(closure: () -> Void) {
		dispatch_barrier_async(queue, closure)
	}
	
	func barrierSync(closure: () -> Void) {
		dispatch_barrier_sync(queue, closure)
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

enum MOCQueue: String, ExecutableQueue {
	case WorkingWithMOC = "VirtualTouris.ConcurrentQueue.WorkingWithMOC"
	
	var queue: dispatch_queue_t {
		return dispatch_queue_create(rawValue, DISPATCH_QUEUE_CONCURRENT)
	}
	
}

enum SerialQueue: String, ExecutableQueue {
	case DownLoadImage = "VirtualTourist.SerialQueue.DownLoadImage"
	
	var queue: dispatch_queue_t {
		return dispatch_queue_create(rawValue, DISPATCH_QUEUE_SERIAL)
	}
}