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
import CenteredCollectionView

struct Restaurant {
	let address: String
	let name: String
	let id: String
	var dealTitle: String?
	var dealDescription: String?
}

class MainViewController: UIViewController {
	// Firebase
	private let reference = Database.database().reference()

	// MapKit
	private let mapView = MKMapView()
	private let geocoder = CLGeocoder()
	private let locationManager = CLLocationManager()

	// CenteredCollectionView
	private let collectionView: UICollectionView
	fileprivate let centeredCollectionViewFlowLayout = CenteredCollectionViewFlowLayout()

	// shared mutable state ¯\_(ツ)_/¯
	fileprivate var followUser = true
	var restaurants: [Restaurant] = []

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		collectionView = UICollectionView(centeredCollectionViewFlowLayout: centeredCollectionViewFlowLayout)

		// fuck storyboards
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		// Firebase
		getQuery().observe(.value) { [weak self] (dataSnapshot, string) in
			guard let strongSelf = self else { return }

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

				strongSelf.restaurants.append(restaurant)
				strongSelf.addAnnotationFor(restaurant: restaurant)
			}
			strongSelf.collectionView.reloadData()
		}
		
		// location services
		self.locationManager.requestWhenInUseAuthorization()
		if CLLocationManager.locationServicesEnabled() {
			locationManager.delegate = self
			locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
			locationManager.startUpdatingLocation()
		}
		
		// MapView
		mapView.delegate = self
		mapView.showsUserLocation = true

		// view
		view.addSubview(mapView)
		mapView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(collectionView)
		collectionView.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			mapView.topAnchor.constraint(equalTo: view.topAnchor),
			mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

			collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
			collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			collectionView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -160)
			])

		// setup CenteredCollectionView
		// implement the delegate and dataSource
		collectionView.delegate = self
		collectionView.dataSource = self
		collectionView.backgroundColor = .clear
		// register collection cells
		collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self))
		// configure CenteredCollectionViewFlowLayout properties
		centeredCollectionViewFlowLayout.itemSize = CGSize(width: view.bounds.width * 0.7, height: 150)
		centeredCollectionViewFlowLayout.minimumLineSpacing = 20
		// get rid of scrolling indicators
		collectionView.showsVerticalScrollIndicator = false
		collectionView.showsHorizontalScrollIndicator = false
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
		var annotationView: MKPinAnnotationView
		if let dequeue = mapView.dequeueReusableAnnotationView(withIdentifier: String(describing: MKPinAnnotationView.self)) as? MKPinAnnotationView {
			annotationView = dequeue
		} else {
			annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: String(describing: MKPinAnnotationView.self))
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

extension MainViewController: UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: UICollectionViewCell.self), for: indexPath)
		cell.backgroundColor = .white
		cell.layer.cornerRadius = 10
		return cell
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return restaurants.count
	}
}

extension MainViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if let currentCenteredPage = centeredCollectionViewFlowLayout.currentCenteredPage,
			currentCenteredPage != indexPath.row {
			centeredCollectionViewFlowLayout.scrollToPage(index: indexPath.row, animated: true)
		}
	}
}
