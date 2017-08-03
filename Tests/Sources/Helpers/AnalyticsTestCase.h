//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGAnalytics/SRGAnalytics.h>
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^EventExpectationHandler)(NSString *event, NSDictionary *labels);

@interface AnalyticsTestCase : XCTestCase

/**
 *  Expectation for global TMS hidden event notifications
 */
- (XCTestExpectation *)expectationForHiddenEventNotificationWithHandler:(EventExpectationHandler)handler;

/**
 *  Expectation for global TMS Player single hidden event notifications (ie: play, pause, stop, eof)
 */
- (XCTestExpectation *)expectationForPlayerSingleHiddenEventNotificationWithHandler:(EventExpectationHandler)handler;

/**
 *  Expectation for global ComScore hidden event notifications
 */
- (XCTestExpectation *)expectationForComScoreHiddenEventNotificationWithHandler:(EventExpectationHandler)handler;

/**
 *  Expectation fulfilled after some given time interval (in seconds), calling the optionally provided handler. Can
 *  be useful for ensuring nothing unexpected occurs during some time
 */
- (XCTestExpectation *)expectationForElapsedTimeInterval:(NSTimeInterval)timeInterval withHandler:(nullable void (^)(void))handler;

@end

NS_ASSUME_NONNULL_END
