/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2010-2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */


#import "ExternalDisplayManager.h"

#define kFPS 60
#define CORE_ANIMATION_MAX_FRAMES_PER_SECOND 60

@implementation ExternalDisplayManager

@synthesize delegate, view, mirror;

-(id)init
{
	if ((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(screenDidConnectNotification:) name: UIScreenDidConnectNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(screenDidDisconnectNotification:) name: UIScreenDidDisconnectNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(screenModeDidChangeNotification:) name: UIScreenModeDidChangeNotification object: nil];
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(deviceOrientationDidChange:) name: UIDeviceOrientationDidChangeNotification object: nil];
	}
	return self;
}

-(void)dealloc
{
	[self stop:YES];
	[view release], view = nil;
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[super dealloc];
}

-(void)setTVMode:(BOOL)yn
{
	if (tvoutWindow) {
		if (tvSafeMode == YES && yn == NO) {
			[UIView beginAnimations:@"zoomIn" context: nil];
			tvoutWindow.transform = CGAffineTransformScale(tvoutWindow.transform, 1.25, 1.25);
			[UIView commitAnimations];
			[tvoutWindow setNeedsDisplay];
		} else if (tvSafeMode == NO && yn == YES) {
			[UIView beginAnimations:@"zoomOut" context: nil];
			tvoutWindow.transform = CGAffineTransformScale(tvoutWindow.transform, .8, .8);
			[UIView commitAnimations];			
			[tvoutWindow setNeedsDisplay];
		}
	}
	tvSafeMode = yn;
}

-(void)start
{
	NSArray* screens = [UIScreen screens];
	
	if ([screens count] <= 1) {
		return;	
	}
	
	if (tvoutWindow) {
		[tvoutWindow release];
		tvoutWindow = nil;
	}

	if (mirrorView)	{
		[mirrorView release];
		mirrorView = nil;
	}
	
	if (deviceWindow) {
		[deviceWindow release];
		deviceWindow = nil;
	}
	
	if (!tvoutWindow) {
		deviceWindow = [[[UIApplication sharedApplication] keyWindow] retain];
		
		CGSize max;
		max.width = 0;
		max.height = 0;
		UIScreenMode *maxScreenMode = nil;
		UIScreen *external = [[UIScreen screens] objectAtIndex: 1];
		for(int i = 0; i < [[external availableModes] count]; i++) {
			UIScreenMode *current = [[[[UIScreen screens] objectAtIndex:1] availableModes] objectAtIndex: i];
			if (current.size.width > max.width)	{
				max = current.size;
				maxScreenMode = current;
			}
		}
		external.currentMode = maxScreenMode;
		
		tvoutWindow = [[UIWindow alloc] initWithFrame: CGRectMake(0,0, max.width, max.height)];
		tvoutWindow.userInteractionEnabled = NO;
		tvoutWindow.screen = external;
		tvoutWindow.opaque = YES;
		tvoutWindow.hidden = NO;
		tvoutWindow.backgroundColor = [UIColor blackColor];
		tvoutWindow.layer.contentsGravity = kCAGravityResizeAspect;
		
		UIApplication *app = [UIApplication sharedApplication];
		[self updateMirroredWindowTransformForInterfaceOrientation:app.statusBarOrientation];
		
		BOOL image = NO;
		CGFloat bigScale = 1.0;
		
		if ((view!=nil) && !mirror)	{
			mirrorView = [view retain]; // for the view itself
			if (CGRectIsEmpty(view.frame) || CGRectIsNull(view.frame)) {
				view.frame = tvoutWindow.frame;
			}
		} else {
			// size the mirrorView to expand to fit the external screen
			CGRect mirrorRect;
			if ((view != nil) && mirror) {
				mirrorRect = [view bounds];
			} else {
				mirrorRect = [[UIScreen mainScreen] bounds];
			}
			CGFloat horiz = max.width / CGRectGetWidth(mirrorRect);
			CGFloat vert = max.height / CGRectGetHeight(mirrorRect);
			bigScale = horiz < vert ? horiz : vert;
			mirrorRect = CGRectMake(mirrorRect.origin.x, mirrorRect.origin.y, mirrorRect.size.width * bigScale, mirrorRect.size.height * bigScale);
			mirrorView = [[UIImageView alloc] initWithFrame: mirrorRect];
			image = YES;
		}
		scaleView = CGAffineTransformMakeScale(bigScale, bigScale);
		mirrorView.center = tvoutWindow.center;
		
		// TV safe area -- scale the window by 20% -- for composite / component, not needed for VGA output
		if (tvSafeMode) {
			tvoutWindow.transform = CGAffineTransformScale(tvoutWindow.transform, .8, .8);
		}
		[tvoutWindow addSubview: mirrorView];
		[tvoutWindow makeKeyAndVisible];
		tvoutWindow.hidden = NO;		
		tvoutWindow.backgroundColor = [UIColor darkGrayColor];
		
		if (image) {
			// orient the view properly
			if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) {
				mirrorView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI * 1.5);			
			} else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight) {
				mirrorView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI * -1.5);
			} else {
				mirrorView.transform = CGAffineTransformIdentity;
			}
		}
		
		done = NO;
		[deviceWindow makeKeyAndVisible];
		
		// Setup periodic callbacks
		[displayLink invalidate];
		[displayLink release];
		displayLink = nil;
		
		if ([mirrorView isKindOfClass:[UIImageView class]]) {
			[self update:nil];
			
			// Setup display link sync
			displayLink = [[CADisplayLink displayLinkWithTarget:self selector:@selector(update:)] retain];
			[displayLink setFrameInterval:(kFPS >= CORE_ANIMATION_MAX_FRAMES_PER_SECOND) ? 1 : (CORE_ANIMATION_MAX_FRAMES_PER_SECOND / kFPS)];
			
			// We MUST add ourselves in the commons run loop in order to mirror during UITrackingRunLoopMode.
			// Otherwise, the display won't be updated while fingering are touching the screen.
			// This has a major impact on performance though...
			[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		}
	}
}

