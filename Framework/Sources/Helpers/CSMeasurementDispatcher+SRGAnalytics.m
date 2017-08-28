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

static CSCore *s_fakeCore;

// Private comScore methods
@interface NSObject (SRGCSApplicationMeasurement)

+ (id)newWithCore:(CSCore *)core eventType:(CSApplicationEventType)type labels:(NSDictionary *)labels timestamp:(long long)timestamp;
- (NSDictionary *)getLabels;

@end

__attribute__((constructor)) static void CSMeasurementDispatcherInit(void)
{
    // Create early enough since initialized asynchronously in comScore SDK (!)
    s_fakeCore = [[CSCore alloc] init];
}

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
    SRGAnalyticsConfiguration *configuration = [SRGAnalyticsTracker sharedTracker].configuration;
    if (configuration.unitTesting) {
        // Labels are not complete. To get (almost) all labels we mimic the comScore SDK by creating the measurement object. The
        // timestamp will not be identical to the timestamp of the real event which is sent afterwards, and global labels will
        // be missing.
        long long timestamp = [[NSDate date] timeIntervalSince1970];
        id measurement = [NSClassFromString(@"CSApplicationMeasurement") newWithCore:s_fakeCore eventType:eventType labels:labels timestamp:timestamp];
        
        NSMutableDictionary<NSString *, NSString *> *fullLabels = [NSMutableDictionary dictionary];
        for (id label in [measurement getLabels].allValues) {
            NSString *name = [label valueForKey:@"name"];
            NSString *value = [label valueForKey:@"value"];
            fullLabels[name] = value;
        }
        
        NSDictionary *userInfo = @{ SRGAnalyticsComScoreLabelsKey : [fullLabels copy] };
        
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
    else {
        // Call the original implementation
        [self swizzled_send:eventType labels:labels cache:cache background:background];
    }
}

@end
