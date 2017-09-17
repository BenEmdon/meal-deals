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
	fileprivate var followUser = false
	var restaurants: [Restaurant] = []
	private var geocoderCounter = 1
	private var isExpanded = false
	private var collectionViewBottomConstraint: NSLayoutConstraint!

	// button yo
	let button = UIButton()

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
			}
			for restaurant in strongSelf.restaurants {
				strongSelf.addAnnotationFor(restaurant: restaurant)
			}
			strongSelf.collectionView.reloadData()
			if !strongSelf.restaurants.isEmpty {
				UIView.animate(withDuration: 0.5, animations: { [weak self] in
					self?.button.isHidden = false
				})
			}
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

		button.setImage(#imageLiteral(resourceName: "ChevronUp"), for: .normal)
		button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
		button.backgroundColor = UIColor.white.withAlphaComponent(0.9)
		button.layer.cornerRadius = 10
		button.isHidden = false


		// view
		view.addSubview(mapView)
		mapView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(collectionView)
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(button)
		button.translatesAutoresizingMaskIntoConstraints = false
		collectionViewBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 280)

		NSLayoutConstraint.activate([
			mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			mapView.topAnchor.constraint(equalTo: view.topAnchor),
			mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

			collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			collectionViewBottomConstraint,
			collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			collectionView.heightAnchor.constraint(equalToConstant: 310),

			button.heightAnchor.constraint(equalToConstant: 44),
			button.widthAnchor.constraint(equalTo: button.heightAnchor),
			button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
			button.bottomAnchor.constraint(equalTo: collectionView.topAnchor, constant: -5)
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

	func buttonPressed() {
		button.isEnabled = false
		let animations: () -> ()
		if isExpanded {
			animations = { [weak self] in
				self?.button.transform = CGAffineTransform(rotationAngle: 0)
				self?.collectionViewBottomConstraint.constant = 280
				self?.view.layoutIfNeeded()
			}
			isExpanded = false
		} else {
			animations = { [weak self] in
				self?.button.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
				self?.collectionViewBottomConstraint.constant = -10
				self?.view.layoutIfNeeded()
			}
			isExpanded = true
		}

		UIView.animate(
			withDuration: 0.5,
			animations: animations,
			completion: { [weak self] _ in
				self?.button.isEnabled = true
			}
		)
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
				var region = MKCoordinateRegionMakeWithDistance(coordinate, 200, 200)
				region.center.latitude -= region.span.latitudeDelta * 0.30
				strongSelf.mapView.setRegion(region, animated: true)
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
				} else {
					print("Didn't find anything")
				}
				strongSelf.geocoderCounter -= 1
			})
		}
		geocoderCounter += 1
	}


	func getQuery() -> DatabaseQuery {
		return reference.child("restaurants").queryLimited(toFirst: 10)
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
			followUser,
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
}