-(void)stop:(BOOL)forGood
{
	done = forGood;
	if (displayLink) {
		[displayLink invalidate];
		[displayLink release];
		displayLink = nil;
	}
	if (tvoutWindow) {
		[tvoutWindow release];
		tvoutWindow = nil;
	}
	if (deviceWindow) {
		[deviceWindow release];
		deviceWindow = nil;
	}
	if (mirrorView)	{
		[mirrorView release];
		mirrorView = nil;
	}
}

-(void)screenDidConnectNotification:(NSNotification*) notification
{
	NSLog(@"[DEBUG] screen did connect = %@",notification);
	if (delegate) {
		[delegate screenDidConnectNotification];
	}
	[self start];
}

-(void)screenDidDisconnectNotification:(NSNotification*) notification
{
	NSLog(@"[DEBUG] screen did disconnect = %@",notification);
	if (delegate) {
		[delegate screenDidDisconnectNotification];
	}
	[self stop:NO];
}

-(void)screenModeDidChangeNotification:(NSNotification*) notification
{
	NSLog(@"[DEBUG] screen mode did change = %@",notification);
	[self stop:NO];
	[self start];
}

-(void)updateMirroredWindowTransformForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Grab the secondary window layer
	CALayer *mirrorLayer = mirrorView.layer;
	mirrorView.transform = CGAffineTransformIdentity;
	
	// Rotate to match interface orientation
	switch (interfaceOrientation) 
	{
		case UIInterfaceOrientationPortrait:
			mirrorLayer.transform = CATransform3DIdentity;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			mirrorLayer.transform = CATransform3DMakeRotation(M_PI / 2, 0.0f, 0.0f, 1.0f);
			break;
		case UIInterfaceOrientationLandscapeRight:
			mirrorLayer.transform = CATransform3DMakeRotation(-(M_PI / 2), 0.0f, 0.0f, 1.0f);
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			mirrorLayer.transform = CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f);
			break;
		default:
			break;
	}
}

-(void)deviceOrientationDidChange:(NSNotification*) notification
{
	if (mirrorView == nil || done == YES || [mirrorView isKindOfClass:[UIImageView class]]==NO) return;
	UIDeviceOrientation newInterfaceOrientation = [[UIDevice currentDevice] orientation];
	[self updateMirroredWindowTransformForInterfaceOrientation:newInterfaceOrientation];	
}

