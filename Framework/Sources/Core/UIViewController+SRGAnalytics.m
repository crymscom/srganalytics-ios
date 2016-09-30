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
static void (*s_viewWillDisappear)(id, SEL, BOOL);

// Swizzled method implementations
static void swizzed_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated);
static void swizzed_viewWillDisappear(UIViewController *self, SEL _cmd, BOOL animated);

@implementation UIViewController (SRGAnalytics)

#pragma mark Class methods

+ (void)load
{
    Method viewDidAppearMethod = class_getInstanceMethod(self, @selector(viewDidAppear:));
    s_viewDidAppear = (__typeof__(s_viewDidAppear))method_getImplementation(viewDidAppearMethod);
    method_setImplementation(viewDidAppearMethod, (IMP)swizzed_viewDidAppear);
    
    Method viewWillDisappearMethod = class_getInstanceMethod(self, @selector(viewWillDisappear:));
    s_viewWillDisappear = (__typeof__(s_viewWillDisappear))method_getImplementation(viewWillDisappearMethod);
    method_setImplementation(viewWillDisappearMethod, (IMP)swizzed_viewWillDisappear);
}

#pragma mark Tracking

- (void)trackPageView
{
    if ([self conformsToProtocol:@protocol(SRGAnalyticsViewTracking)]) {
        id<SRGAnalyticsViewTracking> trackedSelf = (id<SRGAnalyticsViewTracking>)self;
        
        if ([trackedSelf respondsToSelector:@selector(srg_isTrackedAutomatically)] && ! [trackedSelf srg_isTrackedAutomatically]) {
            return;
        }
        
        NSString *title = [trackedSelf srg_pageViewTitle];
        
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
        
        [[SRGAnalyticsTracker sharedTracker] trackPageViewTitle:title
                                                         levels:levels
                                                   customLabels:customLabels
                                           fromPushNotification:fromPushNotification];
    }
}

#pragma mark Notifications

- (void)srg_viewController_analytics_applicationWillEnterForeground:(NSNotification *)notification
{
    [self trackPageView];
}

@end

#pragma mark Functions

static void swizzed_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated)
{
    s_viewDidAppear(self, _cmd, animated);
    
    [self trackPageView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(srg_viewController_analytics_applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

static void swizzed_viewWillDisappear(UIViewController *self, SEL _cmd, BOOL animated)
{
    s_viewWillDisappear(self, _cmd, animated);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}
