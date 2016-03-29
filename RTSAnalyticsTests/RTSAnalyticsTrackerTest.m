//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import <SRGMediaPlayer/SRGMediaPlayer.h>
#import <ComScore-iOS/CSComScore.h>

#import "RTSAnalyticsTracker.h"
#import "RTSAnalyticsMediaPlayerDataSource.h"

@interface RTSAnalyticsTrackerTest : XCTestCase
@property(nonatomic, strong) id<RTSAnalyticsMediaPlayerDataSource> dataSourceMock;
@end

@implementation RTSAnalyticsTrackerTest

- (void)setUp
{
    [super setUp];
    
    self.dataSourceMock = OCMProtocolMock(@protocol(RTSAnalyticsMediaPlayerDataSource));
}

- (void)tearDown
{
    self.dataSourceMock = nil;
    [super tearDown];
}

// Making sure with AAAAA that this method is called first.
- (void)testAAAAATrackerValidSetup
{
    id comScoreClassMock = OCMClassMock([CSComScore class]);
    
    // Also check that when we have multiple trackers, the setup is done only once for comScore.
	[[RTSAnalyticsTracker sharedTracker] startTrackingForBusinessUnit:SSRBusinessUnitRTS
                                                      mediaDataSource:self.dataSourceMock];
	
    OCMVerify([comScoreClassMock setCustomerC2:[OCMArg isNotNil]]);
    OCMVerify([comScoreClassMock setPublisherSecret:[OCMArg isNotNil]]);
    OCMVerify([comScoreClassMock setAppContext]);

    id checkBlock = ^BOOL(id obj) {
        if (![obj isKindOfClass:[NSDictionary class]]) {
            return NO;
        }
        
        NSDictionary *labels = (NSDictionary *)obj;
        NSArray *keys = @[@"ns_ap_an", @"ns_ap_lang", @"ns_ap_ver", @"srg_unit", @"srg_ap_push", @"ns_site", @"ns_vsite"];
        
        if ([labels count] != [keys count]) {
            return NO;
        }
        
        for (NSString *key in keys) {
            if ([labels objectForKey:key] == nil) {
                return NO;
            }
        }
        
        return YES;
    };
    
    OCMVerify([comScoreClassMock setLabels:[OCMArg checkWithBlock:checkBlock]]);
    [comScoreClassMock stopMocking];
}

@end
