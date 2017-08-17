//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsTestCase.h"

#import <SRGAnalytics/SRGAnalytics.h>

@implementation AnalyticsTestCase

#pragma mark Helpers

- (XCTestExpectation *)expectationForHiddenEventNotificationWithHandler:(EventExpectationHandler)handler
{
    return [self expectationForNotification:SRGAnalyticsRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *event = labels[@"event_id"];
        if ([event isEqualToString:@"screen"]) {
            return NO;
        }
        
        return handler(event, labels);
    }];
}

- (XCTestExpectation *)expectationForHiddenPlaybackEventNotificationWithHandler:(EventExpectationHandler)handler
{
    return [self expectationForNotification:SRGAnalyticsRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        static dispatch_once_t s_onceToken;
        static NSArray<NSString *> *s_playerSingleHiddenEvents;
        dispatch_once(&s_onceToken, ^{
            s_playerSingleHiddenEvents = @[@"play", @"pause", @"seek", @"stop", @"eof"];
        });
        
        NSString *event = labels[@"event_id"];
        if ([s_playerSingleHiddenEvents containsObject:event]) {
            return handler(event, labels);
        }
        else {
            return NO;
        }
    }];
}

- (XCTestExpectation *)expectationForComScoreHiddenEventNotificationWithHandler:(EventExpectationHandler)handler
{
    return [self expectationForNotification:SRGAnalyticsComScoreRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        
        NSString *type = labels[@"ns_type"];
        if (! [type isEqualToString:@"hidden"]) {
            return NO;
        }
        
        // Discard heartbeats (though hidden events, they are outside our control)
        NSString *event = labels[@"ns_st_ev"];
        if ([event isEqualToString:@"hb"]) {
            return NO;
        }
        
        return handler(event, labels);
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
