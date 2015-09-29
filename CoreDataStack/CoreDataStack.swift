//
//  CoreDataStack.swift
//
//  Created by Ben on 28.09.15.
//  Copyright © 2015 Ben. All rights reserved.
//

import CoreData
import Foundation


/**
# CoreDataStack
This class sets up the CoreData stack. It is a simple port of the stack that Marcus Zarra describes in [My Core Data Stack](http://martiancraft.com/blog/2015/03/core-data-stack/).
It is meant to be used via dependency injection and passed from View Controller to View Controller.
*/
class CoreDataStack {

/**
This is the main managed object context to interact with.
Will be nil if the initialization fails.
*/
	let managedObjectContext: NSManagedObjectContext?
/**
This is a private managed object context that is responsible for persisting the data.
It also is the parent context of the main managed object context
Will be nil if the initialization fails.
*/
	private let privateContext: NSManagedObjectContext?
	
/**
The initializer builds the actual CoreData stack with two contexts, the model and a persistent store.
- Parameter modelName: The filename of the CoreData model
- Parameter callback: A callback function that gets called once the CoreData stack in set up

TODO: Proper error handling
*/
	init(modelName: String, callback: () -> ()) {
		/// Looking for the data model url.
		let modelURL = NSBundle.mainBundle().URLForResource(modelName, withExtension: "momd")
		if let modelURL = modelURL {
			/// Creating the actual model object.
			let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL)
			
			if let managedObjectModel = managedObjectModel {
				/// Creating a persistent store coordinator for the private context.
				let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
				
				// Initialising and configuring the managed object contexts.
				self.managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
				self.privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
				self.privateContext?.persistentStoreCoordinator = coordinator
				self.managedObjectContext?.parentContext = self.privateContext

				/// Configure the persistent store on a background queue.
				let priority = DISPATCH_QUEUE_PRIORITY_BACKGROUND
				dispatch_async(dispatch_get_global_queue(priority, 0)) {
					/// Options for the persistent store
					let options = [
						NSMigratePersistentStoresAutomaticallyOption: true,
						NSInferMappingModelAutomaticallyOption: true,
						NSSQLitePragmasOption: ["journal_mode": "DELETE"]
					]
					
					// Get the documents directory and URL for the persisitent store. It will be created if it doesn't exist.
					let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last
					let storeURL = documentsURL?.URLByAppendingPathComponent("\(modelName).sqlite")
					
					// Try to create a persistent store as SQLite storage type.
					do {
						try self.privateContext?.persistentStoreCoordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
					}
					catch let error as NSError {
						NSLog("%@", "Unresolved error \(error), \(error.userInfo)")
						abort()
					}
					
					/// Call the callback function on the main queue.
					dispatch_async(dispatch_get_main_queue()) {
						callback()
					}
				}
			} else {
				print("Error creating the NSManagedObjectModel object")
				
				/// If the model can not be created, initialize both contexts with nil
				self.managedObjectContext = nil
				self.privateContext = nil
			}
		} else {
			print("Error creating the URL of the data model file")
			
			/// If the model url can not be retrieved, initialize both contexts with nil
			self.managedObjectContext = nil
			self.privateContext = nil
		}
	}
	
/**
The save method checks for changes in both contexts, altough there should only be changes in the main managed object context.
It then tries to perform the actual saves on both contexts, while the main context waits for the private context to finish.
	
TODO: Implement proper error handling
*/
	func save() {
		/// If no new data is present, we don't need to save anything
		if (self.privateContext?.hasChanges == false && self.managedObjectContext?.hasChanges == false) {
			return
		}
		
		/// Perform the main context's save synchronously and wait for the private context
		self.managedObjectContext?.performBlockAndWait({ () -> Void in
			do {
				try self.managedObjectContext?.save()
				
				/// Perform the private context's save asynchronously
				self.privateContext?.performBlock({ () -> Void in
					do {
						try self.privateContext?.save()
					} catch let privateError as NSError {
						print("Error saving private context: \(privateError.localizedDescription)")
					}
				})
			} catch let mainError as NSError {
				print("Error saving main context: \(mainError.localizedDescription)")
			}
		})
	}
}
