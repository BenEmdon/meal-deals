//
//  QueryTestViewController.swift
//  meal-deals
//
//  Created by Benjamin Emdon on 2017-09-16.
//  Copyright © 2017 branch brunch. All rights reserved.
//

import UIKit
import Firebase

class QueryTestViewController: UIViewController {

	var reference = Database.database().reference()
	var deals = [DataSnapshot]()

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.

		getQuery().observe(.value) { (dataSnapshot, string) in
			self.deals.append(dataSnapshot)
			print(dataSnapshot.description)
		}

		//getQuery().observe(.childChanged, with: { [weak self] (snapshot: DataSnapshot) in
		//	self?.deals.append(snapshot)
		//	print(snapshot.description)
		//})
	}

	func getQuery() -> DatabaseQuery {
		return reference.child("deals").queryLimited(toFirst: 10)
	}
	
}
