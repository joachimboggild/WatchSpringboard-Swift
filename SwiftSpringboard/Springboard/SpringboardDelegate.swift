//
//  SpringboardDelegate.swift
//  SwiftSpringboard
//
//  Created by Joachim Boggild on 13/08/15.
//  Copyright (c) 2015 Joachim Boggild. All rights reserved.
//

import Foundation

@objc public protocol SpringboardDelegate
{
	/** Retrieve the items to display on the springboard */
	optional func springboardGetItems() -> [PSpringboardItem];
	
	/** Method that is invoked when an item is tapped. */
	optional func springboard(springboard: SpringboardViewControllerView, itemWasTapped item: PSpringboardItem);
}