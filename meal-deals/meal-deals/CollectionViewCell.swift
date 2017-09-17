//
//  CollectionViewCell.swift
//  meal-deals
//
//  Created by Jacky Chiu on 2017-09-16.
//  Copyright © 2017 branch brunch. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
	var restaurant: Restaurant?
	
	fileprivate let name = UILabel()
	fileprivate let title = UILabel()
	fileprivate let details = UILabel()
	fileprivate let address = UILabel()

	override init(frame: CGRect) {
		super.init(frame: frame)
		backgroundColor = UIColor.white.withAlphaComponent(0.9)
		layer.cornerRadius = 10

		title.font = UIFont.systemFont(ofSize: 20, weight: UIFontWeightHeavy)
		
		let mainView = UIView()
		let stackView = UIStackView()
		let separator = UIView()
		separator.backgroundColor = .black
		
		stackView.axis = .vertical
		stackView.spacing = 5
		stackView.addArrangedSubview(title)
		stackView.addArrangedSubview(separator)
		stackView.addArrangedSubview(details)
		stackView.addArrangedSubview(name)
		stackView.addArrangedSubview(address)
		stackView.translatesAutoresizingMaskIntoConstraints = false

		
		mainView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		mainView.translatesAutoresizingMaskIntoConstraints = false
		
		addSubview(mainView)
		addSubview(stackView)
		
		NSLayoutConstraint.activate([
			mainView.leadingAnchor.constraint(equalTo: leadingAnchor),
			mainView.topAnchor.constraint(equalTo: topAnchor),
			mainView.trailingAnchor.constraint(equalTo: trailingAnchor),
			mainView.bottomAnchor.constraint(equalTo: bottomAnchor),
			
			stackView.leadingAnchor.constraint(equalTo: mainView.layoutMarginsGuide.leadingAnchor),
			stackView.topAnchor.constraint(equalTo: mainView.layoutMarginsGuide.topAnchor),
			stackView.trailingAnchor.constraint(equalTo: mainView.layoutMarginsGuide.trailingAnchor),
			stackView.bottomAnchor.constraint(lessThanOrEqualTo: mainView.layoutMarginsGuide.bottomAnchor),

			separator.heightAnchor.constraint(equalToConstant: 2)
			])

	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func render() {
		if let restaurant = restaurant {
			name.text = restaurant.name
			title.text = restaurant.dealTitle
			details.text = restaurant.dealDescription
			address.text = restaurant.address
		}
	}
	
	override func prepareForReuse() {
		restaurant = nil
		name.text = nil
		title.text = nil
		details.text = nil
		address.text = nil
	}
}
