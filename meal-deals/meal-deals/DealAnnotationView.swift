//
//  DealAnnotationView.swift
//  meal-deals
//
//  Created by Jacky Chiu on 2017-09-16.
//  Copyright © 2017 branch brunch. All rights reserved.
//

import UIKit
import MapKit

class DealAnnotationView: MKAnnotationView {
	let label = UILabel()
	var dealTitle: String?
	
	override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
		super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
		label.textColor = UIColor.black
		label.textAlignment = .center
		label.numberOfLines = 0
		
		addSubview(label)
	}

	override func sizeThatFits(_ size: CGSize) -> CGSize {
		return label.sizeThatFits(size)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func render() {
		if let title = dealTitle {
			label.text = "\(title)\n📍"
		}
		label.sizeToFit()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		dealTitle = nil
		label.text = nil
	}
}
