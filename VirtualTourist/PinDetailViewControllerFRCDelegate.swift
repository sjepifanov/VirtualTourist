//
//  PinDetailViewControllerFRCDelegate.swift
//  VirtualTourist
//
//  Created by Sergei on 07/01/16.
//  Copyright © 2016 Sergei. All rights reserved.
//

// Taken from http://stackoverflow.com/questions/20554137/nsfetchedresultscontollerdelegate-for-collectionview thread

import CoreData

extension PinDetailViewController: NSFetchedResultsControllerDelegate {
	
	private func addBlockOperations(processingBlock: () -> Void) {
		blockOperations.append(NSBlockOperation(block: processingBlock))
	}
	
	func controllerWillChangeContent(controller: NSFetchedResultsController) {
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
			addBlockOperations { self.collectionView.insertItemsAtIndexPaths([newIndexPath!]) }
		case .Update:
			addBlockOperations { self.collectionView.reloadItemsAtIndexPaths([newIndexPath!]) }
		case .Move:
			addBlockOperations { self.collectionView.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!) }
		case .Delete:
			addBlockOperations { self.collectionView.deleteItemsAtIndexPaths([indexPath!]) }
		}
	}
	
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		collectionView.performBatchUpdates({ () -> Void in
			for operation in self.blockOperations {
				operation.start()
			}
			}, completion: { (finished) -> Void in
				self.blockOperations.removeAll(keepCapacity: false)
				CoreDataStackManager.sharedInstance.saveContext()
		})
	}
}