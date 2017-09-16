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

struct Restaurant {
	let address: String
	let name: String
	let id: String
	var dealTitle: String?
	var dealDescription: String?
}

class MainViewController: UIViewController {
	private let mapView = MKMapView()
	private let geocoder = CLGeocoder()
	var reference = Database.database().reference()
	private let locationManager = CLLocationManager()

	var restaurant: [Restaurant] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()

		getQuery().observe(.value) { (dataSnapshot, string) in

			for child in dataSnapshot.children {
				print(child)
			}
		}
		
		// location services
		self.locationManager.requestWhenInUseAuthorization()
		if CLLocationManager.locationServicesEnabled() {
			locationManager.delegate = self
			locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
			locationManager.startUpdatingLocation()
		}
		
		// mapView
		mapView.delegate = self
		mapView.showsUserLocation = true

		// view
		view.addSubview(mapView)
		mapView.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			mapView.topAnchor.constraint(equalTo: view.topAnchor),
			mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			])
	}
	
	func updateLocation(coordinate: CLLocationCoordinate2D) {
		let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 200, 200)
		mapView.setRegion(viewRegion, animated: true)
	}

	func getQuery() -> DatabaseQuery {
		return reference.child("restaurants").queryLimited(toFirst: 10)
	}
}

extension MainViewController: MKMapViewDelegate {
	
}

extension MainViewController: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let coordinate = manager.location?.coordinate else { return }
		updateLocation(coordinate: coordinate)
	}
}
