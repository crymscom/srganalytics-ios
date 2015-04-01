//
//  RTSAnalyticsTrackerConfigTest.m
//  RTSAnalytics
//
//  Created by Cédric Foellmi on 01/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "RTSAnalyticsTrackerConfig.h"

@interface RTSAnalyticsTrackerConfigTest : XCTestCase

@end

@implementation RTSAnalyticsTrackerConfigTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testConfigAppName
{
    RTSAnalyticsTrackerConfig *config = [RTSAnalyticsTrackerConfig configWithBusinessUnit:@"rts"
                                                                      comScoreVirtualSite:@"cc_vsite"
                                                                   streamSenseVirtualSite:@"ss_vsite"];
    
    XCTAssertNotNil([config appName], @"App name must be nil");
}

- (void)testConfigAppVersion
{
    RTSAnalyticsTrackerConfig *config = [RTSAnalyticsTrackerConfig configWithBusinessUnit:@"rts"
                                                                      comScoreVirtualSite:@"cc_vsite"
                                                                   streamSenseVirtualSite:@"ss_vsite"];
    
    XCTAssertNotNil([config version], @"Version must be nil");
}

- (void)testComScoreGlobalLabelKeys
{
    RTSAnalyticsTrackerConfig *config = [RTSAnalyticsTrackerConfig configWithBusinessUnit:@"rts"
                                                                      comScoreVirtualSite:@"cc_vsite"
                                                                   streamSenseVirtualSite:@"ss_vsite"];
    
    NSSet *keys = [NSSet setWithArray:[[config comScoreGlobalLabels] allKeys]];
    NSSet *expectedKeys = [NSSet setWithArray:@[@"ns_ap_an", @"ns_ap_ver", @"srg_unit", @"srg_ap_push", @"ns_site", @"ns_vsite"]];
    
    XCTAssertEqualObjects(keys, expectedKeys, @"Wrong list of comScore global label keys");
}

@end
