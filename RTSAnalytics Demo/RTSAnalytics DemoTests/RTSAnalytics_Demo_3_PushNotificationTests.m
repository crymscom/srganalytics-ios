//
//  RTSAnalytics_Demo_3_PushNotificationTests.m
//  RTSAnalytics Demo
//
//  Created by Frédéric Humbert-Droz on 17/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>

@interface RTSAnalytics_Demo_3_PushNotificationTests : KIFTestCase

@end

@implementation RTSAnalytics_Demo_3_PushNotificationTests

- (void)setUp
{
    [super setUp];
    [KIFSystemTestActor setDefaultTimeout:30.0];
}

- (void)testViewControllerPresentedFromPushSendsViewEventWithValidTag
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	XCTAssertEqualObjects(labels[@"srg_ap_push"], @"1");
	
	[tester tapViewWithAccessibilityLabel:@"Done"];
    [tester waitForTimeInterval:2.0f];
}

- (void)testPresentAnotherViewControllerSendsViewEventWithValidTag
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester waitForTimeInterval:2.0f];
}

@end
