//
//  MainViewController.swift
//  meal-deals
//
//  Created by Jacky Chiu on 2017-09-16.
//  Copyright © 2017 branch brunch. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import CoreLocation

class MainViewController: UIViewController {
	private let mapView = MKMapView()
	private let geocoder = CLGeocoder()
	var reference = Database.database().reference()
	private let locationManager = CLLocationManager()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.locationManager.requestWhenInUseAuthorization()
		
		if CLLocationManager.locationServicesEnabled() {
			locationManager.delegate = self
			locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
			locationManager.startUpdatingLocation()
		}
		
		// mapView setup
		mapView.delegate = self
		mapView.showsUserLocation = true

		// mapView region
		let noLocation = CLLocationCoordinate2D()
		let viewRegion = MKCoordinateRegionMakeWithDistance(noLocation, 10, 10)
		mapView.setRegion(viewRegion, animated: true)

		// view setup
		view.addSubview(mapView)
		mapView.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			mapView.topAnchor.constraint(equalTo: view.topAnchor),
			mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			])
	}

	func getQuery() -> DatabaseQuery {
		return reference.child("deals").queryLimited(toFirst: 10)
	}
}

extension MainViewController: MKMapViewDelegate {
	
}

extension MainViewController: CLLocationManagerDelegate {
	
}
