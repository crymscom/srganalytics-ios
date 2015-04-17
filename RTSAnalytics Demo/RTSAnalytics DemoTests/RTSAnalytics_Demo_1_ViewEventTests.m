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

- (void) test_1_ApplicationStartsAndStartMeasurementAndFirstPageViewEventAreSend
{
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	XCTAssertEqualObjects(@"RTSAnalytics Demo iOS", startLabels[@"ns_ap_an"]);
	XCTAssertEqualObjects(@"mainsite",              startLabels[@"ns_site"]);
	XCTAssertEqualObjects(@"rts-app-test-v",        startLabels[@"ns_vsite"]);
	XCTAssertEqualObjects(@"RTS",                   startLabels[@"srg_unit"]);
	
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	XCTAssertEqualObjects(@"app.mainpagetitle", labels[@"name"]);
	XCTAssertEqualObjects(@"app",               labels[@"category"]);
	XCTAssertEqualObjects(@"0",                 labels[@"srg_ap_push"]);
	XCTAssertEqualObjects(@"app",               labels[@"srg_n1"]);
	XCTAssertEqualObjects(@"MainPageTitle",     labels[@"srg_title"]);
	XCTAssertEqualObjects(@"view",              labels[@"ns_type"]);
}


- (void) test_2_PresentViewControllerWithNoTitleSendsViewEvent
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	
	XCTAssertEqualObjects(@"app.untitled", labels[@"name"]);
	XCTAssertEqualObjects(@"app",          labels[@"category"]);
	XCTAssertEqualObjects(@"0",            labels[@"srg_ap_push"]);
	XCTAssertEqualObjects(@"app",          labels[@"srg_n1"]);
	XCTAssertEqualObjects(@"untitled",     labels[@"srg_title"]);
	XCTAssertEqualObjects(@"view",         labels[@"ns_type"]);
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
}

- (void) test_3_PresentViewControllerWithTitleViewEvent
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	
	XCTAssertEqualObjects(@"app.cest-un-titre-pour-levenement-", labels[@"name"]);
	XCTAssertEqualObjects(@"0",                                  labels[@"srg_ap_push"]);
	XCTAssertEqualObjects(@"app",                                labels[@"srg_n1"]);
	XCTAssertEqualObjects(@"C'est un titre pour l'événement !",  labels[@"srg_title"]);
	XCTAssertEqualObjects(@"view",                               labels[@"ns_type"]);
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
}

- (void) test_4_PresentViewControllerWithTitleAndLevelsSendsViewEvent
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	
	XCTAssertEqualObjects(@"tv.dautres-niveauxplus-loin.title", labels[@"name"]);
	XCTAssertEqualObjects(@"0",                                 labels[@"srg_ap_push"]);
	XCTAssertEqualObjects(@"tv",                                labels[@"srg_n1"]);
	XCTAssertEqualObjects(@"dautres-niveauxplus-loin",          labels[@"srg_n2"]);
	XCTAssertEqualObjects(@"tv.dautres-niveauxplus-loin",       labels[@"category"]);
	XCTAssertEqualObjects(@"Title",                             labels[@"srg_title"]);
	XCTAssertEqualObjects(@"view",                              labels[@"ns_type"]);
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
}

- (void) test_5_PresentViewControllerWithTitleLevelsAndCustomLabelsSendsViewEvent
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	
	XCTAssertEqualObjects(@"tv.n1.n2.title", labels[@"name"]);
	XCTAssertEqualObjects(@"0",              labels[@"srg_ap_push"]);
	XCTAssertEqualObjects(@"tv",             labels[@"srg_n1"]);
	XCTAssertEqualObjects(@"n1",             labels[@"srg_n2"]);
	XCTAssertEqualObjects(@"n2",             labels[@"srg_n3"]);
	XCTAssertEqualObjects(@"tv.n1.n2",       labels[@"category"]);
	XCTAssertEqualObjects(@"Title",          labels[@"srg_title"]);
	XCTAssertEqualObjects(@"view",           labels[@"ns_type"]);
	
	XCTAssertEqualObjects(@"custom",         labels[@"srg_ap_cu"]);
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
}


@end
