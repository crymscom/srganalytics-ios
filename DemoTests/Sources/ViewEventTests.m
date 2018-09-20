//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <KIF/KIF.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <UIKit/UIKit.h>

typedef BOOL (^EventExpectationHandler)(NSString *event, NSDictionary *labels);

static NSDictionary *s_startLabels = nil;

@interface ViewEventTests : KIFTestCase

@end

@implementation ViewEventTests

#pragma mark Setup and tear down

- (void)setUp
{
    [super setUp];
    
    [KIFSystemTestActor setDefaultTimeout:60.0];
}

#pragma mark Helpers

- (XCTestExpectation *)expectationForViewEventNotificationWithHandler:(EventExpectationHandler)handler
{
    return [self expectationForNotification:SRGAnalyticsRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsLabelsKey];
        
        NSString *event = labels[@"event_id"];
        if (! [event isEqualToString:@"screen"]) {
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

#pragma mark Tests

// For all tests, use KIF only to control the UI and wait for UI responses. For tests and waiting on other conditions, use
// XCTest. While KIF provides similar functionalities, e.g. for waiting on notifications, expectations cannot be defined
// prior to some code being run (e.g. tapping a UI element). If the code being run triggers the notification, it is
// impossible to catch it with KIF. This is why the expectation - action - waiting model of XCTest is used instead

- (void)testAutomaticTracking
{
    [self expectationForViewEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"navigation_property_type"], @"app");
        XCTAssertEqualObjects(labels[@"accessed_after_push_notification"], @"false");
        XCTAssertEqualObjects(labels[@"navigation_bu_distributer"], @"RTS");
        XCTAssertEqualObjects(labels[@"content_title"], @"Automatic tracking");
        return YES;
    }];
    
    // Test NetMetrix notification as well. Not tested elsewhere since always the same
    [self expectationForNotification:SRGAnalyticsNetmetrixRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSURL *URL = notification.userInfo[SRGAnalyticsNetmetrixURLKey];
        XCTAssertTrue([URL.absoluteString containsString:@"/apps/test/ios/"]);
        return YES;
    }];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2.];
}

- (void)testAutomaticTrackingWithLevels
{
    [self expectationForViewEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"accessed_after_push_notification"], @"false");
        XCTAssertEqualObjects(labels[@"navigation_level_1"], @"Level1");
        XCTAssertEqualObjects(labels[@"navigation_level_2"], @"Level2");
        XCTAssertEqualObjects(labels[@"navigation_level_3"], @"Level3");
        XCTAssertNil(labels[@"navigation_level_4"]);
        XCTAssertEqualObjects(labels[@"content_title"], @"Automatic tracking with levels");
        return YES;
    }];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2.];
}

- (void)testMaximumNumberOfLevels
{
    // The SRG standard only has srg_nX fields up to 10. The full hierarchy is still obtained from the name and category labels, though
    [self expectationForViewEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"accessed_after_push_notification"], @"false");
        XCTAssertEqualObjects(labels[@"navigation_level_1"], @"Level1");
        XCTAssertEqualObjects(labels[@"navigation_level_2"], @"Level2");
        XCTAssertEqualObjects(labels[@"navigation_level_3"], @"Level3");
        XCTAssertEqualObjects(labels[@"navigation_level_4"], @"Level4");
        XCTAssertEqualObjects(labels[@"navigation_level_5"], @"Level5");
        XCTAssertEqualObjects(labels[@"navigation_level_6"], @"Level6");
        XCTAssertEqualObjects(labels[@"navigation_level_7"], @"Level7");
        XCTAssertEqualObjects(labels[@"navigation_level_8"], @"Level8");
        XCTAssertNil(labels[@"navigation_level_9"]);
        XCTAssertNil(labels[@"navigation_level_10"]);
        XCTAssertNil(labels[@"navigation_level_11"]);
        XCTAssertEqualObjects(labels[@"content_title"], @"Automatic tracking with many levels");
        return YES;
    }];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2.];
}

- (void)testAutomaticTrackingWithLevelsAndLabels
{
    [self expectationForViewEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"accessed_after_push_notification"], @"false");
        XCTAssertEqualObjects(labels[@"navigation_level_1"], @"Level1");
        XCTAssertEqualObjects(labels[@"navigation_level_2"], @"Level2");
        XCTAssertNil(labels[@"navigation_level_3"]);
        XCTAssertEqualObjects(labels[@"content_title"], @"Automatic tracking with levels and labels");
        XCTAssertEqualObjects(labels[@"custom_label"], @"custom_value");
        return YES;
    }];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2.];
}

- (void)testManualTracking
{
    [self expectationForViewEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"accessed_after_push_notification"], @"false");
        XCTAssertEqualObjects(labels[@"navigation_property_type"], @"app");
        XCTAssertEqualObjects(labels[@"content_title"], @"Manual tracking");
        return YES;
    }];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Track"];
    [tester tapViewWithAccessibilityLabel:@"Track"];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2.];
}

- (void)testMissingTitle
{
    id eventObserver = [NSNotificationCenter.defaultCenter addObserverForName:SRGAnalyticsRequestNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        XCTFail(@"No event must be sent when the title is empty");
    }];
    
    [self expectationForElapsedTimeInterval:3. withHandler:nil];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
    [self waitForExpectationsWithTimeout:5. handler:^(NSError * _Nullable error) {
        [NSNotificationCenter.defaultCenter removeObserver:eventObserver];
    }];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2.];
}

- (void)testFromPushNotification
{
    [self expectationForViewEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"accessed_after_push_notification"], @"true");
        return YES;
    }];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2.];
}

@end
