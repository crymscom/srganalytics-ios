//
//  UIViewController+Analytics.m
//  RTSAnalytics
//
//  Created by Frédéric Humbert-Droz on 09/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "UIViewController+Analytics.h"

#import <objc/runtime.h>

#import "RTSAnalyticsTracker.h"
#import "NSString+RTSAnalyticsUtils.h"
#import "RTSAnalyticsPageViewDataSource.h"

@implementation UIViewController (Analytics)

static void (*viewDidAppearIMP)(UIViewController *, SEL, BOOL);

static void AnalyticsViewDidAppear(UIViewController *self, SEL _cmd, BOOL animated);
static void AnalyticsViewDidAppear(UIViewController *self, SEL _cmd, BOOL animated)
{
	viewDidAppearIMP(self, _cmd, animated);
	[self sendPageView];
}

- (void) sendPageView
{
	id<RTSAnalyticsPageViewDataSource> controller = (id<RTSAnalyticsPageViewDataSource>)self;
	if ([controller respondsToSelector:@selector(pageViewTitle)])
	{
		NSString *title = [controller pageViewTitle];
		NSArray *levels = nil;
		
		if ([controller respondsToSelector:@selector(pageViewLevels)])
			levels = [controller pageViewLevels];

		//FIXME : detect from notification
		[[RTSAnalyticsTracker sharedTracker] trackPageViewTitle:title levels:levels fromPushNotification:NO];
	}
}

+ (void) load
{
	Method viewDidAppear = class_getInstanceMethod(self, @selector(viewDidAppear:));
	viewDidAppearIMP = (__typeof__(viewDidAppearIMP))method_getImplementation(viewDidAppear);
	method_setImplementation(viewDidAppear, (IMP)AnalyticsViewDidAppear);
}


@end
