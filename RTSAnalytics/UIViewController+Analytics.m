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
	[self trackPageView];
}

- (void) trackPageView
{
	if (![self conformsToProtocol:@protocol(RTSAnalyticsPageViewDataSource)])
		return;
	
	[[RTSAnalyticsTracker sharedTracker] trackPageViewForDataSource:(id<RTSAnalyticsPageViewDataSource>)self];
}

+ (void) load
{
	Method viewDidAppear = class_getInstanceMethod(self, @selector(viewDidAppear:));
	viewDidAppearIMP = (__typeof__(viewDidAppearIMP))method_getImplementation(viewDidAppear);
	method_setImplementation(viewDidAppear, (IMP)AnalyticsViewDidAppear);
}

@end
