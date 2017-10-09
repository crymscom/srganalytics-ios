//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsTestCase.h"

#import <SRGAnalytics_DataProvider/SRGAnalytics_DataProvider.h>

static NSURL *ServiceTestURL(void)
{
    return [NSURL URLWithString:@"http://il.srgssr.ch"];
}

static NSURL *MMFTestURL(void)
{
    return [NSURL URLWithString:@"http://play-mmf.herokuapp.com"];
}

@interface DataProviderTestCase : AnalyticsTestCase

@property (nonatomic) SRGMediaPlayerController *mediaPlayerController;

@end

@implementation DataProviderTestCase

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

- (void)testPrepareToPlayMediaComposition
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider videoMediaCompositionWithUid:@"42297626" chaptersOnly:NO completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone quality:SRGQualityHD startBitRate:0 userInfo:nil resume:YES completionHandler:^(NSError * _Nonnull error) {
            XCTAssertNil(error);
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            XCTAssertEqual(self.mediaPlayerController.streamingMethod, SRGStreamingMethodHLS);
            XCTAssertEqual(self.mediaPlayerController.quality, SRGQualityHD);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePaused);
    
    // Start playback and check labels
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_segment"], @"Archive footage of the man and his moods");
        XCTAssertEqualObjects(labels[@"media_streaming_quality"], @"HD");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:swi:video:42297626");
        return YES;
    }];
    
    [self.mediaPlayerController play];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayMediaComposition
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSWI];
    [[dataProvider videoMediaCompositionWithUid:@"42297626" chaptersOnly:NO completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
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

- (void)testPlaySegmentInMediaComposition
{
    // Use a segment id as video id, expect segment labels
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_segment"], @"Schweizer Pioniere: Die Fitnessbloggerin in der Türkei");
        XCTAssertEqualObjects(labels[@"media_streaming_quality"], @"HD");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:srf:video:27af89ad-2408-40e5-8318-96e25d3e003b");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSRF];
    [[dataProvider videoMediaCompositionWithUid:@"27af89ad-2408-40e5-8318-96e25d3e003b" chaptersOnly:NO completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone quality:SRGQualityHD startBitRate:0 userInfo:nil resume:YES completionHandler:^(NSError * _Nonnull error) {
            XCTAssertNil(error);
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            XCTAssertEqual(self.mediaPlayerController.segments.count, mediaComposition.mainChapter.segments.count);
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayLivestreamInMediaComposition
{
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_segment"], @"Livestream");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:srf:video:c4927fcf-e1a0-0001-7edd-1ef01d441651");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSRF];
    [[dataProvider videoMediaCompositionWithUid:@"c4927fcf-e1a0-0001-7edd-1ef01d441651" chaptersOnly:NO completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone quality:SRGQualityHD startBitRate:0 userInfo:nil resume:YES completionHandler:^(NSError * _Nonnull error) {
            XCTAssertNil(error);
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            XCTAssertNil(self.mediaPlayerController.segments);
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMetadata
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSRF];
    [[dataProvider videoMediaCompositionWithUid:@"c4927fcf-e1a0-0001-7edd-1ef01d441651" chaptersOnly:NO completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        NSDictionary *userInfo = @{ @"key" : @"value" };
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone quality:SRGQualityHD startBitRate:0 userInfo:userInfo resume:YES completionHandler:^(NSError * _Nonnull error) {
            XCTAssertEqualObjects([self.mediaPlayerController.userInfo dictionaryWithValuesForKeys:userInfo.allKeys], userInfo);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testUpdateWithCompatibleMediaComposition
{
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Play"];
    
    __block NSString *originalTitle = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:MMFTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierRTS];
    NSDate *startDate = [NSDate date];
    NSDate *endDate = [startDate dateByAddingTimeInterval:200];
    NSString *URNString = [NSString stringWithFormat:@"urn:rts:video:_bipbop_advanced_delay_%@_%@", @((NSInteger)[startDate timeIntervalSince1970]), @((NSInteger)[endDate timeIntervalSince1970])];
    SRGMediaURN *URN = [SRGMediaURN mediaURNWithString:URNString];
    [[dataProvider mediaCompositionWithURN:URN chaptersOnly:NO completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        originalTitle = mediaComposition.mainChapter.title;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone quality:SRGQualityHD startBitRate:0 userInfo:nil resume:YES completionHandler:^(NSError * _Nonnull error) {
            [expectation1 fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // The test media title changes over time. Wait a little bit to detect a change.
    [self expectationForElapsedTimeInterval:2. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Update"];
    
    [[dataProvider mediaCompositionWithURN:URN chaptersOnly:NO completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        self.mediaPlayerController.mediaComposition = mediaComposition;
        XCTAssertNotEqualObjects(self.mediaPlayerController.mediaComposition.mainChapter.title, originalTitle);
        
        [expectation2 fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testUpdateWithoutMediaComposition
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Play"];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSRF];
    [[dataProvider videoMediaCompositionWithUid:@"2b1bf779-6442-4f78-969e-2194020ae263" chaptersOnly:NO completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone quality:SRGQualityHD startBitRate:0 userInfo:nil resume:YES completionHandler:^(NSError * _Nonnull error) {
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    self.mediaPlayerController.mediaComposition = nil;
    XCTAssertEqualObjects(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
}

- (void)testMediaCompositionUpdateWithDifferentChapter
{
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Play"];
    
    __block SRGMediaComposition *mediaComposition1 = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSRF];
    [[dataProvider videoMediaCompositionWithUid:@"c4927fcf-e1a0-0001-7edd-1ef01d441651" chaptersOnly:NO completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        mediaComposition1 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone quality:SRGQualityHD startBitRate:0 userInfo:nil resume:YES completionHandler:^(NSError * _Nonnull error) {
            [expectation1 fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Update"];
    
    [[dataProvider videoMediaCompositionWithUid:@"895b9096-f07d-4daa-83e0-ac6486ac72e3" chaptersOnly:NO completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        self.mediaPlayerController.mediaComposition = mediaComposition;
        
        // Incompatible media composition. No update must have taken place
        XCTAssertEqualObjects(self.mediaPlayerController.mediaComposition, mediaComposition1);
        
        [expectation2 fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMediaCompositionUpdateWithDifferentSegment
{
    // Retrieve two media compositions of segments belonging to the same media composition
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Play"];
    
    __block SRGMediaComposition *mediaComposition1 = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL() businessUnitIdentifier:SRGDataProviderBusinessUnitIdentifierSRF];
    [[dataProvider videoMediaCompositionWithUid:@"2b1bf779-6442-4f78-969e-2194020ae263" chaptersOnly:NO completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        mediaComposition1 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone quality:SRGQualityHD startBitRate:0 userInfo:nil resume:YES completionHandler:^(NSError * _Nonnull error) {
            [expectation1 fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Update"];
    
    [[dataProvider videoMediaCompositionWithUid:@"197d52e6-7836-45e0-92f1-74862cc0873a" chaptersOnly:NO completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        self.mediaPlayerController.mediaComposition = mediaComposition;
        XCTAssertEqualObjects(self.mediaPlayerController.mediaComposition, mediaComposition);
        
        [expectation2 fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

@end
