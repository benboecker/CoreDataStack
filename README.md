# CoreDataStack

This project demonstrates a simple port of the multithreaded CoreData stack by Marcus Zarra ([*My Core Data Stack*](http://martiancraft.com/blog/2015/03/core-data-stack/)). The original was written in *Objective-C* and this is a rather direct port that doesn't take special Swift features into account. I hope to upgrade the stack in the future to be more Swift-like (Using lazy-loaded, computed properties, proper error handling, etc).

## Example Project

This Repo comes with a simple example project that utilises a `NSFetchedResultsController` to populate a table view with timestamp values. It shows how to use the CoreData stack object in a view controller.