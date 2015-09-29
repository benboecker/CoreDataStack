//
//  ViewController.swift
//  CoreDataStack
//
//  Created by Ben on 29.09.15.
//  Copyright © 2015 Ben. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UITableViewController, NSFetchedResultsControllerDelegate {

	private var coreDataStack: CoreDataStack!
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.coreDataStack = CoreDataStack(modelName: "Example", callback: { () -> () in
			do {
				try self.fetchedResultsController.performFetch()
				self.tableView.reloadData()
			} catch let error as NSError {
				print("Error fetching items: \(error.localizedDescription)")
			}
		})
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let sections = fetchedResultsController.sections {
			let currentSection = sections[section]
			return currentSection.numberOfObjects
		}
		
		return 0
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
		let timestamp = self.fetchedResultsController.objectAtIndexPath(indexPath) as? NSManagedObject
		cell.textLabel?.text = timestamp?.valueForKey("timestamp")?.description
		return cell
	}
	
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
	
	
	@IBAction func addTimestamp(sender: UIBarButtonItem) {
		let timestamp = NSEntityDescription.insertNewObjectForEntityForName("Timestamp", inManagedObjectContext: self.fetchedResultsController.managedObjectContext) as NSManagedObject
		timestamp.setValue(NSDate(), forKey: "timestamp")
		self.coreDataStack.save()
	}
	
}

