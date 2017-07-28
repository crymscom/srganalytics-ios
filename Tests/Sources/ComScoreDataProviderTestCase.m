//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsTestCase.h"

#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>

static NSURL *ServiceTestURL(void)
{
    return [NSURL URLWithString:@"http://il-test.srgssr.ch"];
}

@interface ComScoreDataProviderTestCase : AnalyticsTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation ComScoreDataProviderTestCase

#pragma mark Setup and teardown

- (void)setUp
{
    self.mediaPlayerController = [[SRGMediaPlayerController alloc] init];
    self.mediaPlayerController.liveTolerance = 10.;
}

- (void)tearDown
{
    [self.mediaPlayerController reset];
    self.mediaPlayerController = nil;
}

#pragma mark Tests

- (void)testComScorePrepareToPlayMediaComposition
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider videoMediaCompositionWithUid:@"42297626" completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone quality:SRGQualityHD startBitRate:0 userInfo:nil resume:YES completionHandler:^(NSError * _Nonnull error) {
            XCTAssertNil(error);
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    
    // Start playback and check labels
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ep"], @"Archive footage of the man and his moods");
        XCTAssertEqualObjects(labels[@"srg_mqual"], @"HD");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testComScorePlayMediaComposition
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider videoMediaCompositionWithUid:@"42297626" completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone quality:SRGQualityHD startBitRate:0 userInfo:nil resume:YES completionHandler:^(NSError * _Nonnull error) {
            XCTAssertNil(error);
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
}

- (void)testComScorePlaySegmentInMediaComposition
{
    // Use a segment id as video id, expect segment labels
    [self expectationForComScoreHiddenEventNotificationWithHandler:^BOOL(NSString *type, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"ns_st_ev"], @"play");
        XCTAssertEqualObjects(labels[@"ns_st_ep"], @"«26 minutes» – web first: Welsche Satire auf Hochdeutsch!");
        XCTAssertEqualObjects(labels[@"srg_mqual"], @"HD");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSRF];
    [[dataProvider videoMediaCompositionWithUid:@"99ac4dd4-8cd4-4883-8c80-0373d37cf0ad" completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone quality:SRGQualityHD startBitRate:0 userInfo:nil resume:YES completionHandler:^(NSError * _Nonnull error) {
            XCTAssertNil(error);
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

@end
