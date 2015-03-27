//
//  RTSAnalytics.m
//  RTSAnalytics
//
//  Created by Cédric Foellmi on 25/03/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSAnalyticsTracker.h"

#import <UIKit/UIKit.h>

#import <comScore-iOS-SDK/CSComScore.h>
#import <comScore-iOS-SDK/CSStreamSense.h>
#import <comScore-iOS-SDK/CSStreamSenseClip.h>
#import <comScore-iOS-SDK/CSStreamSensePlaylist.h>

#import <RTSMediaPlayer/RTSMediaPlayer.h>


@interface RTSAnalyticsTracker () {
    BOOL _wasReadyToPlay;
//    BOOL _wasSegmentSelected; // To be used when we need to distinguish segments being played and segments selected by the user.
}
@property(nonatomic, strong) RTSAnalyticsTrackerConfig *config;
@property(nonatomic, weak) id<RTSAnalyticsDataSource> dataSource;
@end

@implementation RTSAnalyticsTracker

- (instancetype)initWithConfig:(RTSAnalyticsTrackerConfig *)config dataSource:(id<RTSAnalyticsDataSource>)dataSource
{
    NSAssert(config, @"Missing config");
    NSAssert(dataSource, @"Missing dataSource");
    
    self = [super init];
    if (self) {
        self.config = config;
        self.dataSource = dataSource;
        
//        WARNING: This call is made once on SRG player, while the comScore documentation says it must be
//        balanced with onUxInactive.
//        [CSComScore onUxActive];
        
        [CSComScore setCustomerC2:@"6036016"];
        [CSComScore setPublisherSecret:@"b19346c7cb5e521845fb032be24b0154"];
        [CSComScore setLabels:[self.config comScoreGlobalLabels]];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sendMetadataUponAppEnteringForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sendMetadataUponVideoPlayerViewStatusChange:)
                                                     name:RTSMediaPlayerPlaybackStateDidChangeNotification
                                                   object:nil];

//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(sendMetadataUponVideoPlaybackEventOccurence:)
//                                                     name:SRGMediaPlaybackEventDidOccurNotification
//                                                   object:nil];

    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)sendMetadataUponAppEnteringForeground:(NSNotification *)notification
{
    [CSComScore viewWithLabels:[self.dataSource comScoreLabelsForAppEnteringForeground]];
}

- (void)sendComScoreMetadataUponVideoPlaybackReadyToPlayNotification:(NSNotification *)notification
{
}

- (void)sendMetadataUponVideoPlayerViewStatusChange:(NSNotification *)notification
{
    RTSMediaPlayerController *player = [notification object];
    
//  *** comScore ***
    
    NSDictionary *labels = [self.dataSource comScoreReadyToPlayLabelsForIdentifier:player.identifier];
    [CSComScore viewWithLabels:labels];
    
//  *** StreamSense ***
 
    if (player.playbackState == RTSMediaPlaybackStatePendingPlay) {
        _wasReadyToPlay = YES;
    }

    CSStreamSense *streamSense = [self configuredStreamSenseInstance];

    if (_wasReadyToPlay && (player.playbackState == RTSMediaPlaybackStatePlaying)) {
        _wasReadyToPlay = NO;
        [[streamSense playlist] setLabels:[self.dataSource streamSensePlaylistMetadataForIdentifier:player.identifier]];
        [[streamSense clip] setLabels:[self.dataSource streamSenseFullLengthClipMetadataForIdentifier:player.identifier]];
        [streamSense notify:CSStreamSensePlay position:0];
    }
    
//  Segments
//    if (eventType == SRGMediaPlaybackEventStartSegment || eventType == SRGMediaPlaybackEventEndSlide) {
//        [[self.streamSense clip] setLabels:[dataSource segmentMetadataWithPlaybackEventUserInfo:userInfo wasSegmentSelected:self.wasSegmentSelected]];
//        _wasSegmentSelected = NO; // Reseting value right after using it.
//    }

    
    BOOL isLive = ([self.dataSource mediaModeForIdentifier:player.identifier] == RTSAnalyticsMediaModeLiveStream);

    CSStreamSenseEventType streamSenseEventType = ^(void) {
        switch (player.playbackState) {
            case RTSMediaPlaybackStatePaused:
                return (isLive) ? CSStreamSenseEnd : CSStreamSensePause;

            case RTSMediaPlaybackStatePlaying:
                return CSStreamSensePlay;

            case RTSMediaPlaybackStateEnded:
                return CSStreamSenseEnd;

            default:
                return CSStreamSenseCustom;
        }
    }();

    // Launch StreamSense events only if necessary:
    if (streamSenseEventType != CSStreamSenseCustom) {
        [[streamSense clip] setLabels:[self.dataSource streamSenseFullLengthClipMetadataForIdentifier:player.identifier]];

        long milliseconds = (isLive) ? 0 : MAX(0, CMTimeGetSeconds(player.player.currentItem.currentTime)  * 1000.0);
        [streamSense notify:streamSenseEventType position:milliseconds];
    }
    
//    if (eventType == SRGMediaPlaybackEventSegmentSelected) {
//    //  Re-set current values of the playlist.
//        [[streamSense playlist] setLabels:[dataSource playlistMetadata]];
//        _wasSegmentSelected = YES;
//    }
}

- (CSStreamSense *)configuredStreamSenseInstance
{
    CSStreamSense *instance = [CSStreamSense new];
 
    NSDictionary *initLabels = @{@"srg_ptype": @"p_app_ios",
                                 @"ns_site":   @"mainsite",
                                 @"ns_vsite":  [NSString stringWithFormat:@"%@-v", [self.config.businessUnit lowercaseString]],
                                 @"ns_st_mv":  self.config.version,
                                 @"srg_unit":  [self.config.businessUnit uppercaseString]};
    
    [instance setLabels:initLabels];
    
    return instance;
}

@end
