//
//  SpringboardView.swift
//  SwiftSpringboard
//
//  Created by Joachim Boggild on 11/08/15.
//  Copyright (c) 2015 Joachim Boggild. All rights reserved.
//

import Foundation
import UIKit

public class SpringboardView: UIScrollView, UIScrollViewDelegate
{
	public var minimumZoomLevelToLaunchApp: CGFloat = 0.0
	public var doubleTapGesture: UITapGestureRecognizer!
	
	private var _touchView: UIView!
	private var _contentView: UIView!

	private var _debugRectInContent: UIView!
	private var _debugRectInScroll: UIView!
	
	private let _ITEM_DIAMETER: CGFloat = 120;
	
	// controls how much transform we apply to the views (not used)
	var _transformFactor: CGFloat = 1.0
	
	// a few state variables
	var _lastFocusedViewIndex: Int = 0
	var _zoomScaleCache : CGFloat = 0
	var _minTransform: CGAffineTransform!
	
	// dirty when the view changes width/height
	var _minimumZoomLevelIsDirty = false
	var _contentSizeIsDirty = false
	var _contentSizeUnscaled = CGSizeZero
	var _contentSizeExtra = CGSizeZero
	
	var _centerOnEndDrag = false
	var _centerOnEndDeccel = false
	
	
	
	// -----------------------------------------------------------------------------------------------
	// MARK:
	// MARK: PROPERTIES

	private var _itemViews = [UIView]();
	public var itemViews: [UIView] {
		get {
			return _itemViews;
		}
		
		set (newViews) {
			if (newViews != _itemViews) {
				for view in _itemViews {
					if view.isDescendantOfView(self) {
						view.removeFromSuperview()
					}
				}
				
				_itemViews = newViews;
				for view in _itemViews {
					_contentView.addSubview(view);
				}
				
				LM_setContentSizeIsDirty();
			}
		}
	}

	private var _itemDiameter: CGFloat = 0;
	public var itemDiameter: CGFloat {
		get {
			return _itemDiameter;
		}
		
		set (newValue) {
			if _itemDiameter != newValue {
				_itemDiameter = newValue;
				LM_setContentSizeIsDirty();
			}
			
		}
	}
	
	private var _itemPadding: CGFloat = 0;
	public var itemPadding: CGFloat {
		get {
			return _itemPadding;
		}
		
		set (newValue) {
			if(_itemPadding != newValue)
			{
				_itemPadding = newValue;
				LM_setContentSizeIsDirty();
			}
		}
	}

