//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+SRGAnalytics.h"

#import "SRGAnalyticsTracker.h"

#import <libextobjc/libextobjc.h>
#import <objc/runtime.h>

// Associated object keys
static void *s_observerKey = &s_observerKey;
static void *s_appearedOnce = &s_appearedOnce;

// Swizzled method original implementations
static void (*s_viewDidAppear)(id, SEL, BOOL);
static void (*s_viewWillDisappear)(id, SEL, BOOL);

// Swizzled method implementations
static void swizzled_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated);
static void swizzled_viewWillDisappear(UIViewController *self, SEL _cmd, BOOL animated);

@implementation UIViewController (SRGAnalytics)

#pragma mark Class methods

+ (void)load
{
    Method viewDidAppearMethod = class_getInstanceMethod(self, @selector(viewDidAppear:));
    s_viewDidAppear = (__typeof__(s_viewDidAppear))method_getImplementation(viewDidAppearMethod);
    method_setImplementation(viewDidAppearMethod, (IMP)swizzled_viewDidAppear);
    
    Method viewWillDisappearMethod = class_getInstanceMethod(self, @selector(viewWillDisappear:));
    s_viewWillDisappear = (__typeof__(s_viewWillDisappear))method_getImplementation(viewWillDisappearMethod);
    method_setImplementation(viewWillDisappearMethod, (IMP)swizzled_viewWillDisappear);
}

#pragma mark Tracking

- (void)srg_trackPageView
{
    return [self srg_trackPageViewAutomatic:NO];
}

- (void)srg_trackPageViewAutomatic:(BOOL)automatic
{
    if ([self conformsToProtocol:@protocol(SRGAnalyticsViewTracking)]) {
        id<SRGAnalyticsViewTracking> trackedSelf = (id<SRGAnalyticsViewTracking>)self;
        
        if (automatic && [trackedSelf respondsToSelector:@selector(srg_isTrackedAutomatically)] && ! [trackedSelf srg_isTrackedAutomatically]) {
            return;
        }
        
        NSString *title = [trackedSelf srg_pageViewTitle];
        
        NSArray<NSString *> *levels = nil;
        if ([trackedSelf respondsToSelector:@selector(srg_pageViewLevels)]) {
            levels = [trackedSelf srg_pageViewLevels];
        }
        
        SRGAnalyticsPageViewLabels *labels = nil;
        if ([trackedSelf respondsToSelector:@selector(srg_pageViewLabels)]) {
            labels = [trackedSelf srg_pageViewLabels];
        }
        
        BOOL fromPushNotification = NO;
        if ([trackedSelf respondsToSelector:@selector(srg_isOpenedFromPushNotification)]) {
            fromPushNotification = [trackedSelf srg_isOpenedFromPushNotification];
        }
        
        [[SRGAnalyticsTracker sharedTracker] trackPageViewWithTitle:title
                                                             levels:levels
                                                             labels:labels
                                               fromPushNotification:fromPushNotification];
    }
}

@end

#pragma mark Functions

static void swizzled_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated)
{
    s_viewDidAppear(self, _cmd, animated);
    
    // Track a view controller at most once automatically when appearing. This covers all possible appearance scenarios,
    // e.g.
    //    - Moving to a parent view controller
    //    - Modal presentation
    //    - View controller revealed after having been initially hidden behind a modal view controller
    if (! [objc_getAssociatedObject(self, s_appearedOnce) boolValue]) {
        [self srg_trackPageViewAutomatic:YES];
        objc_setAssociatedObject(self, s_appearedOnce, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    // An anonymous observer (conveniently created with the notification center registration method taking a block as
    // parameter) is required. If we simply registered `self` as observer, removal in `-viewWillDisappear:` would also
    // remove all other registrations of the view controller for the same notifications!
    @weakify(self)
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        @strongify(self)
        
        [self srg_trackPageViewAutomatic:YES];
    }];
    objc_setAssociatedObject(self, s_observerKey, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void swizzled_viewWillDisappear(UIViewController *self, SEL _cmd, BOOL animated)
{
    s_viewWillDisappear(self, _cmd, animated);
    
    id observer = objc_getAssociatedObject(self, s_observerKey);
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    objc_setAssociatedObject(self, s_observerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
