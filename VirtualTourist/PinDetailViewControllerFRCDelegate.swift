//
//  PinDetailViewControllerFRCDelegate.swift
//  VirtualTourist
//
//  Created by Sergei on 07/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

// Taken from http://stackoverflow.com/questions/20554137/nsfetchedresultscontollerdelegate-for-collectionview

import CoreData

extension PinDetailViewController: NSFetchedResultsControllerDelegate {
	// Add collectionView operations to Operation Block. Execute when all actions are done, from controllerDidChangeContent
	private func addBlockOperations(processingBlock: () -> Void) {
		blockOperations.append(NSBlockOperation(block: processingBlock))
	}
	
	func controllerWillChangeContent(controller: NSFetchedResultsController) {
		// Clear blockOperations array before adding new ones
		blockOperations.removeAll(keepCapacity: false)	}
	
	func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
		switch type {
		case .Insert:
			addBlockOperations { self.collectionView.insertSections(NSIndexSet(index: sectionIndex)) }
		case .Update:
			addBlockOperations { self.collectionView.reloadSections(NSIndexSet(index: sectionIndex)) }
		case .Move:
			// not implemented
			break
		case .Delete:
			addBlockOperations { self.collectionView.deleteSections(NSIndexSet(index: sectionIndex)) }
		}
	}
	
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		switch type {
		case .Insert:
			guard let newIndexPath = newIndexPath else { break }
			addBlockOperations { self.collectionView.insertItemsAtIndexPaths([newIndexPath]) }
		case .Update:
			guard let newIndexPath = newIndexPath else { break }
			addBlockOperations { self.collectionView.reloadItemsAtIndexPaths([newIndexPath]) }
		case .Move:
			guard let indexPath = indexPath, newIndexPath = newIndexPath else { break }
			addBlockOperations { self.collectionView.moveItemAtIndexPath(indexPath, toIndexPath: newIndexPath) }
		case .Delete:
			guard let indexPath = indexPath else { break }
			addBlockOperations { self.collectionView.deleteItemsAtIndexPaths([indexPath]) }
		}
	}
	
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		collectionView.performBatchUpdates({ () -> Void in
			// Execute all operations added to blockOperations array
			self.blockOperations.forEach { $0.start() }
			}, completion: { (finished) -> Void in
				// Clear blockOperations array when all opeartions are finished
				self.blockOperations.removeAll(keepCapacity: false)
		})
	}
}