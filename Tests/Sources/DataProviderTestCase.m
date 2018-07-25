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
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeDVR quality:SRGQualityHD startBitRate:0 userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            XCTAssertEqual(self.mediaPlayerController.resource.streamingMethod, SRGStreamingMethodHLS);
            XCTAssertEqual(self.mediaPlayerController.resource.quality, SRGQualityHD);
            XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeFlat);
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

- (void)testPrepareToPlay360Video
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:8414077" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityNone startBitRate:0 userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeMonoscopic);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPrepareToPlay360VideoAlreadyStereoscopic
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:8414077" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        self.mediaPlayerController.view.viewMode = SRGMediaPlayerViewModeStereoscopic;
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityNone startBitRate:0 userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeStereoscopic);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testPlayMediaComposition
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.playbackState, SRGMediaPlayerPlaybackStatePlaying);
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeFlat);
}

- (void)testPlaySegmentInMediaComposition
{
    // Use a segment id as video id, expect segment labels
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_segment"], @"Newsflash");
        XCTAssertEqualObjects(labels[@"media_streaming_quality"], @"HD");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:srf:video:985aa94a-587c-494e-b484-3cd746032264");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:985aa94a-587c-494e-b484-3cd746032264" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
    XCTAssertEqual(self.mediaPlayerController.segments.count, fetchedMediaComposition.mainChapter.segments.count);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeFlat);
}

- (void)testPlayLivestreamInMediaComposition
{
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_segment"], @"Livestream");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:srf:video:c4927fcf-e1a0-0001-7edd-1ef01d441651");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:c4927fcf-e1a0-0001-7edd-1ef01d441651" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
    XCTAssertNil(self.mediaPlayerController.segments);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeFlat);
}

- (void)testPlay360InMediaComposition
{
    [self expectationForHiddenEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(labels[@"event_id"], @"play");
        XCTAssertEqualObjects(labels[@"media_urn"], @"urn:rts:video:8414077");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:8414077" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeMonoscopic);
}

- (void)testPlay360AndFlatInMediaComposition
{
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        XCTAssertEqualObjects(event, @"play");
        return YES;
    }];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:MMFTestURL()];
    
    __block SRGMediaComposition *fetchedMediaComposition1 = nil;
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:_gothard" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition1 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition1);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeMonoscopic);
    
    __block BOOL stopReceived = NO;
    __block BOOL playReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"stop"]) {
            stopReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return stopReceived && playReceived;
    }];
    
    __block SRGMediaComposition *fetchedMediaComposition2 = nil;
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:_fifa_russia_2017" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition2 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition2);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeMonoscopic);
    
    stopReceived = NO;
    playReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"stop"]) {
            stopReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return stopReceived && playReceived;
    }];
    
    self.mediaPlayerController.view.viewMode = SRGMediaPlayerViewModeStereoscopic;
    
    __block SRGMediaComposition *fetchedMediaComposition3 = nil;
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:_gothard" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition3 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition3);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeStereoscopic);
    
    stopReceived = NO;
    playReceived = NO;
    
    [self expectationForHiddenPlaybackEventNotificationWithHandler:^BOOL(NSString *event, NSDictionary *labels) {
        if ([event isEqualToString:@"stop"]) {
            stopReceived = YES;
        }
        else if ([event isEqualToString:@"play"]) {
            XCTAssertFalse(playReceived);
            playReceived = YES;
        }
        else {
            XCTFail(@"Unexpected event %@", event);
        }
        
        return stopReceived && playReceived;
    }];
    
    __block SRGMediaComposition *fetchedMediaComposition4 = nil;
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:_rts_info" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition4 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.mediaComposition, fetchedMediaComposition4);
    XCTAssertEqual(self.mediaPlayerController.view.viewMode, SRGMediaPlayerViewModeFlat);
}

