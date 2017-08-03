//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsTestCase.h"
#import "NSNotificationCenter+Tests.h"

typedef BOOL (^EventExpectationHandler)(NSString *type, NSDictionary *labels);

@interface ComScoreTrackerTestCase : AnalyticsTestCase

@end

@implementation ComScoreTrackerTestCase

#pragma mark Tests

- (void)testComScoreHiddenEvent
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertNil(type);
        XCTAssertEqualObjects(labels[@"srg_title"], @"Hidden event");
        XCTAssertEqualObjects(labels[@"name"], @"app.hidden-event");
        XCTAssertEqualObjects(labels[@"category"], @"app");
        return YES;
    }];
    
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"Hidden event"];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testComScoreHiddenEventWithLabels
{
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertNil(type);
        XCTAssertEqualObjects(labels[@"srg_title"], @"Hidden event");
        XCTAssertEqualObjects(labels[@"name"], @"app.hidden-event");
        XCTAssertEqualObjects(labels[@"category"], @"app");
        XCTAssertEqualObjects(labels[@"custom_label"], @"custom_value");
        return YES;
    }];
    
    SRGAnalyticsHiddenEventLabels *labels = [[SRGAnalyticsHiddenEventLabels alloc] init];
    labels.comScoreValues = @{ @"custom_label" : @"custom_value" };
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@"Hidden event"
                                                            labels:labels];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testComScoreHiddenEventWithEmptyTitle
{
    id eventObserver = [[NSNotificationCenter defaultCenter] addObserverForComScoreHiddenEventNotificationUsingBlock:^(NSString * _Nonnull event, NSDictionary * _Nonnull labels) {
        XCTFail(@"Events with missing title must not be sent");
    }];
    
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    
    [[SRGAnalyticsTracker sharedTracker] trackHiddenEventWithTitle:@""];
    
    [self waitForExpectationsWithTimeout:5. handler:^(NSError * _Nullable error) {
        [[NSNotificationCenter defaultCenter] removeObserver:eventObserver];
    }];
}

@end