	private var _minimumItemScaling: CGFloat = 0;
	public var minimumItemScaling: CGFloat {
		get {
			return _minimumItemScaling;
		}
		
		set {
			if _minimumItemScaling != newValue {
				_minimumItemScaling = newValue;
				setNeedsLayout()
			}
		
		}
	}


	
	// -----------------------------------------------------------------------------------------------
	// MARK:
	// MARK: INITIALIZATION

	
	init() {
		super.init(frame: CGRectMake(0, 0, 100, 100));
		LM_initBase();
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame);
		LM_initBase();
	}
	
	public required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder);
		LM_initBase();
	}
	
	
	
	// -----------------------------------------------------------------------------------------------
	// MARK:
	// MARK: SpringboardView
	

	private func showAllContentAnimated(animated: Bool) {
		var contentRectInContentSpace = LM_fullContentRectInContentSpace();
		
		_lastFocusedViewIndex = LM_closestIndexToPointInContent(LM_rectCenter(contentRectInContentSpace));
		
		if animated == true
		{
			UIView.animateWithDuration(0.5, delay: 0, options: .LayoutSubviews | .AllowAnimatedContent | .BeginFromCurrentState | .CurveEaseInOut,
				animations: {
					() -> Void in
					self.zoomToRect(contentRectInContentSpace, animated: false);
					self.layoutIfNeeded();
				},
				completion: nil
			)
		} else {
			zoomToRect(contentRectInContentSpace, animated: false);
		}
	}
	
	public func indexOfItemClosestToPoint(pointInSelf: CGPoint) -> Int {
		return LM_closestIndexToPointInSelf(pointInSelf)
	}
	
	public func centerOnIndex(index: Int, zoomScale: CGFloat, animated: Bool) {
		_lastFocusedViewIndex = index;
		let view = itemViews[Int(index)];
		let centerContentSpace = view.center;
		
		if zoomScale != self.zoomScale {
			var rectInContentSpace = LM_rectWithCenter(centerContentSpace, size: view.bounds.size);
			// this takes the rect in content space
			zoomToRect(rectInContentSpace, animated: animated);
		} else {
			let sizeInSelfSpace = bounds.size
			let centerInSelfSpace = LM_pointInContentToSelf(centerContentSpace)
			let rectInSelfSpace = LM_rectWithCenter(centerInSelfSpace, size: sizeInSelfSpace)
			// this takes the rect in self space
			scrollRectToVisible(rectInSelfSpace, animated: animated)
		}
	}

	public func doIntroAnimation() {
		layoutIfNeeded();
		
		let size = self.bounds.size;
		let minScale: CGFloat = 0.5;
		let centerView = itemViews[_lastFocusedViewIndex];
		let centerViewCenter = centerView.center;
		
		for view in itemViews {
			let viewCenter = view.center;
			view.alpha = 0;
			let dx = (viewCenter.x - centerViewCenter.x);
			let dy = (viewCenter.y - centerViewCenter.y);
			let distance = (dx*dx-dy*dy);
			let factor: CGFloat = max(min(max(size.width, size.height)/distance, 1), 0);
			let scaleFactor = (factor) * 0.8 + 0.2;
			let translateFactor: CGFloat = -0.9;
			view.transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(dx * translateFactor, dy * translateFactor), minScale * scaleFactor, minScale * scaleFactor);
		}
		
		setNeedsLayout();
		
		UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseOut,
			animations: { () -> Void in
				for view in self.itemViews {
					view.alpha = 1;
				}
				self.layoutSubviews();
			}, completion: nil);
	}


	// -----------------------------------------------------------------------------------------------
	// MARK:
	// MARK: INPUT
	
	func LM_didZoomGesture(sender: UITapGestureRecognizer) {
		let maximumZoom: CGFloat = 1;
		
		let positionInSelf = sender.locationInView(self);
		let targetIndex = LM_closestIndexToPointInSelf(positionInSelf);
		
		if zoomScale >= minimumZoomLevelToLaunchApp && zoomScale != minimumZoomScale {
			showAllContentAnimated(true);
		} else {
			UIView.animateWithDuration(0.5) {
				self.centerOnIndex(targetIndex, zoomScale: maximumZoom, animated: false)
				self.layoutIfNeeded();
			};
		}
	}
	
	
	// -----------------------------------------------------------------------------------------------
	// MARK:
	// MARK: Privates
	

	private func LM_initBase() {
		println("initbase")
		
		self.delaysContentTouches = false;
		self.showsHorizontalScrollIndicator = false;
		self.showsVerticalScrollIndicator = false;
		self.alwaysBounceHorizontal = true;
		self.alwaysBounceVertical = true;
		self.bouncesZoom = true;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.delegate = self;
  
//		self.itemDiameter = 68;
		self.itemDiameter = _ITEM_DIAMETER + 8;
		self.itemPadding = 48;
		self.minimumItemScaling = 0.5;
  
		_transformFactor = 1;
		_zoomScaleCache = self.zoomScale;
		minimumZoomLevelToLaunchApp = 0.4;
  
		_touchView = UIView();
//		_touchView.backgroundColor = UIColor.purpleColor();
		addSubview(_touchView);
  
		_contentView = UIView();
		//_contentView.backgroundColor = UIColor.greenColor();
		addSubview(_contentView)
  
  /*_debugRectInContent = [[UIView alloc] init];
  _debugRectInContent.backgroundColor = [UIColor redColor];
  _debugRectInContent.alpha = 0.4;
  [_contentView addSubview:_debugRectInContent];
  _debugRectInScroll = [[UIView alloc] init];
  _debugRectInScroll.backgroundColor = [UIColor blueColor];
  _debugRectInScroll.alpha= 0.4;
  [self addSubview:_debugRectInScroll];*/
  
		doubleTapGesture = UITapGestureRecognizer(target: self, action: "LM_didZoomGesture:");
		doubleTapGesture.numberOfTapsRequired = 1;
		_contentView.addGestureRecognizer(doubleTapGesture);
	}
	
	private func LM_pointInSelfToContent(point: CGPoint) -> CGPoint {
		return CGPointMake(point.x/zoomScale, point.y/zoomScale);
	}
	
	private func LM_pointInContentToSelf(point: CGPoint) -> CGPoint {
		return CGPointMake(point.x * zoomScale, point.y * zoomScale);
	}
	
	private func LM_sizeInSelfToContent(size: CGSize) -> CGSize {
		return CGSizeMake(size.width/zoomScale, size.height/zoomScale);
	}
	
	private func LM_sizeInContentToSelf(size: CGSize) -> CGSize {
		return CGSizeMake(size.width*zoomScale, size.height*zoomScale);
	}
	
	private func LM_rectCenter(rect: CGRect) -> CGPoint {
		return CGPointMake(rect.origin.x+rect.size.width*0.5, rect.origin.y+rect.size.height*0.5);
	}
	
	private func LM_rectWithCenter(center: CGPoint, size: CGSize) -> CGRect {
		return CGRectMake(center.x-size.width*0.5, center.y-size.height*0.5, size.width, size.height);
	}
	
	private func LM_transformView(view: SpringboardItemView) {
		// TODO: refactor to make functions use converter and helper functions
		let size = bounds.size;
		let zoomScale = _zoomScaleCache;
		let insets = contentInset;

		var frame = convertRect(CGRectMake(view.center.x - itemDiameter/2, view.center.y - itemDiameter/2, itemDiameter, itemDiameter), fromView: view.superview);

		frame.origin.x -= contentOffset.x;
		frame.origin.y -= contentOffset.y;

		let center = CGPointMake(frame.origin.x+frame.size.width/2, frame.origin.y+frame.size.height/2);
		let padding = itemPadding*zoomScale*0.4;
		var	distanceToBorder: CGFloat = size.width;
		var xOffset: CGFloat = 0;
		var yOffset: CGFloat = 0;

		let distanceToBeOffset = itemDiameter * zoomScale * (min(size.width, size.height)/320);

		let leftDistance: CGFloat = center.x - padding - insets.left;
		if leftDistance < distanceToBeOffset {
			if leftDistance < distanceToBorder {
				distanceToBorder = leftDistance;
			}
			xOffset = 1 - leftDistance / distanceToBeOffset;
		}
		
		let topDistance: CGFloat = center.y - padding - insets.top;
		if topDistance < distanceToBeOffset {
			if topDistance < distanceToBorder {
				distanceToBorder = topDistance;
			}
			yOffset = 1 - topDistance / distanceToBeOffset;
		}
		
		let rightDistance: CGFloat = size.width - padding - center.x - insets.right;
		if rightDistance < distanceToBeOffset {
			if rightDistance < distanceToBorder {
				distanceToBorder = rightDistance;
			}
			xOffset = -(1 - rightDistance / distanceToBeOffset);
		}
		
		let bottomDistance: CGFloat = size.height - padding - center.y - insets.bottom;
		if bottomDistance < distanceToBeOffset {
			if bottomDistance < distanceToBorder {
				distanceToBorder = bottomDistance;
			}
			yOffset = -(1 - bottomDistance / distanceToBeOffset);
		}
		
		distanceToBorder *= 2;
		var usedScale: CGFloat;
		if distanceToBorder < distanceToBeOffset * 2{
			if distanceToBorder < CGFloat(-(Int(itemDiameter*2.5))) {
				view.transform = _minTransform;
				usedScale = minimumItemScaling * zoomScale
			} else {
				var rawScale = max(distanceToBorder / (distanceToBeOffset * 2), 0);
				rawScale = min(rawScale, 1);
				rawScale = 1-pow(1-rawScale, 2);
				var scale: CGFloat = rawScale * (1 - minimumItemScaling) + minimumItemScaling;

				xOffset = frame.size.width*0.8*(1-rawScale)*xOffset;
				yOffset = frame.size.width*0.5*(1-rawScale)*yOffset;

				var translationModifier: CGFloat = min(distanceToBorder/_itemDiameter+2.5, 1);

				scale = max(min(scale * _transformFactor + (1 - _transformFactor), 1), 0);
				translationModifier = min(translationModifier * _transformFactor, 1);
				view.transform = CGAffineTransformTranslate(CGAffineTransformMakeScale(scale, scale), xOffset * translationModifier, yOffset * translationModifier);
				
				usedScale = scale * zoomScale;
			}
		} else {
			view.transform = CGAffineTransformIdentity;
			usedScale = zoomScale;
		}
		
		if dragging || zooming {
			view.setScale(usedScale, animated: true);
		} else {
			view.scale = usedScale;
		}
	}
	
	private func LM_setContentSizeIsDirty() {
		_contentSizeIsDirty = true;
		LM_setMinimumZoomLevelIsDirty();
	}
	
	private func LM_setMinimumZoomLevelIsDirty() {
		_minimumZoomLevelIsDirty = true;
		_contentSizeIsDirty = true;
		setNeedsLayout();
	}

	private func LM_closestIndexToPointInSelf(pointInSelf: CGPoint) -> Int {
		let pointInContent = LM_pointInSelfToContent(pointInSelf);
		return LM_closestIndexToPointInContent(pointInContent);
	}
	
	private func LM_closestIndexToPointInContent(pointInContent: CGPoint) -> Int {
		var hasItem = false;
		var distance: CGFloat = 0;
		var index = _lastFocusedViewIndex;
		var i = 0;
		for potentialView in itemViews {
			let center = potentialView.center;
			let potentialDistance = LMPointDistance(x1: center.x, y1: center.y, x2: pointInContent.x, y2: pointInContent.y);
			
			if potentialDistance < distance || !hasItem {
				hasItem = true;
				distance = potentialDistance;
				index = i;
			}
			i++;
		}
		
		return index;
	}
	
	private func LM_centerOnClosestToScreenCenterAnimated(animated: Bool) {
		let sizeInSelf = self.bounds.size;
		let centerInSelf = CGPointMake(sizeInSelf.width*0.5, sizeInSelf.height*0.5);
		let closestIndex = LM_closestIndexToPointInSelf(centerInSelf);
		centerOnIndex(closestIndex, zoomScale:self.zoomScale, animated:animated);
	}
	
	private func LM_fullContentRectInContentSpace() -> CGRect {
		let rect = CGRectMake(_contentSizeExtra.width*0.5,
			_contentSizeExtra.height*0.5,
			_contentSizeUnscaled.width-_contentSizeExtra.width,
			_contentSizeUnscaled.height-_contentSizeExtra.height);
		//_debugRectInContent.frame = rect;
  
		return rect;
	}
	
	private func LM_insetRectInSelf() -> CGRect {
		let insets = self.contentInset;
		let size = self.bounds.size;
		return CGRectMake(insets.left, insets.top, size.width-insets.left-insets.right, size.height-insets.top-insets.bottom);
	}
	
	private func LM_centerViewIfSmaller() {
		/*CGRect frameToCenter = _contentView.frame;
  
  CGRect rect = [self LM_insetRect];
  // center horizontally
  if (frameToCenter.size.width < rect.size.width)
		frameToCenter.origin.x = (rect.size.width - frameToCenter.size.width) / 2;
  else
		frameToCenter.origin.x = 0;
  
  // center vertically
  if (frameToCenter.size.height < rect.size.height)
		frameToCenter.origin.y = (rect.size.height - frameToCenter.size.height) / 2;
  else
		frameToCenter.origin.y = 0;
  
  _contentView.frame = frameToCenter;*/

	}
	
	private func LMPointDistance(#x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat) ->  CGFloat {
		let temp = LKPointDistanceSquared(x1: x1, y1: y1, x2: x2, y2: y2);
		let d: Double = Double(temp);
		let sq = sqrt(d);
		return CGFloat(sq);
	}
	
	private func LKPointDistanceSquared(#x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat) -> CGFloat {
		return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
	}

	
	// -----------------------------------------------------------------------------------------------
	// MARK:
	// MARK: UIScrollViewDelegate
	
	public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		// TODO: refactor to make functions use converter and helper functions
		let size = self.bounds.size;
  
		// targetContentOffset is in coordinates relative to self;
		var targContOff: CGPoint = targetContentOffset.memory;
  
		// putting proposedTargetCenter in coordinates relative to _contentView
		var proposedTargetCenter = CGPointMake(targContOff.x+size.width/2, targContOff.y+size.height/2);
		proposedTargetCenter.x /= zoomScale;
		proposedTargetCenter.y /= zoomScale;
		//_debugRectInContent.frame = CGRectMake(proposedTargetCenter.x-40, proposedTargetCenter.y-40, 80, 80);
  
		// finding out the idealTargetCenter in coordinates relative to _contentView
		_lastFocusedViewIndex = LM_closestIndexToPointInContent(proposedTargetCenter);
		let view = itemViews[_lastFocusedViewIndex];
		let idealTargetCenter = view.center;
		//_debugRectInContent.frame = CGRectMake(idealTargetCenter.x-40, idealTargetCenter.y-40, 80, 80);
		
		// finding out the idealTargetOffset in coordinates relative to _contentView
		let idealTargetOffset = CGPointMake(idealTargetCenter.x-size.width/2/zoomScale, idealTargetCenter.y-size.height/2/zoomScale);
		//_debugRectInContent.frame = CGRectMake(idealTargetOffset.x-40, idealTargetOffset.y-40, 80, 80);
  
		// finding out the correctedTargetOffset in coordinates relative to self
		let correctedTargetOffset = CGPointMake(idealTargetOffset.x*zoomScale, idealTargetOffset.y*zoomScale);
		//_debugRectInScroll.frame = CGRectMake(correctedTargetOffset.x-40, correctedTargetOffset.y-40, 80, 80);
  
		// finding out currentCenter in coordinates relative to _contentView;
		var currentCenter = CGPointMake(self.contentOffset.x+size.width/2, self.contentOffset.y+size.height/2);
		currentCenter.x /= zoomScale;
		currentCenter.y /= zoomScale;
		//_debugRectInContent.frame = CGRectMake(currentCenter.x-40, currentCenter.y-40, 80, 80);
  
		// finding out the frame of actual icons in relation to _contentView
		var contentCenter = _contentView.center;
		contentCenter.x /= zoomScale;
		contentCenter.y /= zoomScale;
		let contentSizeNoExtras = CGSizeMake(_contentSizeUnscaled.width-_contentSizeExtra.width, _contentSizeUnscaled.height-_contentSizeExtra.height);
		let contentFrame = CGRectMake(contentCenter.x-contentSizeNoExtras.width*0.5, contentCenter.y-contentSizeNoExtras.height*0.5, contentSizeNoExtras.width, contentSizeNoExtras.height);
		//_debugRectInContent.frame = contentFrame;
  
		if !CGRectContainsPoint(contentFrame, proposedTargetCenter)
		{
			// we're going to end outside
			if !CGRectContainsPoint(contentFrame, currentCenter)
			{
				// we're already outside. stop roll and snap back on end drag
				targContOff = self.contentOffset;
				_centerOnEndDrag = true;
				return;
			}
			else
			{
				// we're still in, ending out. Wait for the animation to end, THEN snap back.
				let ourPriority: CGFloat = 0.8;
				targContOff = CGPointMake(
					targContOff.x*(1-ourPriority)+correctedTargetOffset.x*ourPriority,
					targContOff.y*(1-ourPriority)+correctedTargetOffset.y*ourPriority
				);
				_centerOnEndDeccel = true;
				return;
			}
		}
		// we're going to end in. snap to closest icon
		targContOff = correctedTargetOffset;
		targetContentOffset.memory = targContOff;
	}

	public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if _centerOnEndDrag {
			_centerOnEndDrag = false;
			centerOnIndex(_lastFocusedViewIndex, zoomScale: zoomScale, animated: true);
		}
	}
	
	public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		if _centerOnEndDeccel
		{
			_centerOnEndDeccel = false;
			centerOnIndex(_lastFocusedViewIndex, zoomScale:self.zoomScale, animated:true);
		}
	}
	
	public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
		return _contentView;
	}
	
	public func scrollViewDidZoom(scrollView: UIScrollView) {
		_zoomScaleCache = zoomScale;
		LM_centerViewIfSmaller();
	}
	
	
	// -----------------------------------------------------------------------------------------------
	// MARK:
	// MARK: UIView
	

	public override func layoutSubviews() {
		super.layoutSubviews();
		
		let size = self.bounds.size;
		let insets = self.contentInset;

		let minSide = min(size.width, size.height)
		let maxSide = max(size.width, size.height)
		let sq = sqrt(CGFloat(itemViews.count));
		var itemsPerLine = ceil(minSide / maxSide * sq);

		if itemsPerLine % 2 == 0 {
			itemsPerLine++;
		}
		
		let lines = Int(ceil(Double(itemViews.count)/Double(itemsPerLine)));
		var newMinimumZoomScale:CGFloat = 0;
		if _contentSizeIsDirty
		{
			let padding = itemPadding;
			let sizeWidth = itemsPerLine*itemDiameter+(itemsPerLine+1)*padding+(itemDiameter+padding)/2;
			let sizeHeight = CGFloat(lines) * itemDiameter + 2 * padding
			_contentSizeUnscaled = CGSizeMake(sizeWidth, sizeHeight);
			newMinimumZoomScale = min((size.width-insets.left-insets.right)/_contentSizeUnscaled.width, (size.height-insets.top-insets.bottom)/_contentSizeUnscaled.height);
	
			_contentSizeExtra = CGSizeMake((size.width-itemDiameter*0.5)/newMinimumZoomScale, (size.height-itemDiameter*0.5)/newMinimumZoomScale);
	
			_contentSizeUnscaled.width += _contentSizeExtra.width;
			_contentSizeUnscaled.height += _contentSizeExtra.height;
			_contentView.bounds = CGRectMake(0, 0, _contentSizeUnscaled.width, _contentSizeUnscaled.height);
		}
		
		if _minimumZoomLevelIsDirty {
			minimumZoomScale = newMinimumZoomScale;
			let newZoom: CGFloat = max(self.zoomScale, newMinimumZoomScale);
			if newZoom != _zoomScaleCache || true {
				self.zoomScale = newZoom;
				_zoomScaleCache = newZoom;
		
				_contentView.center = CGPointMake(_contentSizeUnscaled.width*0.5*newZoom, _contentSizeUnscaled.height*0.5*newZoom);
				self.contentSize = CGSizeMake(_contentSizeUnscaled.width*newZoom, _contentSizeUnscaled.height*newZoom);
			}
		}
		
		if _contentSizeIsDirty {
			var i: Int = 0;
			for view in itemViews {
				view.bounds = CGRectMake(0, 0, itemDiameter, itemDiameter);
				
				var posX: CGFloat = 0;
				var posY: CGFloat = 0;
				
				var line: UInt = UInt(CGFloat(i)/itemsPerLine);
				var indexInLine: UInt = UInt(i % Int(itemsPerLine));
				if i == 0 {
					// place item 0 at the center of the grid
					line = UInt(CGFloat(itemViews.count) / itemsPerLine / 2);
					indexInLine = UInt(itemsPerLine/2);
				}
				else
				{
					// switch item at center of grid to position 0
					if line == UInt(CGFloat(itemViews.count) / itemsPerLine / 2)
						&& indexInLine == UInt(itemsPerLine / 2) {
							line = 0;
							indexInLine = 0;
					}
				}
		
				var lineOffset: CGFloat = 0;
				if line % 2 == 1 {
					lineOffset = (itemDiameter + itemPadding) / 2;
				}
				
				posX = _contentSizeExtra.width * 0.5 + itemPadding + lineOffset + CGFloat(indexInLine) * (itemDiameter + itemPadding) + itemDiameter/2;
				posY = _contentSizeExtra.height * 0.5 + itemPadding + CGFloat(line) * itemDiameter + itemDiameter / 2;
				view.center = CGPointMake(posX, posY);
		
				i++;
			}
	
			_contentSizeIsDirty = false;
		}
		if _minimumZoomLevelIsDirty {
			if _lastFocusedViewIndex <= itemViews.count {
				centerOnIndex(_lastFocusedViewIndex, zoomScale:_zoomScaleCache, animated:false);
			}
	
			_minimumZoomLevelIsDirty = false;
		}
  
		_zoomScaleCache = self.zoomScale;
  
		_touchView.bounds = CGRectMake(0, 0, (_contentSizeUnscaled.width-_contentSizeExtra.width)*_zoomScaleCache, (_contentSizeUnscaled.height-_contentSizeExtra.height)*_zoomScaleCache);
		_touchView.center = CGPointMake(_contentSizeUnscaled.width*0.5*_zoomScaleCache, _contentSizeUnscaled.height*0.5*_zoomScaleCache);
  
		LM_centerViewIfSmaller();
  
		let scale: CGFloat = min(_minimumItemScaling*_transformFactor+(1-_transformFactor), 1);
		_minTransform = CGAffineTransformMakeScale(scale, scale);
		for view in itemViews as! [SpringboardItemView] {
			LM_transformView(view);
		}
	}
	
	public override var bounds: CGRect {
		get {
			return super.bounds
		}
		
		set {
			if !CGSizeEqualToSize(super.bounds.size, newValue.size) {
				LM_setMinimumZoomLevelIsDirty();
			}
			super.bounds = newValue;
		}
	}
	
	public override var frame: CGRect {
		get {
			return super.frame;
		}
		
		set {
			if !CGSizeEqualToSize(newValue.size, bounds.size) {
				LM_setMinimumZoomLevelIsDirty();
			}
			super.frame = newValue;
		}
	}
}
