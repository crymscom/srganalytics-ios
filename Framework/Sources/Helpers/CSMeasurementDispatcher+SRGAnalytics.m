//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "CSMeasurementDispatcher+SRGAnalytics.h"

#import "SRGAnalyticsLogger.h"
#import "SRGAnalyticsNotifications.h"
#import "SRGAnalyticsTracker.h"

#import <objc/runtime.h>

// Private comScore methods
@interface NSObject (SRGCSApplicationMeasurement)

+ (id)newWithCore:(CSCore *)core eventType:(CSApplicationEventType)type labels:(NSDictionary *)labels timestamp:(long long)timestamp;
- (NSDictionary *)getLabels;

@end

@implementation CSMeasurementDispatcher (SRGAnalytics)

#pragma mark Class methods

+ (void)load
{
    // Swizzle a method which gets called early, not when the events are really sent. comScore processes events after some
    // time, which is unreliable (especially for tests)
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(send:labels:cache:background:)),
                                   class_getInstanceMethod(self, @selector(swizzled_send:labels:cache:background:)));
}

- (void)swizzled_send:(CSApplicationEventType)eventType labels:(NSDictionary *)labels cache:(BOOL)cache background:(BOOL)background
{
    // Call the original implementation
    [self swizzled_send:eventType labels:labels cache:cache background:background];

    // Do not do anything when not running in test mode
    SRGAnalyticsTracker *tracker = [SRGAnalyticsTracker sharedTracker];
    if (! [tracker.businessUnitIdentifier isEqualToString:SRGAnalyticsBusinessUnitIdentifierTEST]) {
        return;
    }
    
    id core = object_getIvar(self, class_getInstanceVariable([self class], "_core"));
    
    // The application measurement creation below will crash if the AdSupport framework is linked with the project. We can
    // apply a fix by forcing unique id generation, but this fix was discovered to lead to subtle internal comScore issues.
    // We still keep this fix for the test BU, used in our test suite. Everything will be dropped when comScore is replaced,
    // after all
    if (NSClassFromString(@"ASIdentifierManager") != Nil) {
        SRGAnalyticsLogWarning(@"notifications", @"comScore notifications are not sent when the AdSupport framework is linked "
                               "to the project. Contact us if this support is really required in your case.");
        
        // To avoid internal comScore crashes, we force unique id generation. This might lead to instabilities, as we
        // discovered, which is why we add a warning message to the logs. This is a test-only behavior, though, and
        // comScore support will be dropped soon, we therefore don't need a better fix for the moment.
        SEL selector = NSSelectorFromString(@"generateCrossPublisherUniqueId");
        void (*methodImp)(id, SEL) = (void (*)(id, SEL))[core methodForSelector:selector];
        methodImp(core, selector);
    }
    
    // Labels are not complete. To get all labels we mimic the comScore SDK by creating the measurement object. Only the
    // timestamp will not be identical to the timestamp of the real event which is sent afterwards
    long long timestamp = [[NSDate date] timeIntervalSince1970];
    id measurement = [NSClassFromString(@"CSApplicationMeasurement") newWithCore:core eventType:eventType labels:labels timestamp:timestamp];
    
    NSMutableDictionary<NSString *, NSString *> *fullLabels = [NSMutableDictionary dictionary];
    for (id label in [measurement getLabels].allValues) {
        NSString *name = [label valueForKey:@"name"];
        NSString *value = [label valueForKey:@"value"];
        fullLabels[name] = value;
    }
    
    NSDictionary *userInfo = @{ SRGAnalyticsComScoreLabelsKey: [fullLabels copy] };
    
    void (^notificationBlock)(void) = ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SRGAnalyticsComScoreRequestNotification object:self userInfo:userInfo];
    };
    
    if (! [NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), notificationBlock);
    }
    else {
        notificationBlock();
    }
}

@end
