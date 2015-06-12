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

extern NSString * const RTSAnalyticsComScoreRequestDidFinishNotification;
extern NSString * const RTSAnalyticsComScoreRequestLabelsUserInfoKey;

@interface RTSAnalytics_Demo_3_PushNotificationTests : KIFTestCase

@end

@implementation RTSAnalytics_Demo_3_PushNotificationTests

- (void) test_1_ViewControllerPresentedFromPushSendsViewEventWithValidTag
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:RTSAnalyticsComScoreRequestDidFinishNotification object:nil];
	NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
	XCTAssertEqualObjects(labels[@"srg_ap_push"], @"1");
	
	[tester tapViewWithAccessibilityLabel:@"Done"];
}

- (void) test_2_PresentAnotherViewControllerSendsViewEventWithValidTag
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:RTSAnalyticsComScoreRequestDidFinishNotification object:nil];
	NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
	XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
}

@end
