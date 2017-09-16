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
	fileprivate var followUser = true

	var restaurants: [Restaurant] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()

		getQuery().observe(.value) { (dataSnapshot, string) in

			for child in dataSnapshot.children {
				guard
					let snapshot = child as? DataSnapshot,
					let restaurantDict = snapshot.value as? Dictionary<String, String>
					else { continue }

				guard
					let address = restaurantDict["address"],
					let name = restaurantDict["name"],
					let id = restaurantDict["id"]
					else { print("Malformed data 😢"); continue }

				let restaurant = Restaurant(
					address: address,
					name: name,
					id: id,
					dealTitle: restaurantDict["deal_title"],
					dealDescription: restaurantDict["deal_description"]
				)

				self.restaurants.append(restaurant)
				self.addAnnotationFor(restaurant: restaurant)
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
	
	func displayLocationOf(restaurant: Restaurant) {
		geocoder.geocodeAddressString(restaurant.address, completionHandler: { [weak self] (placemarks, error) in
			guard let strongSelf = self else { return }
			if let error = error {
				print(error)
			}
			
			if let coordinate = placemarks?.first?.location?.coordinate {
				strongSelf.updateLocation(coordinate: coordinate)
			}
		})
	}
	
	func addAnnotationFor(restaurant: Restaurant) {
		geocoder.geocodeAddressString(restaurant.address, completionHandler: { [weak self] (placemarks, error) in
			guard let strongSelf = self else { return }
			if let error = error {
				print(error)
			}
			
			if let coordinate = placemarks?.first?.location?.coordinate {
				let annotation = MKPointAnnotation()
				annotation.coordinate = coordinate
				annotation.title = restaurant.dealTitle
				strongSelf.mapView.addAnnotation(annotation)
			}
		})
	}

	func getQuery() -> DatabaseQuery {
		return reference.child("restaurants").queryLimited(toFirst: 10)
	}
}

extension MainViewController: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		var annotationView: MKAnnotationView
		if let view = mapView.dequeueReusableAnnotationView(withIdentifier: String(describing: MKAnnotationView.self)) {
			annotationView = view
		} else {
			annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: String(describing: MKAnnotationView.self))
		}
		
		annotationView.canShowCallout = true
		
		return annotationView
	}
}

extension MainViewController: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard
			followUser,
			let coordinate = manager.location?.coordinate
		else { return }
		self.updateLocation(coordinate: coordinate)
	}
}
