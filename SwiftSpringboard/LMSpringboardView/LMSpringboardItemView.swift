//
//  LMSpringboardItemView.swift
//  SwiftSpringboard
//
//  Created by Joachim Boggild on 11/08/15.
//  Copyright (c) 2015 Joachim Boggild. All rights reserved.
//

import Foundation
import UIKit

public class LMSpringboardItemView: UIView
{
	var icon: UIImageView!
	var label: UILabel!
	var isFolderLike: Bool?
	var bundleIdentifier: String = "";

	private var _visualEffectView: UIView?
	private var _visualEffectMaskView: UIImageView?
	
	let kLMSpringboardItemViewSmallThreshold: CGFloat = 0.75;

	private var _scale: CGFloat
	var scale: CGFloat {
		get {
			return _scale;
		}
		set {
			setScale(scale, animated: false);
		}
	}
	
	init() {
		_scale = 1;
		super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
		label = UILabel();
		label.opaque = false;
		label.backgroundColor = nil;
		label.textColor = UIColor.whiteColor();
		label.font = UIFont.systemFontOfSize(UIFont.smallSystemFontSize());
		addSubview(label);
		
		icon = UIImageView();
		addSubview(icon)
	}

	required public init(coder aDecoder: NSCoder) {
		_scale = 1;
		super.init(coder: aDecoder);
	}
	
	public override init(frame: CGRect) {
		_scale = 1;
		super.init(frame: frame);
	}

	func setScale(scale: CGFloat, animated: Bool) {
		if(_scale != scale) {
			let wasSmallBefore = (_scale < kLMSpringboardItemViewSmallThreshold);
			_scale = scale;
			setNeedsLayout()

			if((_scale < kLMSpringboardItemViewSmallThreshold) != wasSmallBefore)
			{
				if animated {
					UIView.animateWithDuration(0.3) {
						self.layoutIfNeeded();
						if (self._scale < self.kLMSpringboardItemViewSmallThreshold) {
							self.label.alpha = 0;
						} else {
							self.label.alpha = 1;
						};
					}
				}
				else
				{
					if(_scale < kLMSpringboardItemViewSmallThreshold) {
						label.alpha = 0;
					} else {
						label.alpha = 1;
					}
				}
			}
			
		}
	}
	
	func setTitle(title: String) {
		label.text = title;
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		let size = self.bounds.size
	
		icon.center = CGPointMake(size.width*0.5, size.height*0.5);
		icon.bounds = CGRectMake(0, 0, size.width, size.height);
	
		_visualEffectView?.center = icon.center;
		_visualEffectView?.bounds = icon.bounds;
		_visualEffectMaskView?.center = icon.center;
		_visualEffectMaskView?.bounds = icon.bounds;

		label.sizeToFit()
		label.center = CGPointMake(size.width*0.5, size.height+4);
	
		let ascale = 60/size.width;
		icon.transform = CGAffineTransformMakeScale(ascale, ascale);
		_visualEffectView?.transform = icon.transform;
	}
}