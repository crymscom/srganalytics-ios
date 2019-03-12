//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsTestCase.h"

#import <SRGAnalytics/SRGAnalytics.h>

static __attribute__((constructor)) void AnalyticsTestCaseInit(void)
{
    NSString *contentProtectionFrameworkPath = [NSBundle.mainBundle pathForResource:@"SRGContentProtection" ofType:@"framework" inDirectory:@"Frameworks"];
    NSBundle *contentProtectionFramework = [NSBundle bundleWithPath:contentProtectionFrameworkPath];
    [contentProtectionFramework loadAndReturnError:NULL];
}

@implementation AnalyticsTestCase

#pragma mark Helpers

- (XCTestExpectation *)expectationForSingleNotification:(NSNotificationName)notificationName object:(id)objectToObserve handler:(XCNotificationExpectationHandler)handler
{
    NSString *description = [NSString stringWithFormat:@"Expectation for notification '%@' from object %@", notificationName, objectToObserve];
    XCTestExpectation *expectation = [self expectationWithDescription:description];
    __block id observer = [NSNotificationCenter.defaultCenter addObserverForName:notificationName object:objectToObserve queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
        void (^fulfill)(void) = ^{
            [expectation fulfill];
            [NSNotificationCenter.defaultCenter removeObserver:observer];
        };
        
        if (handler) {
            if (handler(notification)) {
                fulfill();
            }
        }
        else {
            fulfill();
        }
    }];
    return expectation;
}

- (XCTestExpectation *)expectationForPageViewEventNotificationWithHandler:(EventExpectationHandler)handler
{
    return [self expectationForSingleNotification:SRGAnalyticsRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *event = labels[@"event_id"];
        if ([event isEqualToString:@"screen"]) {
            return handler(event, labels);
        }
        else {
            return NO;
        }
    }];
}

- (XCTestExpectation *)expectationForHiddenEventNotificationWithHandler:(EventExpectationHandler)handler
{
    return [self expectationForSingleNotification:SRGAnalyticsRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *event = labels[@"event_id"];
        if ([event isEqualToString:@"screen"]) {
            return NO;
        }
        
        // Discard app overlap measurements
        NSString *name = labels[@"event_name"];
        if ([name isEqualToString:@"Installed Apps"]) {
            return NO;
        }
        
        return handler(event, labels);
    }];
}

- (XCTestExpectation *)expectationForHiddenPlaybackEventNotificationWithHandler:(EventExpectationHandler)handler
{
    return [self expectationForSingleNotification:SRGAnalyticsRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        static dispatch_once_t s_onceToken;
        static NSArray<NSString *> *s_playerEvents;
        dispatch_once(&s_onceToken, ^{
            s_playerEvents = @[@"play", @"pause", @"seek", @"stop", @"eof"];
        });
        
        NSString *event = labels[@"event_id"];
        if ([s_playerEvents containsObject:event]) {
            return handler(event, labels);
        }
        else {
            return NO;
        }
    }];
}

- (XCTestExpectation *)expectationForComScoreHiddenEventNotificationWithHandler:(EventExpectationHandler)handler
{
    return [self expectationForSingleNotification:SRGAnalyticsComScoreRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        
        NSString *type = labels[@"ns_type"];
        if (! [type isEqualToString:@"hidden"]) {
            return NO;
        }
        
        // Discard heartbeats (hidden events, but entirely outside our control)
        NSString *event = labels[@"ns_st_ev"];
        if ([event isEqualToString:@"hb"]) {
            return NO;
        }
        
        // Discard app overlap measurements
        NSString *name = labels[@"srg_title"];
        if ([name isEqualToString:@"Installed Apps"]) {
            return NO;
        }
        
        return handler(event, labels);
    }];
}

- (XCTestExpectation *)expectationForComScorePlaybackEventNotificationWithHandler:(EventExpectationHandler)handler
{
    return [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        static dispatch_once_t s_onceToken;
        static NSArray<NSString *> *s_playerEvents;
        dispatch_once(&s_onceToken, ^{
            s_playerEvents = @[@"play", @"pause", @"end" ];
        });
        
        if ([s_playerEvents containsObject:event]) {
            return handler(event, labels);
        }
        else {
            return NO;
        }
    }];
}

- (XCTestExpectation *)expectationForElapsedTimeInterval:(NSTimeInterval)timeInterval withHandler:(void (^)(void))handler
{
    XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Wait for %@ seconds", @(timeInterval)]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
        handler ? handler() : nil;
    });
    return expectation;
}

@end
