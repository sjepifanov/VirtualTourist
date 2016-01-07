//
//  MapViewControllerMKMapViewDelegate.swift
//  VirtualTourist
//
//  Created by Sergei on 28/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import Foundation
import MapKit

// MARK: - MapViewController extension for MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
	
	// MARK: - Delegates
	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		saveMapRegion()
	}
	
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		// If the annotation is the user location, just return nil.
		if annotation.isKindOfClass(MKUserLocation) { return nil }
		// Try to dequeue an existing pin view first.
		let reuseID = "pin"
		var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseID) as? MKPinAnnotationView
		// If no pin view exist create a new one.
		guard let pin = pinView else {
			pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
			guard let pin = pinView else {
				return nil
			}
			pin.pinTintColor = .redColor()
			pin.animatesDrop = true
			pin.canShowCallout = false
			pin.draggable = true
			return pin
		}
		pin.annotation = annotation
		return pin
	}
	
	func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
		guard let annotation = view.annotation else {
			return
		}
		switch newState {
		case .Starting:
			let latitude = annotation.coordinate.latitude as NSNumber
			managedObject = getManagedObject(forKey: latitude)
		case .Ending:
			guard let pin = managedObject else {
				break
			}
			let latitude = annotation.coordinate.latitude as NSNumber
			let longitude = annotation.coordinate.longitude as NSNumber
			pin.setValue(latitude, forKey: Keys.Latitude)
			pin.setValue(longitude, forKey: Keys.Longitude)
			CoreDataStackManager.sharedInstance.saveContext()
		default:
			break
		}
		
	}
	
	func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
		print("view added")
	}
	
	func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
		print("select annotation")
	}
	
	func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		print("tapped callout")
	}
	
	func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
		print("deselect annotation")
	}
	
	// MARK: - Helpers
	// Save Map Region
	func saveMapRegion() {
		guard let filePath = filePath else {
			return
		}
		// Place the "center" and "span" of the map into a dictionary
		// The "span" is the width and height of the map in degrees.
		// It represents the zoom level of the map.
		let dictionary = [
			Keys.Latitude: mapView.region.center.latitude as NSNumber,
			Keys.Longitude: mapView.region.center.longitude as NSNumber,
			Keys.LatitudeDelta: mapView.region.span.latitudeDelta as NSNumber,
			Keys.LongitudeDelta: mapView.region.span.longitudeDelta as NSNumber
		]
		// Archive the dictionary into the filePath
		NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
	}
	
	// Get managed object for Key by executing fetch with predicate
	func getManagedObject(forKey latitude: NSNumber) -> Pin? {
		do {
			fetchedResultsController.fetchRequest.fetchLimit = 1
			fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "latitude = %@", latitude)
			try fetchedResultsController.performFetch()
		} catch {
			return nil
		}
		guard let fetchedObject = fetchedResultsController.fetchedObjects?.first as? Pin else {
			return nil
		}
		return fetchedObject
	}
}