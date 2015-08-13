//
//  PSpringboardItem.swift
//  SwiftSpringboard
//
//  Created by Joachim Boggild on 13/08/15.
//  Copyright (c) 2015 Joachim Boggild. All rights reserved.
//

import Foundation

/**
This protocol defines the properties that items to be shown in the springboard should contain.
*/
@objc public protocol PSpringboardItem
{
	var identifier: String { get }
	var label: String { get }
	var image: UIImage! { get }
}