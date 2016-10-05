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

static NSDictionary *startLabels = nil;

+ (void)load
{
	[[NSNotificationCenter defaultCenter] addObserverForName:SRGAnalyticsComScoreRequestNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *notification) {
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

- (void)testPresentViewControllerWithNoTitleSendsViewEvent
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
	NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil];
	NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
	
	XCTAssertEqualObjects(labels[@"name"], @"app.untitled");
	XCTAssertEqualObjects(labels[@"category"], @"app");
	XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
	XCTAssertEqualObjects(labels[@"srg_n1"], @"app");
	XCTAssertEqualObjects(labels[@"srg_title"], @"untitled");
	XCTAssertEqualObjects(labels[@"ns_type"], @"view");
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester waitForTimeInterval:2.0f];
}

- (void)testPresentViewControllerWithNoTitleSendsViewEventNetmetrix
{
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
    NSNotification *notification = [system waitForNotificationName:SRGAnalyticsNetmetrixRequestNotification object:nil];
    NSURL *urlKey = notification.userInfo[SRGAnalyticsNetmetrixURLKey];
    BOOL containAppName =[urlKey.absoluteString containsString:@"/apps/test/ios/"];
    
    XCTAssertNotNil(urlKey);
    XCTAssertTrue(containAppName);
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester waitForTimeInterval:2.0f];
}

- (void) testPresentViewControllerWithTitleViewEvent
{
	[tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
	NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil];
	NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
	
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
	
	NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil];
	NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
	
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
	
	NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil];
	NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
	
	XCTAssertEqualObjects(labels[@"name"], @"tv.n1.n2.title");
	
	[tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester waitForTimeInterval:2.0f];
}

- (void)testPresentViewControllerWithWithManualTrackingEvent
{
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0] inTableViewWithAccessibilityIdentifier:@"tableView"];
    
    NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil];
    NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
    
    XCTAssertEqualObjects(labels[@"name"], @"app.manual-tracking");
    XCTAssertEqualObjects(labels[@"srg_ap_push"], @"0");
    XCTAssertEqualObjects(labels[@"srg_n1"], @"app");
    XCTAssertNotEqualObjects(labels[@"srg_title"], @"Title");
    XCTAssertEqualObjects(labels[@"srg_title"], @"Manual tracking");
    
    ;    XCTAssertEqualObjects(labels[@"ns_type"], @"view");
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester waitForTimeInterval:2.0f];
}

// FIXME: Fix race condition with code in +load. This is the first test executed and it will fail because the start event is
//        received here first
- (void) testHiddenEventWithNoTitle
{
    NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil whileExecutingBlock:^{
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
    }];
    
    NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
    XCTAssertEqualObjects(labels[@"srg_title"], @"untitled");
    XCTAssertEqualObjects(labels[@"ns_type"], @"hidden");
    
    [tester waitForTimeInterval:2.0f];
}

- (void) testHiddenEventWithTitle
{
    NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil whileExecutingBlock:^{
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
    }];
    
    NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
    XCTAssertEqualObjects(labels[@"srg_title"], @"Title");
    XCTAssertEqualObjects(labels[@"ns_type"], @"hidden");
    
    [tester waitForTimeInterval:2.0f];
}

- (void) testHiddenEventWithTitleAndCustomLabels
{
    NSNotification *notification = [system waitForNotificationName:SRGAnalyticsComScoreRequestNotification object:nil whileExecutingBlock:^{
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1] inTableViewWithAccessibilityIdentifier:@"tableView"];
    }];
    
    NSDictionary *labels = notification.userInfo[SRGAnalyticsComScoreLabelsKey];
    XCTAssertEqualObjects(labels[@"srg_title"], @"Title");
    XCTAssertEqualObjects(labels[@"ns_type"], @"hidden");
    XCTAssertEqualObjects(labels[@"srg_ap_cu"], @"custom");
    
    [tester waitForTimeInterval:2.0f];
}

@end
