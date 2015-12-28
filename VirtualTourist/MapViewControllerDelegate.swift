//
//  MapViewControllerDelegate.swift
//  VirtualTourist
//
//  Created by Sergei on 28/12/15.
//  Copyright © 2015 Sergei. All rights reserved.
//

import Foundation
import MapKit

// MARK: - MapViewController extension for MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		saveMapRegion()
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
		// Archive the dictionary into the filePath
		NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
	}
}