- (void)testMetadata
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:c4927fcf-e1a0-0001-7edd-1ef01d441651" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        NSDictionary *userInfo = @{ @"key" : @"value" };
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:userInfo completionHandler:^{
            XCTAssertEqualObjects([self.mediaPlayerController.userInfo dictionaryWithValuesForKeys:userInfo.allKeys], userInfo);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testUpdateWithCompatibleMediaComposition
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    __block NSString *originalTitle = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:MMFTestURL()];
    NSDate *startDate = [NSDate date];
    NSDate *endDate = [startDate dateByAddingTimeInterval:200];
    NSString *URN = [NSString stringWithFormat:@"urn:rts:video:_bipbop_advanced_delay_%@_%@", @((NSInteger)[startDate timeIntervalSince1970]), @((NSInteger)[endDate timeIntervalSince1970])];
    [[dataProvider mediaCompositionForURN:URN standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        originalTitle = mediaComposition.mainChapter.title;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    // The test media title changes over time. Wait a little bit to detect a change.
    [self expectationForElapsedTimeInterval:2. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Update"];
    
    [[dataProvider mediaCompositionForURN:URN standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        self.mediaPlayerController.mediaComposition = mediaComposition;
        XCTAssertNotEqualObjects(self.mediaPlayerController.mediaComposition.mainChapter.title, originalTitle);
        
        [expectation2 fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testUpdateWithoutMediaComposition
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    __block SRGMediaComposition *fetchedMediaComposition = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:c4927fcf-e1a0-0001-7edd-1ef01d441651" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    self.mediaPlayerController.mediaComposition = nil;
    XCTAssertEqualObjects(self.mediaPlayerController.mediaComposition, fetchedMediaComposition);
    XCTAssertEqualObjects(self.mediaPlayerController.segments, fetchedMediaComposition.mainChapter.segments);
}

- (void)testMediaCompositionUpdateWithDifferentChapter
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    __block SRGMediaComposition *fetchedMediaComposition1 = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:c4927fcf-e1a0-0001-7edd-1ef01d441651" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition1 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Update"];
    
    [[dataProvider mediaCompositionForURN:@"urn:srf:video:895b9096-f07d-4daa-83e0-ac6486ac72e3" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        self.mediaPlayerController.mediaComposition = mediaComposition;
        
        // Incompatible media composition. No update must have taken place
        XCTAssertEqualObjects(self.mediaPlayerController.mediaComposition, fetchedMediaComposition1);
        XCTAssertEqualObjects(self.mediaPlayerController.segments, fetchedMediaComposition1.mainChapter.segments);
        
        [expectation2 fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMediaCompositionUpdateWithDifferentMainSegment
{
    // Retrieve two media compositions of segments belonging to the same media composition
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    __block SRGMediaComposition *fetchedMediaComposition1 = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:8995306" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition1 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.segments, fetchedMediaComposition1.mainChapter.segments);
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Update"];
    
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:8995308" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        self.mediaPlayerController.mediaComposition = mediaComposition;
        XCTAssertEqualObjects(self.mediaPlayerController.mediaComposition, mediaComposition);
        XCTAssertEqualObjects(self.mediaPlayerController.segments, mediaComposition.mainChapter.segments);
        [expectation2 fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testMediaCompositionUpdateWithNewSegment
{
    [self expectationForNotification:SRGMediaPlayerPlaybackStateDidChangeNotification object:self.mediaPlayerController handler:^BOOL(NSNotification * _Nonnull notification) {
        return [notification.userInfo[SRGMediaPlayerPlaybackStateKey] integerValue] == SRGMediaPlayerPlaybackStatePlaying;
    }];
    
    __block SRGMediaComposition *fetchedMediaComposition1 = nil;
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:MMFTestURL()];
    NSDate *startDate = [[NSDate date] dateByAddingTimeInterval:-6];
    NSDate *endDate = [startDate dateByAddingTimeInterval:20];
    NSString *URN = [NSString stringWithFormat:@"urn:rts:video:_rts_info_fulldvr_%@_%@", @((NSInteger)[startDate timeIntervalSince1970]), @((NSInteger)[endDate timeIntervalSince1970])];
    [[dataProvider mediaCompositionForURN:URN standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        fetchedMediaComposition1 = mediaComposition;
        
        [self.mediaPlayerController playMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.segments, fetchedMediaComposition1.mainChapter.segments);
    
    // The full DVR adds a highlight every 5 seconds. Wait a little bit to detect a change.
    [self expectationForElapsedTimeInterval:5. withHandler:nil];
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Update"];
    
    [[dataProvider mediaCompositionForURN:URN standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        XCTAssertTrue(fetchedMediaComposition1.mainChapter.segments.count != mediaComposition.mainChapter.segments.count);

        self.mediaPlayerController.mediaComposition = mediaComposition;
        XCTAssertEqualObjects(self.mediaPlayerController.mediaComposition, mediaComposition);
        XCTAssertEqualObjects(self.mediaPlayerController.segments, mediaComposition.mainChapter.segments);
        [expectation2 fulfill];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
}

- (void)testDefaultStreamingMethod
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:audio:3262320" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.resource.streamingMethod, SRGStreamingMethodHLS);
}

- (void)testPreferredStreamingMethod
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:audio:3262320" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodProgressive contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.resource.streamingMethod, SRGStreamingMethodProgressive);
}

- (void)testNonExistingStreamingMethod
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:audio:3262320" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodHTTP contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.resource.streamingMethod, SRGStreamingMethodHLS);
}

- (void)testDefaultStreamType
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:3608506" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHD startBitRate:0 userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGStreamTypeDVR);
}

- (void)testPreferredStreamType
{
    // FIXME: See https://github.com/SRGSSR/SRGMediaPlayer-iOS/issues/50. Workaround so that the test passes on iOS >= 11.3.
    NSOperatingSystemVersion operatingSystemVersion = [NSProcessInfo processInfo].operatingSystemVersion;
    if (operatingSystemVersion.majorVersion == 11 && operatingSystemVersion.minorVersion >= 3) {
        self.mediaPlayerController.minimumDVRWindowLength = 40.;
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:3608506" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeLive quality:SRGQualityHD startBitRate:0 userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGStreamTypeLive);
}

- (void)testNonExistingStreamType
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:rts:video:3608506" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeOnDemand quality:SRGQualityHD startBitRate:0 userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.streamType, SRGStreamTypeDVR);
}

- (void)testDefaultQuality
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityNone startBitRate:0 userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.resource.quality, SRGQualityHD);
}

- (void)testPreferredQuality
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualitySD startBitRate:0 userInfo:nil completionHandler:^{
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.resource.quality, SRGQualitySD);
}

- (void)testNonExistingQuality
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:swi:video:42297626" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityHQ startBitRate:0 userInfo:nil completionHandler:^{
            XCTAssertNil(error);
            XCTAssertEqual(self.mediaPlayerController.mediaComposition, mediaComposition);
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqual(self.mediaPlayerController.resource.quality, SRGQualityHD);
}

- (void)testPreferHTTPSResources
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ready to play"];
    
    // The following audio has two equivalent resources for the playback default settings (one in HTTP, the other in HTTPS). The order of these resources in the JSON is not reliable,
    // but we want to select always the HTTPS resource first
    SRGDataProvider *dataProvider = [[SRGDataProvider alloc] initWithServiceURL:ServiceTestURL()];
    [[dataProvider mediaCompositionForURN:@"urn:srf:audio:d7dd9454-23c8-4160-81ff-ace459dd53c0" standalone:NO withCompletionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        XCTAssertNotNil(mediaComposition);
        
        [self.mediaPlayerController prepareToPlayMediaComposition:mediaComposition withPreferredStreamingMethod:SRGStreamingMethodNone contentProtection:SRGContentProtectionNone streamType:SRGStreamTypeNone quality:SRGQualityNone startBitRate:0 userInfo:nil completionHandler:^{
            [expectation fulfill];
        }];
    }] resume];
    
    [self waitForExpectationsWithTimeout:20. handler:nil];
    
    XCTAssertEqualObjects(self.mediaPlayerController.contentURL.scheme, @"https");
}

@end
