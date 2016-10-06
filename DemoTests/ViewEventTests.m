//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import <SRGAnalytics/SRGAnalytics.h>

@interface SRGAnalytics_Demo_1_EventTests : KIFTestCase

@end

@implementation SRGAnalytics_Demo_1_EventTests

static NSDictionary * startLabels = nil;

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserverForName:SRGAnalyticsComScoreRequestNotification object:nil queue:nil usingBlock:^(NSNotification *notification) {
        NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
        if ([labels[@"ns_ap_ev"] isEqualToString:@"start"]) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                startLabels = [labels copy];
            });
        }
    }];
}

- (void)setUp
{
    [super setUp];
    [KIFSystemTestActor setDefaultTimeout:60.0];
}

// Making sure with AAAAA that this method is called first.
//#warning This test is subject to severe race condition issues. Disable temporarily
//- (void)disabled_testAAAAAApplicationStartAndStartMeasurementAndFirstPageViewEventAreSend
//{
//	NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil];
//	XCTAssertEqualObjects(startLabels[@"ns_ap_an"], @"SRGAnalytics Demo iOS");
//	XCTAssertEqualObjects(startLabels[@"ns_site"], @"mainsite");
//	XCTAssertEqualObjects(startLabels[@"ns_vsite"], @"SRG-app-test-v");
//	XCTAssertEqualObjects(startLabels[@"srg_unit"], @"SRG");
//
//	NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
//	XCTAssertEqualObjects(labels[@"name"], @"app.mainpagetitle");
//	XCTAssertEqualObjects(labels[@"category"], @"app");
//	XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
//	XCTAssertEqualObjects(labels[@"srg_n1"], @"app");
//	XCTAssertEqualObjects(labels[@"srg_title"], @"MainPageTitle");
//	XCTAssertEqualObjects(labels[@"ns_type"], @"view");
//
//    [tester waitForTimeInterval:2.0f];
//}

- (void)testAutomaticTrackingComScore
{
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];

    NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil];
    NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];

    XCTAssertEqualObjects(labels[@"name"], @"app.automatic-tracking");
    XCTAssertEqualObjects(labels[@"category"], @"app");
    XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
    XCTAssertEqualObjects(labels[@"srg_n1"], @"app");
    XCTAssertNil(labels[@"srg_n2"]);
    XCTAssertEqualObjects(labels[@"srg_title"], @"Automatic tracking");
    XCTAssertEqualObjects(labels[@"ns_type"], @"view");

    [tester tapViewWithAccessibilityLabel:@"Back"];

    [tester waitForTimeInterval:2.];
}

- (void)testAutomaticTrackingNetmetrix
{
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];

    NSNotification *notification = [system waitForNotificationName:SRGAnalyticsNetmetrixRequestNotification object:nil];
    NSURL *urlKey = notification.userInfo[SRGAnalyticsNetmetrixURLKey];
    BOOL containAppName = [urlKey.absoluteString containsString:@"/apps/test/ios/"];

    XCTAssertNotNil(urlKey);
    XCTAssertTrue(containAppName);

    [tester tapViewWithAccessibilityLabel:@"Back"];

    [tester waitForTimeInterval:2.];
}

- (void)testAutomaticTrackingWithLevelsComScore
{
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];

    NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil];
    NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];

    XCTAssertEqualObjects(labels[@"name"], @"level1.level2.level3.automatic-tracking-with-levels");
    XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
    XCTAssertEqualObjects(labels[@"srg_n1"], @"level1");
    XCTAssertEqualObjects(labels[@"srg_n2"], @"level2");
    XCTAssertEqualObjects(labels[@"srg_n3"], @"level3");
    XCTAssertNil(labels[@"srg_n4"]);
    XCTAssertEqualObjects(labels[@"category"], @"level1.level2.level3");
    XCTAssertEqualObjects(labels[@"srg_title"], @"Automatic tracking with levels");
    XCTAssertEqualObjects(labels[@"ns_type"], @"view");

    [tester tapViewWithAccessibilityLabel:@"Back"];

    [tester waitForTimeInterval:2.];
}

- (void)testAutomaticTrackingWithLevelsAndCustomLabelsComScore
{
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];

    NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil];
    NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];

    XCTAssertEqualObjects(labels[@"name"], @"level1.level2.automatic-tracking-with-levels-and-custom-labels");
    XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
    XCTAssertEqualObjects(labels[@"srg_n1"], @"level1");
    XCTAssertEqualObjects(labels[@"srg_n2"], @"level2");
    XCTAssertNil(labels[@"srg_n3"]);
    XCTAssertEqualObjects(labels[@"category"], @"level1.level2");
    XCTAssertEqualObjects(labels[@"srg_title"], @"Automatic tracking with levels and custom labels");
    XCTAssertEqualObjects(labels[@"ns_type"], @"view");
    XCTAssertEqualObjects(labels[@"custom_label"], @"custom_value");

    [tester tapViewWithAccessibilityLabel:@"Back"];

    [tester waitForTimeInterval:2.];
}

- (void)testManualTrackingComScore
{
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Track"];
    [tester tapViewWithAccessibilityLabel:@"Track"];

    NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil];
    NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];

    XCTAssertEqualObjects(labels[@"name"], @"app.manual-tracking");
    XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
    XCTAssertEqualObjects(labels[@"srg_n1"], @"app");
    XCTAssertNil(labels[@"srg_n2"]);
    XCTAssertEqualObjects(labels[@"category"], @"app");
    XCTAssertEqualObjects(labels[@"srg_title"], @"Manual tracking");
    XCTAssertEqualObjects(labels[@"ns_type"], @"view");

    [tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester waitForTimeInterval:2.];
}

@end
