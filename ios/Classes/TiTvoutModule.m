/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2010-2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */


#import "TiTvoutModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiRect.h"
#import "TiViewProxy.h"
#import "ExternalDisplayManager.h"

@implementation TiTvoutModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"4a96f222-9aee-453c-82d5-a7cb38778b25";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"ti.tvout";
}

-(NSDictionary*)makeEvent:(UIScreen*)screen
{
	if (screen==nil) return nil;
	NSMutableDictionary *event = [NSMutableDictionary dictionary];
	CGRect rect = [screen bounds];
	CGSize size = screen.currentMode.size;
	[event setObject:NUMFLOAT(screen.currentMode.pixelAspectRatio) forKey:@"pixelAspectRatio"];
	[event setObject:NUMFLOAT(screen.scale) forKey:@"scale"];
	[event setObject:NUMFLOAT(rect.size.width) forKey:@"width"];
	[event setObject:NUMFLOAT(rect.size.height) forKey:@"height"];
	[event setObject:[NSDictionary dictionaryWithObjectsAndKeys:NUMFLOAT(size.width),@"width",NUMFLOAT(size.height),@"height",nil] forKey:@"size"];
	return event;
}

#pragma mark Public API

-(id)connected
{
	UIScreen *screen = [ExternalDisplayManager externalDisplay];
	return NUMBOOL(screen!=nil);
}

-(NSDictionary*)screen
{
	UIScreen *screen = [ExternalDisplayManager externalDisplay];
	return [self makeEvent:screen];
}

-(void)start:(id)args
{
	ENSURE_UI_THREAD_0_ARGS
	[ExternalDisplayManager start:self];
}

-(void)stop:(id)args
{
	ENSURE_UI_THREAD_0_ARGS
	[ExternalDisplayManager stop];
}

-(void)setView:(id)args
{
	TiViewProxy* view;
	NSNumber* value = nil;

	if ([args isKindOfClass:[NSArray class]]) {
		ENSURE_ARG_OR_NIL_AT_INDEX(view, args, 0, TiViewProxy);
		ENSURE_ARG_OR_NIL_AT_INDEX(value, args, 1, NSNumber);
	} else {
		ENSURE_SINGLE_ARG_OR_NIL(args, TiViewProxy);
		view = args;
	}

   	ENSURE_UI_THREAD_1_ARG(args);

   	BOOL mirror = [TiUtils boolValue:value def:NO];
	if (view == nil) {
		[ExternalDisplayManager setView:nil mirror:NO];
	} else {
		UIView *uiview = [view view];
		if (!mirror) {
			[uiview removeFromSuperview];
			[view windowWillOpen];
		}
		[ExternalDisplayManager setView:uiview mirror:mirror];
	}
}

-(void)setTVMode:(id)enabled
{
	ENSURE_UI_THREAD_1_ARG(enabled);
	ENSURE_SINGLE_ARG(enabled,NSNumber);
	[ExternalDisplayManager setTVMode:[TiUtils boolValue:enabled]];
}

#pragma mark Delegates

-(void)screenDidConnectNotification
{
	if ([self _hasListeners:@"connect"])
	{
		UIScreen *screen = [ExternalDisplayManager externalDisplay];
		NSDictionary *event = [self makeEvent:screen];
		[self fireEvent:@"connect" withObject:event];
	}
}

-(void)screenDidDisconnectNotification
{
	if ([self _hasListeners:@"disconnect"])
	{
		[self fireEvent:@"disconnect"];
	}
}

@end