-(void)update:(CADisplayLink *)sender
{
	if (deviceWindow == nil) return;
	
	// For higher quality rendering and display on the external monitor:
	//
	// 1. Create the graphics image to be the same size as the final output
	// 2. Scale the coordinates used for the drawing/rendering -- use the same scaling that was used to creat the mirrorView.
	// 3. Set the rendered image on the view.
	//
	// We don't want to draw to a graphics image that is the size of the original and then have the image scaled to the size of the
	// external monitor because pixelization occurs when scaling a rasterized image. Of course, if the view contains images then
	// those will be scaled and pixelized in the process, but text should render cleaner this way at the expense of a little more
	// memory for the in-memory image.

	UIGraphicsBeginImageContextWithOptions(mirrorView.bounds.size,NO,0);
	CGContextRef context = UIGraphicsGetCurrentContext();

	if (view) {
		CGContextSaveGState(context);
		if (!CGAffineTransformIsIdentity(scaleView)) {
			CGContextConcatCTM(context, scaleView);
		}
		[[view layer] renderInContext:context];
		CGContextRestoreGState(context);
	} else {
		SEL sel = @selector(screen);
		for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
			if (![window respondsToSelector:sel] || [window screen] == [UIScreen mainScreen]) {
				CGContextSaveGState(context);
				CGContextTranslateCTM(context, [window center].x, [window center].y);
				CGContextConcatCTM(context, [window transform]);
				// Y-offset for the status bar (if it's showing)
				NSInteger yOffset = [UIApplication sharedApplication].statusBarHidden ? 0 : -20;
				UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
				if (orientation == UIInterfaceOrientationPortrait){
					CGContextTranslateCTM(context, -[window bounds].size.width * window.layer.anchorPoint.x, -[window bounds].size.height * window.layer.anchorPoint.y+yOffset);
				} else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
					CGContextTranslateCTM(context, -[window bounds].size.width * window.layer.anchorPoint.x, -[window bounds].size.height * window.layer.anchorPoint.y - yOffset);
				} else if (orientation == UIInterfaceOrientationLandscapeRight) {
					CGContextTranslateCTM(context, -[window bounds].size.width * window.layer.anchorPoint.x - yOffset, -[window bounds].size.height * window.layer.anchorPoint.y);
				} else {
					CGContextTranslateCTM(context, -[window bounds].size.width * window.layer.anchorPoint.x + yOffset, -[window bounds].size.height * window.layer.anchorPoint.y);
				}

				if (!CGAffineTransformIsIdentity(scaleView)) {
					CGContextConcatCTM(context, scaleView);
				}
				[[window layer] renderInContext:context];
				CGContextRestoreGState(context);
			}
		}
	}
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	((UIImageView*)mirrorView).image = image;
}

+(ExternalDisplayManager*)sharedInstance
{
	static ExternalDisplayManager *i;
	@synchronized(self)
	{
		if (!i) {
			i = [[ExternalDisplayManager alloc] init];
		}
		return i;
	}
}

+(void)start:(id<ExternalDisplayManagerDelegate>) delegate
{
	[ExternalDisplayManager sharedInstance].delegate = delegate;
	[[ExternalDisplayManager sharedInstance] start];
}

+(void)stop
{
	[[ExternalDisplayManager sharedInstance] stop:YES];
}

+(void)setTVMode:(BOOL)yn
{
	[[ExternalDisplayManager sharedInstance] setTVMode:yn];
}

+(void)setView:(UIView *)view mirror:(BOOL)mirror
{
	[ExternalDisplayManager sharedInstance].mirror = mirror;
	[ExternalDisplayManager sharedInstance].view = view;
	[ExternalDisplayManager stop];
	[ExternalDisplayManager start:[ExternalDisplayManager sharedInstance].delegate];
}

+(UIScreen*)externalDisplay
{
	if ([[UIScreen screens] count] > 1) {
		return [[UIScreen screens] objectAtIndex: 1];
	}
	return nil;
}

@end
