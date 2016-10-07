//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import <SRGAnalytics/SRGAnalytics.h>

typedef BOOL (^EventExpectationHandler)(NSString *type, NSDictionary *labels);

static NSDictionary *s_startLabels = nil;

@interface SRGAnalytics_Demo_1_EventTests : KIFTestCase

@end

@implementation SRGAnalytics_Demo_1_EventTests

#pragma mark Setup and tear down

- (void)setUp
{
    [super setUp];
    
    [KIFSystemTestActor setDefaultTimeout:60.0];
}

#pragma mark Helpers

- (XCTestExpectation *)expectationForViewEventNotificationWithHandler:(EventExpectationHandler)handler
{
    return [self expectationForNotification:SRGAnalyticsComScoreRequestNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        
        NSString *type = labels[@"ns_type"];
        if (! [type isEqualToString:@"view"]) {
            return NO;
        }
        
        // Discard start events (outside our control)
        NSString *event = labels[@"ns_ap_ev"];
        if ([event isEqualToString:@"start"]) {
            return NO;
        }
        
        return handler(event, labels);
    }];
}

#pragma mark Tests

// For all tests, use KIF only to control the UI and wait for UI responses. For tests and waiting on other conditions, use
// XCTest. While KIF provides similar functionalities, e.g. for waiting on notifications, expectations cannot be defined
// prior to some code being run (e.g. tapping a UI element). If the code being run triggers the notification, it is
// impossible to catch it with KIF. This is why the expectation - action - waiting model of XCTest is used instead

- (void)testAutomaticTracking
{
    [self expectationForViewEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"name"], @"app.automatic-tracking");
        XCTAssertEqualObjects(labels[@"category"], @"app");
        XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
        XCTAssertEqualObjects(labels[@"srg_n1"], @"app");
        XCTAssertNil(labels[@"srg_n2"]);
        XCTAssertEqualObjects(labels[@"srg_title"], @"Automatic tracking");
        XCTAssertEqualObjects(labels[@"ns_type"], @"view");
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
    [self expectationForViewEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"name"], @"level1.level2.level3.automatic-tracking-with-levels");
        XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
        XCTAssertEqualObjects(labels[@"srg_n1"], @"level1");
        XCTAssertEqualObjects(labels[@"srg_n2"], @"level2");
        XCTAssertEqualObjects(labels[@"srg_n3"], @"level3");
        XCTAssertNil(labels[@"srg_n4"]);
        XCTAssertEqualObjects(labels[@"category"], @"level1.level2.level3");
        XCTAssertEqualObjects(labels[@"srg_title"], @"Automatic tracking with levels");
        XCTAssertEqualObjects(labels[@"ns_type"], @"view");
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
    [self expectationForViewEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"name"], @"level1.level2.level3.level4.level5.level6.level7.level8.level9.level10.level11.level12.automatic-tracking-with-many-levels");
        XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
        XCTAssertEqualObjects(labels[@"srg_n1"], @"level1");
        XCTAssertEqualObjects(labels[@"srg_n2"], @"level2");
        XCTAssertEqualObjects(labels[@"srg_n3"], @"level3");
        XCTAssertEqualObjects(labels[@"srg_n4"], @"level4");
        XCTAssertEqualObjects(labels[@"srg_n5"], @"level5");
        XCTAssertEqualObjects(labels[@"srg_n6"], @"level6");
        XCTAssertEqualObjects(labels[@"srg_n7"], @"level7");
        XCTAssertEqualObjects(labels[@"srg_n8"], @"level8");
        XCTAssertEqualObjects(labels[@"srg_n9"], @"level9");
        XCTAssertEqualObjects(labels[@"srg_n10"], @"level10");
        XCTAssertNil(labels[@"srg_n11"]);
        XCTAssertEqualObjects(labels[@"category"], @"level1.level2.level3.level4.level5.level6.level7.level8.level9.level10.level11.level12");
        XCTAssertEqualObjects(labels[@"srg_title"], @"Automatic tracking with many levels");
        XCTAssertEqualObjects(labels[@"ns_type"], @"view");
        return YES;
    }];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2.];
}

- (void)testAutomaticTrackingWithLevelsAndCustomLabels
{
    [self expectationForViewEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"name"], @"level1.level2.automatic-tracking-with-levels-and-custom-labels");
        XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
        XCTAssertEqualObjects(labels[@"srg_n1"], @"level1");
        XCTAssertEqualObjects(labels[@"srg_n2"], @"level2");
        XCTAssertNil(labels[@"srg_n3"]);
        XCTAssertEqualObjects(labels[@"category"], @"level1.level2");
        XCTAssertEqualObjects(labels[@"srg_title"], @"Automatic tracking with levels and custom labels");
        XCTAssertEqualObjects(labels[@"ns_type"], @"view");
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
    [self expectationForViewEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"name"], @"app.manual-tracking");
        XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
        XCTAssertEqualObjects(labels[@"srg_n1"], @"app");
        XCTAssertNil(labels[@"srg_n2"]);
        XCTAssertEqualObjects(labels[@"category"], @"app");
        XCTAssertEqualObjects(labels[@"srg_title"], @"Manual tracking");
        XCTAssertEqualObjects(labels[@"ns_type"], @"view");
        return YES;
    }];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Track"];
    [tester tapViewWithAccessibilityLabel:@"Track"];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2.];
}

- (void)testFromPushNotification
{
    [self expectationForViewEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"srg_ap_push"], @"1");
        XCTAssertNotNil(labels[@"srg_test"]);
        return YES;
    }];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
    [self waitForExpectationsWithTimeout:5. handler:nil];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2.];
}

@end
