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
		// The Pin is draggable. Here we check for dragging state. When Drag started get managed object for current location
		// When Drag ended update managed object with new coordinates.
		switch newState {
		case .Starting:
			let lat = annotation.coordinate.latitude as NSNumber
			let lon = annotation.coordinate.longitude as NSNumber
			
			guard let pin = fetchPin(lat, longitude: lon) else { break }
			managedPin = pin
			fetchPhotos()
			
		case .Ending:
			let lat = annotation.coordinate.latitude as NSNumber
			let lon = annotation.coordinate.longitude as NSNumber

			// Delete Current Photos and Image files for Pin.
			deletePinPhotos()
			
			managedPin.setValue(lat, forKey: Keys.Latitude)
			managedPin.setValue(lon, forKey: Keys.Longitude)
			
			getFlickrPhotosForPin(managedPin)
			
			saveContextAndRefresh()

		default:
			break
		}
	}
	
	func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
		view.highlighted = true
	}
	
	func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
		view.highlighted = false
	}
}
