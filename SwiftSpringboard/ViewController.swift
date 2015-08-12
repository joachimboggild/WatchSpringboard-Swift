//
//  ViewController.swift
//  SwiftSpringboard
//
//  Created by Joachim Boggild on 11/08/15.
//  Copyright (c) 2015 Joachim Boggild. All rights reserved.
//

import UIKit

public class ViewController: UIViewController, UIGestureRecognizerDelegate
{
	// -----------------------------------------------------------------------------------------------
	// MARK:
	// MARK: PRIVATES
	
	private func customView() -> LMViewControllerView {
		return view as! LMViewControllerView;
	}

	private func springboard() -> LMSpringboardView {
		return customView().springboard;
	}
	
	
	// -----------------------------------------------------------------------------------------------
	// MARK:
	// MARK: Notifications
	
	public func LM_didBecomeActive() {
		if !customView().isAppLaunched {
			springboard().centerOnIndex(0, zoomScale: 1, animated: false);
			springboard().doIntroAnimation();
			springboard().alpha = 1;
		}
	}

	public func LM_didEnterBackground() {
		if !customView().isAppLaunched {
			springboard().alpha = 0;
		}
	}
	
	
	
	
	// -----------------------------------------------------------------------------------------------
	// MARK:
	// MARK: UIGestureRecognizerDelegate
	
	public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
		if springboard().zoomScale < springboard().minimumZoomLevelToLaunchApp {
			return false;
		} else {
			return true;
		}
	}

	
	
	// -----------------------------------------------------------------------------------------------
	// MARK:
	// MARK: Input
	
	func LM_respringTapped(sender: AnyObject) {
		if customView().isAppLaunched {
			customView().quitApp();
			UIView.animateWithDuration(0.3) {
				self.setNeedsStatusBarAppearanceUpdate();
			};
		} else {
			UIView.animateWithDuration(0.3, animations: {
				() -> Void in
				self.springboard().alpha = 0;
			}, completion: {
				(completed: Bool) -> Void in
				self.springboard().doIntroAnimation();
				self.springboard().alpha = 1;
			});
		}
	}

	func LM_iconTapped(sender: UITapGestureRecognizer) {
		var item = sender.view
		while item != nil && !(item is LMSpringboardItemView) {
			item = item?.superview;
		}
		
		customView().launchAppItem(item as! LMSpringboardItemView);
		
		UIView.animateWithDuration(0.5) {
			self.setNeedsStatusBarAppearanceUpdate();
		};
	}

	
	
	// -----------------------------------------------------------------------------------------------
	// MARK:
	// MARK: UIViewController
	
	public override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated);
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "LM_didBecomeActive", name: UIApplicationDidBecomeActiveNotification, object: nil);
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "LM_didEnterBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil);
		
		springboard().centerOnIndex(0, zoomScale: springboard().zoomScale, animated: false);
	}
	
	public override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated);
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil);
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil);
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		customView().respringButton.addTarget(self, action: "LM_respringTapped:", forControlEvents: UIControlEvents.TouchUpInside);
		springboard().alpha = 0;
		
		for item in springboard().itemViews as! [LMSpringboardItemView] {
			let tap = UITapGestureRecognizer(target: self, action: "LM_iconTapped:");
			tap.numberOfTapsRequired = 1;
			tap.delegate = self;
			item.addGestureRecognizer(tap);
		}
	}
	
	public override func preferredStatusBarStyle() -> UIStatusBarStyle {
		if isViewLoaded() && customView().isAppLaunched {
			return UIStatusBarStyle.Default
		} else {
			return UIStatusBarStyle.LightContent;
		}
	}
}

