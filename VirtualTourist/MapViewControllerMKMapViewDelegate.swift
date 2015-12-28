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
		if pinView == nil {
			pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
			pinView?.pinTintColor = .redColor()
			pinView?.animatesDrop = true
			pinView?.canShowCallout = false
			pinView?.draggable = true
		} else {
			pinView?.annotation = annotation
		}
		return pinView
	}
	
	func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {

	}
	
	// MARK: - Save Map Region
	func saveMapRegion() {
		// Place the "center" and "span" of the map into a dictionary
		// The "span" is the width and height of the map in degrees.
		// It represents the zoom level of the map.
		let dictionary = [
			Keys.Latitude: mapView.region.center.latitude,
			Keys.Longitude: mapView.region.center.longitude,
			Keys.LatitudeDelta: mapView.region.span.latitudeDelta,
			Keys.LongitudeDelta: mapView.region.span.longitudeDelta
		]
		guard let filePath = filePath else {
			print("File does not exist")
			return
		}
		// Archive the dictionary into the filePath
		if NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath) {
			print("file saved")
		} else {
			print("file not saved")
		}
	}
}
