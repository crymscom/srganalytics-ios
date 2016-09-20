//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+SRGAnalytics.h"

#import "SRGAnalyticsTracker.h"
#import "SRGAnalyticsPageViewDataSource.h"

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
    if ([self conformsToProtocol:@protocol(SRGAnalyticsPageViewDataSource)]) {
        [[SRGAnalyticsTracker sharedTracker] trackPageViewForDataSource:(id<SRGAnalyticsPageViewDataSource>)self];
    }
}

@end

#pragma mark Functions

static void swizzed_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated)
{
    s_viewDidAppear(self, _cmd, animated);

    if ([self conformsToProtocol:@protocol(SRGAnalyticsPageViewDataSource)]) {
        id<SRGAnalyticsPageViewDataSource> dataSource = (id<SRGAnalyticsPageViewDataSource>)self;
        if (! [dataSource respondsToSelector:@selector(isTrackedAutomatically)] || [dataSource isTrackedAutomatically]) {
            [self trackPageView];
        }
    }
}
