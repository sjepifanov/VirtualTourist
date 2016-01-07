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
	
	private func addBlockOperation(processingBlock: () -> Void) {
		blockOperations.append(NSBlockOperation(block: processingBlock))
	}
	
	func controllerWillChangeContent(controller: NSFetchedResultsController) {
		blockOperations.removeAll(keepCapacity: false)	}
	
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		collectionView.performBatchUpdates({ () -> Void in
			for operation in self.blockOperations {
				operation.start()
			}
			}, completion: { (finished) -> Void in
				self.blockOperations.removeAll(keepCapacity: false)
		})
	}
	
	func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
		switch type {
		case .Insert:
			addBlockOperation { self.collectionView.insertSections(NSIndexSet(index: sectionIndex)) }
		case .Update:
			addBlockOperation { self.collectionView.reloadSections(NSIndexSet(index: sectionIndex)) }
		case .Move:
			// not implemented
			break
		case .Delete:
			addBlockOperation { self.collectionView.deleteSections(NSIndexSet(index: sectionIndex)) }
		}
	}
	
	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		switch type {
		case .Insert:
			addBlockOperation { self.collectionView.insertItemsAtIndexPaths([newIndexPath!]) }
		case .Update:
			addBlockOperation { self.collectionView.reloadItemsAtIndexPaths([newIndexPath!]) }
		case .Move:
			addBlockOperation { self.collectionView.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!) }
		case .Delete:
			addBlockOperation { self.collectionView.deleteItemsAtIndexPaths([indexPath!]) }
		}
	}
}