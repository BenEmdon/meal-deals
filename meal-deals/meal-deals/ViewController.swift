//
//  ViewController.swift
//  meal-deals
//
//  Created by Benjamin Emdon on 2017-09-16.
//  Copyright © 2017 branch brunch. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {

	var reference: DatabaseReference!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	func getQuery() {
		return reference.child("deals").queryLimited(toFirst: 10)
	}

}

