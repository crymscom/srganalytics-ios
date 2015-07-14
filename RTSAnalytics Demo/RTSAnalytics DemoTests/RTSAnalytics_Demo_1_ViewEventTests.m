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
#import <SRGAnalytics/SRGAnalytics.h>

@interface RTSAnalytics_Demo_1_ViewEventTests : KIFTestCase

@end

@implementation RTSAnalytics_Demo_1_ViewEventTests

static NSDictionary *startLabels = nil;

+ (void)load
{
	[[NSNotificationCenter defaultCenter] addObserverForName:@"RTSAnalyticsComScoreRequestDidFinish"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *notification) {
                                                      NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
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
- (void)testAAAAAApplicationStartsAndStartMeasurementAndFirstPageViewEventAreSend
{
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	XCTAssertEqualObjects(startLabels[@"ns_ap_an"], @"SRGAnalytics Demo iOS");
	XCTAssertEqualObjects(startLabels[@"ns_site"], @"mainsite");
	XCTAssertEqualObjects(startLabels[@"ns_vsite"], @"rts-app-test-v");
	XCTAssertEqualObjects(startLabels[@"srg_unit"], @"RTS");
	
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	XCTAssertEqualObjects(labels[@"name"], @"app.mainpagetitle");
	XCTAssertEqualObjects(labels[@"category"], @"app");
	XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
	XCTAssertEqualObjects(labels[@"srg_n1"], @"app");
	XCTAssertEqualObjects(labels[@"srg_title"], @"MainPageTitle");
	XCTAssertEqualObjects(labels[@"ns_type"], @"view");
    
    [tester waitForTimeInterval:2.0f];
}

- (void)testPresentViewControllerWithNoTitleSendsViewEvent
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	
	XCTAssertEqualObjects(labels[@"name"], @"app.untitled");
	XCTAssertEqualObjects(labels[@"category"], @"app");
	XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
	XCTAssertEqualObjects(labels[@"srg_n1"], @"app");
	XCTAssertEqualObjects(labels[@"srg_title"], @"untitled");
	XCTAssertEqualObjects(labels[@"ns_type"], @"view");
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester waitForTimeInterval:2.0f];
}

- (void) testPresentViewControllerWithTitleViewEvent
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	
	XCTAssertEqualObjects(labels[@"name"], @"app.cest-un-titre-pour-levenement-");
	XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
	XCTAssertEqualObjects(labels[@"srg_n1"], @"app");
	XCTAssertEqualObjects(labels[@"srg_title"], @"C'est un titre pour l'événement !");
	XCTAssertEqualObjects(labels[@"ns_type"], @"view");
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester waitForTimeInterval:2.0f];
}

- (void) testPresentViewControllerWithTitleAndLevelsSendsViewEvent
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	
	XCTAssertEqualObjects(labels[@"name"], @"tv.dautres-niveauxplus-loin.title");
	XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
	XCTAssertEqualObjects(labels[@"srg_n1"], @"tv");
	XCTAssertEqualObjects(labels[@"srg_n2"], @"dautres-niveauxplus-loin");
	XCTAssertEqualObjects(labels[@"category"], @"tv.dautres-niveauxplus-loin");
	XCTAssertEqualObjects(labels[@"srg_title"], @"Title");
	XCTAssertEqualObjects(labels[@"ns_type"], @"view");
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester waitForTimeInterval:2.0f];
}

- (void) testPresentViewControllerWithTitleLevelsAndCustomLabelsSendsViewEvent
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
	
	NSNotification *notification = [system waitForNotificationName:@"RTSAnalyticsComScoreRequestDidFinish" object:nil];
	NSDictionary *labels = notification.userInfo[@"RTSAnalyticsLabels"];
	
	XCTAssertEqualObjects(labels[@"name"], @"tv.n1.n2.title");
	XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
	XCTAssertEqualObjects(labels[@"srg_n1"], @"tv");
	XCTAssertEqualObjects(labels[@"srg_n2"], @"n1");
	XCTAssertEqualObjects(labels[@"srg_n3"], @"n2");
	XCTAssertEqualObjects(labels[@"category"], @"tv.n1.n2");
	XCTAssertEqualObjects(labels[@"srg_title"], @"Title");
	XCTAssertEqualObjects(labels[@"ns_type"], @"view");
	XCTAssertEqualObjects(labels[@"srg_ap_cu"], @"custom");
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester waitForTimeInterval:2.0f];
}

@end
