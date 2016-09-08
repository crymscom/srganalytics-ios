//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^HiddenEventExpectationHandler)(NSString *event, NSDictionary *labels);

@interface AnalyticsTestCase : XCTestCase

// Expectation for global hidden event notifications (player notifications are all event notifications, we don't want to have a look
// at view events here)
- (XCTestExpectation *)expectationForHiddenEventNotificationWithHandler:(HiddenEventExpectationHandler)handler;

@end

NS_ASSUME_NONNULL_END
