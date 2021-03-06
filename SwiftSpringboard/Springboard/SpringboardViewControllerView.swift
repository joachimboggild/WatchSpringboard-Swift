//
//  LMViewControllerView.swift
//  SwiftSpringboard
//
//  Created by Joachim Boggild on 11/08/15.
//  Copyright (c) 2015 Joachim Boggild. All rights reserved.
//

import Foundation
import UIKit

public class SpringboardViewControllerView : UIView
{
	public var springboard: SpringboardView!
	public var appView: UIView!
	public var respringButton: UIButton!
	public var isAppLaunched: Bool = false
	
	public var delegate: SpringboardDelegate?
	
	private var _appLaunchMaskView: UIImageView!
	private var _lastLaunchedItem: SpringboardItemView?
	
	private let _ITEM_HEIGHT: CGFloat = 120;
	private let _ITEM_WIDTH: CGFloat = 120;
	
	public required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder);
	}
	
	public func setup() {
		let fullFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
		let resizingOptions = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth;

		setBackgroundWithFrame(fullFrame, withAutoresizingMask: resizingOptions);
		
		springboard = SpringboardView(frame: fullFrame);
		springboard.autoresizingMask = resizingOptions;

		let items = delegate?.springboardGetItems?();
		
		if items != nil {
			let views = makeItemViewsFromItems(items!);
			springboard.itemViews = views;
		}
		
		addSubview(springboard);
		
		appView = UIImageView(image: UIImage(named: "App.png"));
		appView.transform = CGAffineTransformMakeScale(0, 0);
		appView.alpha = 0;
		appView.backgroundColor = UIColor.whiteColor();
		addSubview(appView);

		_appLaunchMaskView = UIImageView(image: UIImage(named: "Icon.png"));

		respringButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton;

		addSubview(respringButton);
	}
	
	private func makeItemViewsFromItems(items: [PSpringboardItem]) -> [SpringboardItemView] {
		var views = [SpringboardItemView]();
		for item in items {
			var view = SpringboardItemView();
			view.item = item;
			view.icon.image = item.image;
			views.append(view);
		}
		
		return views;
	}
	
	public func setContent(content: [SpringboardItemView]) {
		springboard.itemViews = content;
	}
	
	private func setBackgroundWithFrame(frame: CGRect, withAutoresizingMask autoresizingMask: UIViewAutoresizing) {
		var bg = UIImageView(frame: frame);
		bg.image = UIImage(named: "Wallpaper.png")
		bg.contentMode = UIViewContentMode.ScaleAspectFill;
		bg.autoresizingMask = autoresizingMask;
		addSubview(bg);
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews();
	
		var statusFrame = CGRectZero;
		
		if let window = self.window {
			statusFrame = UIApplication.sharedApplication().statusBarFrame;
			statusFrame = window.convertRect(statusFrame, toView: self)

			var insets = springboard.contentInset;
			insets.top = statusFrame.size.height;
			springboard.contentInset = insets;
		}
	
		let size = bounds.size;

		
		appView.bounds = CGRectMake(0, 0, size.width, size.height);
		appView.center = CGPointMake(size.width*0.5, size.height*0.5);
	
		_appLaunchMaskView.center = CGPointMake(size.width*0.5, size.height*0.5+statusFrame.size.height);
	
		respringButton.bounds = CGRectMake(0, 0, _ITEM_WIDTH, _ITEM_HEIGHT);
		respringButton.center = CGPointMake(size.width*0.5, size.height-60*0.5);
	}

	public func launchAppItem(item: SpringboardItemView) {
		if !isAppLaunched {
			isAppLaunched = true;
			_lastLaunchedItem = item;
		}
		
		let pointInSelf = convertPoint(item.icon.center, fromView: item);
		let dx = pointInSelf.x - appView.center.x;
		let dy = pointInSelf.y - appView.center.y;
		
		let appScale = _ITEM_WIDTH * item.scale / min(appView.bounds.size.width, appView.bounds.size.height);

		let xform = CGAffineTransformMakeTranslation(dx, dy);
		let xform2 = CGAffineTransformScale(xform, appScale, appScale)
		appView.transform = xform2;
		appView.alpha = 1;
		appView.maskView = _appLaunchMaskView;
		
		_appLaunchMaskView.transform = CGAffineTransformMakeScale(0.01, 0.01);
		
		let springboardScale = min(self.bounds.size.width, self.bounds.size.height) / (_ITEM_WIDTH * item.scale);
		let maskScale = max(self.bounds.size.width, self.bounds.size.height) / (_ITEM_WIDTH * item.scale) * 1.2 * item.scale;
		
		UIView.animateWithDuration(0.5,
			animations: {
				() -> Void in
				self.appView.transform = CGAffineTransformIdentity;
				self.appView.alpha = 1;
				
				self._appLaunchMaskView.transform = CGAffineTransformMakeScale(maskScale,maskScale);
				
				self.springboard.transform = CGAffineTransformTranslate(CGAffineTransformMakeScale(springboardScale,springboardScale), -dx, -dy);
				self.springboard.alpha = 0;
				},
			completion: {
				(completed) -> Void in
				self.appView.maskView = nil;
				self._appLaunchMaskView.transform = CGAffineTransformIdentity;
				
				self.springboard.transform = CGAffineTransformIdentity;
				self.springboard.alpha = 1;
				let index = self.springboard.indexOfItemClosestToPoint(self.springboard.convertPoint(pointInSelf, fromView:self));
				self.springboard.centerOnIndex(index, zoomScale:self.springboard.zoomScale, animated:false);
				
				self.delegate?.springboard?(self, itemWasTapped: item.item!);
			}
		);
	}
	
	public func quitApp() {
		if isAppLaunched {
			isAppLaunched = false;
			let pointInSelf = convertPoint(_lastLaunchedItem!.icon.center, fromView: _lastLaunchedItem!);
			let dx = pointInSelf.x - appView.center.x;
			let dy = pointInSelf.y - appView.center.y;
			
			let appScale = _ITEM_HEIGHT*_lastLaunchedItem!.scale/min(appView.bounds.size.width, appView.bounds.size.height);
			
			let appTransform = CGAffineTransformScale(CGAffineTransformMakeTranslation(dx, dy), appScale, appScale);
			appView.maskView = _appLaunchMaskView;
			
			let springboardScale = min(self.bounds.size.width,self.bounds.size.height)/(_ITEM_WIDTH * _lastLaunchedItem!.scale);
			springboard.transform = CGAffineTransformTranslate(CGAffineTransformMakeScale(springboardScale,springboardScale), -dx, -dy);
			springboard.alpha = 0;
	
			let maskScale = max(bounds.size.width, bounds.size.height) / (_ITEM_WIDTH*_lastLaunchedItem!.scale)*1.2*_lastLaunchedItem!.scale;
	
			_appLaunchMaskView.transform = CGAffineTransformMakeScale(maskScale,maskScale);
	
			UIView.animateWithDuration(0.5, delay:0, options:UIViewAnimationOptions.CurveEaseInOut, animations: {
					self.appView.alpha = 1;
					self.appView.transform = appTransform;
		
					self._appLaunchMaskView.transform = CGAffineTransformMakeScale(0.01, 0.01);
		
					self.springboard.alpha = 1;
					self.springboard.transform = CGAffineTransformIdentity;
				}, completion: {
					(completed: Bool) -> Void in
					self.appView.alpha = 0;
					self.appView.maskView = nil;
			});
	
			_lastLaunchedItem = nil;
		}
	}
}
