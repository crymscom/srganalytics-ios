//
//  RTSAnalytics_DemoTests.m
//  RTSAnalytics DemoTests
//
//  Created by Frédéric Humbert-Droz on 17/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import <RTSAnalytics/RTSAnalytics.h>

@interface RTSAnalytics_Demo_1_ViewEventTests : KIFTestCase

@end

@implementation RTSAnalytics_Demo_1_ViewEventTests

static NSDictionary *startLabels = nil;

+(void) load
{
	[[NSNotificationCenter defaultCenter] addObserverForName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil queue:nil usingBlock:^(NSNotification *notification)
	{
		NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
		if ([labels[@"ns_ap_ev"] isEqualToString:@"start"]) {
			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				startLabels  = labels;
			});
		}
	}];
}

- (void) setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void) tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) test_1_ApplicationStartsAndStartMeasurementAndFirstPageViewEventAreSend
{
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	
	XCTAssertEqualObjects(@"RTSAnalytics Demo iOS", startLabels[@"ns_ap_an"]);
	XCTAssertEqualObjects(@"mainsite",              startLabels[@"ns_site"]);
	XCTAssertEqualObjects(@"rts-app-test-v",        startLabels[@"ns_vsite"]);
	XCTAssertEqualObjects(@"RTS",                   startLabels[@"srg_unit"]);
	
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	XCTAssertEqualObjects(@"app.mainpagetitle", labels[@"name"]);
	XCTAssertEqualObjects(@"0",                 labels[@"srg_ap_push"]);
	XCTAssertEqualObjects(@"app",               labels[@"srg_n1"]);
	XCTAssertEqualObjects(@"MainPageTitle",     labels[@"srg_title"]);
	XCTAssertEqualObjects(@"view",              labels[@"ns_type"]);
}


- (void) test_2_PresentViewControllerSendsViewEvent
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	
	XCTAssertEqualObjects(@"app.title", labels[@"name"]);
	XCTAssertEqualObjects(@"0",			labels[@"srg_ap_push"]);
	XCTAssertEqualObjects(@"app",       labels[@"srg_n1"]);
	XCTAssertEqualObjects(@"Title",     labels[@"srg_title"]);
	XCTAssertEqualObjects(@"view",      labels[@"ns_type"]);
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
}


@end
