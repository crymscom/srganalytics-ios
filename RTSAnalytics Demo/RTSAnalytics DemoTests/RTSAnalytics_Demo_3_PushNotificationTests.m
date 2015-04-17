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

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) test_1_ViewControllerPresentedFromPushSendsViewEventWithValidTag
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	
	XCTAssertEqualObjects(@"app.title", labels[@"name"]);
	XCTAssertEqualObjects(@"1",         labels[@"srg_ap_push"]);
	XCTAssertEqualObjects(@"app",       labels[@"srg_n1"]);
	XCTAssertEqualObjects(@"Title",     labels[@"srg_title"]);
	XCTAssertEqualObjects(@"view",      labels[@"ns_type"]);
	
	[tester tapViewWithAccessibilityLabel:@"Done"];
}


- (void) test_2_PresentAnotherViewControllerSendsViewEventWithValidTag
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	
	XCTAssertEqualObjects(@"app.title", labels[@"name"]);
	XCTAssertEqualObjects(@"0",         labels[@"srg_ap_push"]);
	XCTAssertEqualObjects(@"app",       labels[@"srg_n1"]);
	XCTAssertEqualObjects(@"Title",     labels[@"srg_title"]);
	XCTAssertEqualObjects(@"view",      labels[@"ns_type"]);
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
}

@end
