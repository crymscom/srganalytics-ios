//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+SRGAnalytics.h"

#import "SRGAnalyticsTracker+Private.h"

#import <objc/runtime.h>

// Swizzled method original implementations
static void (*s_viewDidAppear)(id, SEL, BOOL);

// Swizzled method implementations
static void swizzed_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated);

@implementation UIViewController (SRGAnalytics)

#pragma mark Class methods

+ (void)load
{
    Method viewDidAppearMethod = class_getInstanceMethod(self, @selector(viewDidAppear:));
    s_viewDidAppear = (__typeof__(s_viewDidAppear))method_getImplementation(viewDidAppearMethod);
    method_setImplementation(viewDidAppearMethod, (IMP)swizzed_viewDidAppear);
}

#pragma mark Tracking

- (void)trackPageView
{
    if ([self conformsToProtocol:@protocol(SRGAnalyticsViewTracking)]) {
        id<SRGAnalyticsViewTracking> trackedSelf = (id<SRGAnalyticsViewTracking>)self;
        
        NSArray<NSString *> *levels = nil;
        if ([trackedSelf respondsToSelector:@selector(srg_pageViewLevels)]) {
            levels = [trackedSelf srg_pageViewLevels];
        }
        
        NSDictionary<NSString *, NSString *> *customLabels = nil;
        if ([trackedSelf respondsToSelector:@selector(srg_pageViewCustomLabels)]) {
            customLabels = [trackedSelf srg_pageViewCustomLabels];
        }
        
        BOOL fromPushNotification = NO;
        if ([trackedSelf respondsToSelector:@selector(srg_isOpenedFromPushNotification)]) {
            fromPushNotification = [trackedSelf srg_isOpenedFromPushNotification];
        }
        
        [[SRGAnalyticsTracker sharedTracker] trackPageViewTitle:[trackedSelf srg_pageViewTitle]
                                                         levels:levels
                                                   customLabels:customLabels
                                           fromPushNotification:fromPushNotification];
    }
}

@end

#pragma mark Functions

static void swizzed_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated)
{
    s_viewDidAppear(self, _cmd, animated);

    if ([self conformsToProtocol:@protocol(SRGAnalyticsViewTracking)]) {
        id<SRGAnalyticsViewTracking> tracking = (id<SRGAnalyticsViewTracking>)self;
        if (! [tracking respondsToSelector:@selector(srg_isTrackedAutomatically)] || [tracking srg_isTrackedAutomatically]) {
            [self trackPageView];
        }
    }
}
