//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "CSRequest+SRGAnalytics.h"
#import <objc/runtime.h>

NSString * const SRGAnalyticsComScoreRequestDidFinishNotification = @"SRGAnalyticsComScoreRequestDidFinish";
NSString * const SRGAnalyticsComScoreRequestLabelsUserInfoKey = @"SRGAnalyticsLabels";

@interface NSObject (SRGCSApplicationMeasurement)

+ (id)newWithCore:(id)core eventType:(CSApplicationEventType)type labels:(NSDictionary *)labels timestamp:(long long)timestamp;
- (NSDictionary *)getLabels;

@end

@implementation CSMeasurementDispatcher (SRGNotification)

+ (void)load
{
    // Swizzle a method which gets called early, not when the events are really sent. comScore processes events after some
    // time, which is unreliable
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(send:labels:cache:background:)),
                                   class_getInstanceMethod(self, @selector(swizzled_send:labels:cache:background:)));
}

- (void)swizzled_send:(CSApplicationEventType)eventType labels:(NSDictionary *)labels cache:(BOOL)cache background:(BOOL)background
{
    // Call the original implementation
    [self swizzled_send:eventType labels:labels cache:cache background:background];
    
    // Labels are not complete. To get all labels we mimic the comScore SDK by creating the measurement object. Only the
    // timestamp will not be identical to the timestamp of the real event which is sent afterwards
    long long timestamp = [[NSDate date] timeIntervalSince1970];
    id core = object_getIvar(self, class_getInstanceVariable([self class], "_core"));
    id measurement = [NSClassFromString(@"CSApplicationMeasurement") newWithCore:core eventType:eventType labels:labels timestamp:timestamp];
    
    NSMutableDictionary *completeLabels = [NSMutableDictionary dictionary];
    for (id label in [measurement getLabels].allValues) {
        NSString *name = [label valueForKey:@"name"];
        NSString *value = [label valueForKey:@"value"];
        completeLabels[name] = value;
    }
    
    NSDictionary *userInfo = @{ SRGAnalyticsComScoreRequestLabelsUserInfoKey : [completeLabels copy] };
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SRGAnalyticsComScoreRequestDidFinishNotification object:self userInfo:userInfo];
    });
}

@end
