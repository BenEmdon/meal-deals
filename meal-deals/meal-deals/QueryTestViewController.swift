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

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
	}

	func getQuery() -> DatabaseQuery {
		return reference.child("deals").queryLimited(toFirst: 10)
	}
	
}
