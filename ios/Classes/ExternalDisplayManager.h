/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2010-2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */


#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@protocol ExternalDisplayManagerDelegate
@optional

-(void)screenDidConnectNotification;
-(void)screenDidDisconnectNotification;

@end


@interface ExternalDisplayManager : NSObject {
	UIWindow* deviceWindow;
	UIWindow* tvoutWindow;
	UIView *mirrorView;
	UIView *view;
	BOOL mirror;
	BOOL done;
	BOOL tvSafeMode;
	CGAffineTransform scaleView;
	CADisplayLink *displayLink;
	id<ExternalDisplayManagerDelegate> delegate;
}

@property(nonatomic,assign) id<ExternalDisplayManagerDelegate> delegate;
@property(nonatomic,retain) UIView *view;
@property(nonatomic,assign) BOOL mirror;

#pragma mark Private
-(void)start;
-(void)stop:(BOOL)forGood;
-(void)updateMirroredWindowTransformForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

#pragma mark Public
+(void)start:(id<ExternalDisplayManagerDelegate>) delegate;
+(void)stop;
+(void)setTVMode:(BOOL)yn;
+(void)setView:(UIView*)view mirror:(BOOL)mirror;
+(UIScreen*)externalDisplay;

@end
