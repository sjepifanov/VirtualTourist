//
//  CoreDataStackManager.swift
//  VirtualTourist
//
//  Created by Sergei on 23/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStackManager {
	// Taken from http://www.cimgf.com/2014/06/08/the-core-data-stack-in-swift/
	
	// MARK: - Shared instance
	static let sharedInstance = CoreDataStackManager()
	private init() {}
	
	// MARK: - CoreData stack
	
	lazy var managedObjectContext: NSManagedObjectContext = {
		// Grab the URL for the model.
		guard let modelURL = NSBundle.mainBundle().URLForResource("VirtualTourist", withExtension: "momd") else {
			// TODO: - Add proper error handling! Or get rid of guard clause.
			fatalError("Model Data File not found")
		}
		
		// Pass that URL into the NSManagedObjectModel.
		guard let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL) else {
			// TODO: - Add proper error handling! Or get rid of guard clause.
			fatalError("Error initializing managedObjectModel from: \(modelURL)")
		}
		
		// Passing in the initialized NSManagedObjectModel to create the NSPersistentStoreCoordinator.
		let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		
		// Grab all of the possible locations for the documents directory and select the last one from the returned array.
		let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
		guard let storeURL = urls.last?.URLByAppendingPathComponent("PinsAndPhotos.sqlite") else {
			fatalError("Error initializing file path from: \(urls)")
		}
		
		// With a location ask the NSPersistentStoreCoordinator to add a store for that location.
		// Call the method addPersistentStoreWithType on the NSPersistentStoreCoordinator and get back either a NSPersistentStore or nothing.
		// If we get nothing back then that is a failure which we check for.
		do {
			var store: NSPersistentStore = try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
		} catch let error as NSError {
			// TODO: - Add proper error handling!
			fatalError("Failed to load store: \(error), \(error.userInfo)")
		}
		
		// Finally after the NSPersistentStore has been created. Create the actual NSManagedObjectContext.
		// Initialize the NSManagedObjectContext, hand it the NSPersistentStoreCoordinator and return.
		var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
		
		return managedObjectContext
	}()
	
	
	// MARK: - CoreData Saving support
	
	func saveContext() {
		if !managedObjectContext.hasChanges { return }
		do {
			try managedObjectContext.save()
		} catch let error as NSError {
			fatalError("Unresolved error \(error), \(error.userInfo)")
		}
	}
}
