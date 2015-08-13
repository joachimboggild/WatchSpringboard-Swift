//
//  SwiftApp.swift
//  SwiftSpringboard
//
//  Created by Joachim Boggild on 13/08/15.
//  Copyright (c) 2015 Joachim Boggild. All rights reserved.
//

import Foundation

public class SwiftApp : LMApp, PSpringboardItem
{
	public var identifier: String { return super.bundleIdentifier; }
	public var label: String { return super.name; }

	private var _image: UIImage?
	public var image: UIImage {
		get {
			if _image == nil {
				_image = makeRoundImage(icon!);
			}
			
			return _image!;
		}
	}
	
	private func makeRoundImage(img: UIImage) -> UIImage {
		let itemWidth: CGFloat = 120;
		let itemHeight: CGFloat = 120;
		
		let clipPath = UIBezierPath(ovalInRect: CGRectInset(CGRectMake(0, 0, itemWidth, itemHeight), 0.5, 0.5));
		
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(itemWidth, itemHeight), false, UIScreen.mainScreen().scale);
		clipPath.addClip();
		img.drawInRect(CGRectMake(0, 0, itemWidth, itemHeight));
		let renderedImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		return renderedImage;
	}
}