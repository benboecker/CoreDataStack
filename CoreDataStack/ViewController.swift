//
//  ViewController.swift
//  CoreDataStack
//
//  Created by Ben on 29.09.15.
//  Copyright © 2015 Ben. All rights reserved.

import UIKit
import CoreData

/// Using typealiases to structure the view controller
typealias TableViewDataSource = ViewController
typealias FetchedResultsControllerDelegate = ViewController
typealias ViewControllerLifecycle = ViewController
typealias IBActions = ViewController

/**
    ## ViewController
    Simple `UITableViewController` subclass that shows timestamps coming from a fetched results controller.
    Conforms to `NSFetchedResultsControllerDelegate`.
*/
class ViewController: UITableViewController {

    /**
		The CoreDataStack object. It is declared as an implictly unwrapped optional so that we don't need to initialize it in the required init fucntion.
    */
	private var coreDataStack: CoreDataStack!
	
	/**
	The `NSFetchedResultsController` object is created when it is first accessed (lazily). It gets configured with a simple `NSFetchRequest` and the ViewController as its delegate.
	*/
	lazy private var fetchedResultsController: NSFetchedResultsController = {
		let fetchRequest = NSFetchRequest(entityName: "Timestamp")
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
		
		let fetchedResultsController = NSFetchedResultsController(
			fetchRequest: fetchRequest,
			managedObjectContext: self.coreDataStack.managedObjectContext!,
			sectionNameKeyPath: nil,
			cacheName: nil)
		
		fetchedResultsController.delegate = self
		
		return fetchedResultsController
		}()
	
	/**
	The required initializer, just calls super and doesn't do anything else.
	*/
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}

extension ViewControllerLifecycle {
    /**
        Overriding `viewDidLoad()` to set up our CoreData stack.
        The callback fucntion of the stacks's initializer sets up the default state of the user interface.
	*/
	override func viewDidLoad() {
		super.viewDidLoad()
		
		/// Setup the CoreDataStack object
		self.coreDataStack = CoreDataStack(modelName: "Example", callback: { () -> () in
			/// Try to fetch the `fetchedResultsController`s objects and reload the table view if successful
			do {
				try self.fetchedResultsController.performFetch()
				self.tableView.reloadData()
			} catch let error as NSError {
				print("Error fetching items: \(error.localizedDescription)")
			}
		})
	}
}

extension TableViewDataSource {
    /**
        Overriding *numberOfRowsInSection().
        Gets the required section from the fetched results controller and returns the number of rows in it, if found.
		If no section is found, 0 rows are returned.
    */
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let sections = fetchedResultsController.sections {
			let currentSection = sections[section]
			return currentSection.numberOfObjects
		}
		
		return 0
	}
	
    /**
        Overriding `cellForRowAtIndexPath()`. Gets a `NSManagedObject` from the fetched results controller at the specified index path.
        Returns a `UITableViewCell`object with the timestamp's description in the textLabel.
    */
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
		let timestamp = self.fetchedResultsController.objectAtIndexPath(indexPath) as? NSManagedObject
		cell.textLabel?.text = timestamp?.valueForKey("timestamp")?.description
		return cell
	}
}

/**
    This extension defines all `NSFetchedResultsControllerDelegate` functions implemented by the ViewController.
*/
extension FetchedResultsControllerDelegate : NSFetchedResultsControllerDelegate {
	func controllerWillChangeContent(controller: NSFetchedResultsController) {
		self.tableView.beginUpdates()
	}
	
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		if (type == .Insert) {
			self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
		}
	}
	
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		self.tableView.endUpdates()
	}
}

/**
    This extension defines all IBAction functions implemented by the ViewController.
*/
extension IBActions {
	/**
        IBAction function for adding a new timestamp.
        Timestamps get created via a `NSEntityDescription` and saved by the CoreData stack.
        This triggers the fetched results controller to reload the table via via its delegate methods.
        - parameters:
            - sender: The `UIBarButtonItem` object that triggered the IBAction.
	*/
	@IBAction func addTimestamp(sender: UIBarButtonItem) {
		let timestamp = NSEntityDescription.insertNewObjectForEntityForName("Timestamp", inManagedObjectContext: self.fetchedResultsController.managedObjectContext) as NSManagedObject
		timestamp.setValue(NSDate(), forKey: "timestamp")
		self.coreDataStack.save()
	}
}



