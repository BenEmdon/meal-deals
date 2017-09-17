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
import UserNotifications

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
	var restaurants: [Restaurant] = []
	var annotations: [String: MKAnnotation] = [:]
	private var geocoderCounter = 1
	fileprivate var isExpanded = false
	private var collectionViewBottomConstraint: NSLayoutConstraint!
	fileprivate var followLocation = true
	
	// Notification
	let center = UNUserNotificationCenter.current()
	
	// button yo
	let chevronButton = UIButton()
	let locationButton = UIButton()

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

		getQuery().observe(.childChanged, with: { [weak self] dataSnapshot in
			guard let strongSelf = self else { return }

			guard let restaurantDict = dataSnapshot.value as? Dictionary<String, String> else { return print("CANT BE A DICT") }

			guard
				let address = restaurantDict["address"],
				let name = restaurantDict["name"],
				let id = restaurantDict["id"]
				else { return print("Malformed data 😢") }

			let restaurant = Restaurant(
				address: address,
				name: name,
				id: id,
				dealTitle: restaurantDict["deal_title"],
				dealDescription: restaurantDict["deal_description"]
			)

			// remove
			if let annotation = strongSelf.annotations[restaurant.id] {
				strongSelf.mapView.removeAnnotation(annotation)
			}
			strongSelf.annotations.removeValue(forKey: restaurant.id)
			strongSelf.restaurants = strongSelf.restaurants.filter { $0.id != restaurant.id }

			// add again
			strongSelf.restaurants.append(restaurant)
			strongSelf.addAnnotationFor(restaurant: restaurant)
			strongSelf.notifyFor(restaurant: restaurant)
			strongSelf.collectionView.reloadData()
		})


		getQuery().observe(.childAdded, with: { [weak self] dataSnapshot in
			guard let strongSelf = self else { return }

			guard let restaurantDict = dataSnapshot.value as? Dictionary<String, String> else { return print("CANT BE A DICT") }

				guard
					let address = restaurantDict["address"],
					let name = restaurantDict["name"],
					let id = restaurantDict["id"]
					else { return print("Malformed data 😢") }

				let restaurant = Restaurant(
					address: address,
					name: name,
					id: id,
					dealTitle: restaurantDict["deal_title"],
					dealDescription: restaurantDict["deal_description"]
				)

			strongSelf.restaurants.append(restaurant)
			strongSelf.addAnnotationFor(restaurant: restaurant)
			strongSelf.collectionView.reloadData()
			if !strongSelf.restaurants.isEmpty {
				UIView.animate(withDuration: 0.5, animations: { [weak self] in
					self?.chevronButton.isHidden = false
				})
			}
			}
		)


		getQuery().observe(.childRemoved) { [weak self] (dataSnapshot, string) in
			guard let strongSelf = self else { return }

			var restaurantsToRemove: [Restaurant] = []

			for child in dataSnapshot.children {
				guard
					let snapshot = child as? DataSnapshot,
					snapshot.key == "id"
					else { print("not an 'id' field ¯\\_(ツ)_/¯"); continue }

				guard
					let id = snapshot.value as? String,
					let resteraunt = strongSelf.restaurants.first(where: { $0.id == id })
					else { print("Malformed data 😢 or no matching restaurant"); continue }

					restaurantsToRemove.append(resteraunt)
			}
			for restaurant in restaurantsToRemove {
				if let annotation = strongSelf.annotations[restaurant.id] {
					strongSelf.mapView.removeAnnotation(annotation)
				}
				strongSelf.annotations.removeValue(forKey: restaurant.id)
				strongSelf.restaurants = strongSelf.restaurants.filter { $0.id == restaurant.id }
			}

			strongSelf.collectionView.reloadData()
			if strongSelf.restaurants.isEmpty {
				UIView.animate(withDuration: 0.5, animations: { [weak self] in
					self?.chevronButton.isHidden = true
				})
			}
		}
		
		center.delegate = self
		
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

		chevronButton.setImage(#imageLiteral(resourceName: "ChevronUp"), for: .normal)
		chevronButton.addTarget(self, action: #selector(chevronButtonPressed), for: .touchUpInside)
		chevronButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
		chevronButton.layer.cornerRadius = 10
		chevronButton.isHidden = false

		locationButton.setImage(#imageLiteral(resourceName: "location"), for: .normal)
		locationButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
		locationButton.layer.cornerRadius = 10
		locationButton.addTarget(self, action: #selector(locationButtonPressed), for: .touchUpInside)


		// view
		view.addSubview(mapView)
		mapView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(collectionView)
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(chevronButton)
		chevronButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(locationButton)
		locationButton.translatesAutoresizingMaskIntoConstraints = false
		collectionViewBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 265)

		NSLayoutConstraint.activate([
			mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			mapView.topAnchor.constraint(equalTo: view.topAnchor),
			mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

			collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			collectionViewBottomConstraint,
			collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			collectionView.heightAnchor.constraint(equalToConstant: 310),

			chevronButton.heightAnchor.constraint(equalToConstant: 44),
			chevronButton.widthAnchor.constraint(equalTo: chevronButton.heightAnchor),
			chevronButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
			chevronButton.bottomAnchor.constraint(equalTo: collectionView.topAnchor, constant: -5),

			locationButton.heightAnchor.constraint(equalToConstant: 44),
			locationButton.widthAnchor.constraint(equalTo: locationButton.heightAnchor),
			locationButton.bottomAnchor.constraint(equalTo: chevronButton.bottomAnchor),
			locationButton.trailingAnchor.constraint(equalTo: chevronButton.leadingAnchor, constant: -15)
			])

		// setup CenteredCollectionView
		// implement the delegate and dataSource
		collectionView.delegate = self
		collectionView.dataSource = self
		collectionView.backgroundColor = .clear
		// register collection cells
		collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: String(describing: CollectionViewCell.self))
		// configure CenteredCollectionViewFlowLayout properties
		centeredCollectionViewFlowLayout.itemSize = CGSize(width: view.bounds.width * 0.7, height: 300)
		centeredCollectionViewFlowLayout.minimumLineSpacing = 15
		// get rid of scrolling indicators
		collectionView.showsVerticalScrollIndicator = false
		collectionView.showsHorizontalScrollIndicator = false
	}

	func locationButtonPressed() {
		if followLocation {
			locationButton.setImage(#imageLiteral(resourceName: "locationOff"), for: .normal)
			mapView.userTrackingMode = .none
			followLocation = false
		} else {
			locationButton.setImage(#imageLiteral(resourceName: "location"), for: .normal)
			mapView.userTrackingMode = .follow
			followLocation = true
		}

	}

	func chevronButtonPressed() {
		chevronButton.isEnabled = false
		let animations: () -> ()
		if isExpanded {
			animations = { [weak self] in
				self?.chevronButton.transform = CGAffineTransform(rotationAngle: 0)
				self?.collectionViewBottomConstraint.constant = 265
				self?.view.layoutIfNeeded()
			}
			isExpanded = false
		} else {
			animations = { [weak self] in
				self?.chevronButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
				self?.collectionViewBottomConstraint.constant = -10
				self?.view.layoutIfNeeded()
			}
			isExpanded = true
		}

		UIView.animate(
			withDuration: 0.5,
			animations: animations,
			completion: { [weak self] _ in
				self?.chevronButton.isEnabled = true
				self?.updateRestaurantLocation()
			}
		)
	}
	
	func updateLocation(coordinate: CLLocationCoordinate2D) {
		var region = MKCoordinateRegionMakeWithDistance(coordinate, 400, 400)
		if isExpanded {
			region.center.latitude -= region.span.latitudeDelta * 0.30
		}
		mapView.setRegion(region, animated: true)
	}
	
	func updateRestaurantLocation() {
		guard let page = centeredCollectionViewFlowLayout.currentCenteredPage else { return }
		geocoder.geocodeAddressString(restaurants[page].address, completionHandler: { [weak self] (placemarks, error) in
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
		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500 * geocoderCounter)) { [weak self] in
			self?.geocoder.geocodeAddressString(restaurant.address, completionHandler: { [weak self] (placemarks, error) in
				guard let strongSelf = self else { return }
				if let error = error {
					print(error)
				}

				if let coordinate = placemarks?.first?.location?.coordinate {
					let annotation = MKPointAnnotation()
					annotation.coordinate = coordinate
					annotation.title = restaurant.dealTitle
					strongSelf.mapView.addAnnotation(annotation)
					strongSelf.annotations[restaurant.id] = annotation
				} else {
					print("Didn't find anything for \(restaurant)")
				}
				strongSelf.geocoderCounter -= 1
			})
		}
		geocoderCounter += 1
	}
	
	func notifyFor(restaurant: Restaurant) {
		let content = UNMutableNotificationContent()
		content.title = restaurant.name
		content.body = restaurant.dealTitle ?? "Deal coming soon!"
		content.sound = UNNotificationSound.default()
		
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
		let request = UNNotificationRequest(identifier: restaurant.id, content: content, trigger: trigger)
		center.add(request) { (error) in
			if let error = error {
				print("Notify error for \(restaurant): \(error)")
			}
		}
	}

	func getQuery() -> DatabaseQuery {
		return reference.child("restaurants").queryLimited(toFirst: 250)
	}
}

extension MainViewController: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		if annotation.isMember(of: MKUserLocation.self) { return nil }
		let annotationView: DealAnnotationView
		if let dequeue = mapView.dequeueReusableAnnotationView(withIdentifier: String(describing: DealAnnotationView.self)) as? DealAnnotationView {
			annotationView = dequeue
		} else {
			annotationView = DealAnnotationView(annotation: annotation, reuseIdentifier: String(describing: DealAnnotationView.self))
		}
		
		annotationView.dealTitle = annotation.title!
		annotationView.render()
		annotationView.centerOffset = CGPoint(x: -annotationView.label.bounds.width/2, y: -annotationView.label.bounds.height)
		
		return annotationView
	}
}

extension MainViewController: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard
			!isExpanded,
			followLocation,
			let coordinate = manager.location?.coordinate
		else { return }
		self.updateLocation(coordinate: coordinate)
	}
}

extension MainViewController: UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CollectionViewCell.self), for: indexPath) as! CollectionViewCell
		cell.restaurant = restaurants[indexPath.row]
		cell.render()
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
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		updateRestaurantLocation()
	}
	
	func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
		updateRestaurantLocation()
	}
}

extension MainViewController: UNUserNotificationCenterDelegate {
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		completionHandler(.alert)
	}
}
