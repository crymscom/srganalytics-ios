//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>

@interface SRGAnalytics_Demo_3_PushNotificationTests : KIFTestCase

@end

@implementation SRGAnalytics_Demo_3_PushNotificationTests

- (void)setUp
{
    [super setUp];
    
    [KIFSystemTestActor setDefaultTimeout:30.0];
}

- (void)testViewControllerPresentedFromPushSendsViewEventWithValidTag
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil];
	NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
	XCTAssertEqualObjects(labels[@"srg_ap_push"], @"1");
    XCTAssertNotNil(labels[@"srg_test"]);
	
	[tester tapViewWithAccessibilityLabel:@"Done"];
    [tester waitForTimeInterval:2.0f];
}

- (void)testPresentAnotherViewControllerSendsViewEventWithValidTag
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil];
	NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
	XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
    XCTAssertNotNil(labels[@"srg_test"]);
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester waitForTimeInterval:2.0f];
}

@end
