//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsTestCase.h"
#import "NSNotificationCenter+Tests.h"

typedef BOOL (^EventExpectationHandler)(NSString *type, NSDictionary *labels);

@interface TrackerTestCase : AnalyticsTestCase

@end

@implementation TrackerTestCase

#pragma mark Tests

- (void)testHiddenEvent
{
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertNil(type);
        XCTAssertEqualObjects(labels[@"srg_title"], @"Hidden event");
        XCTAssertEqualObjects(labels[@"name"], @"app.Hidden event");
        XCTAssertEqualObjects(labels[@"category"], @"app");
        return YES;
    }];
    
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testHiddenEventWithCustomLabels
{
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertNil(type);
        XCTAssertEqualObjects(labels[@"srg_title"], @"Hidden event");
        XCTAssertEqualObjects(labels[@"name"], @"app.Hidden event");
        XCTAssertEqualObjects(labels[@"category"], @"app");
        XCTAssertEqualObjects(labels[@"custom_label"], @"custom_value");
        return YES;
    }];
    
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"Hidden event" customLabels:@{ @"custom_label" : @"custom_value" }];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testHiddenEventWithEmptyTitle
{
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"Events with missing title must not be sent");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"" customLabels:nil];
    
    [self waitForExpectationsWithTimeout:5. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

@end
