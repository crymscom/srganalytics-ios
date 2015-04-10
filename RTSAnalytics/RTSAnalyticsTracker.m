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

#import <CocoaLumberjack/CocoaLumberjack.h>

#import "CSRequest+RTSNotification.h"

static BOOL isComScoreSingletonConfigured = NO;
static BOOL isComScoreTasksLogginStarted = NO;

@interface CSTaskExecutor : NSObject
- (void)execute:(void(^)(void))block background:(BOOL)background;
@end

@interface CSCore : NSObject
- (CSTaskExecutor *)taskExecutor;
@end

static NSString * const RTSAnalyticsLoggerDomainAnalyticsComscore = @"Comscore";

@interface RTSAnalyticsTracker ()
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
        
        if (!isComScoreSingletonConfigured) {
            [CSComScore onUxActive];
            [CSComScore setCustomerC2:@"6036016"];
            [CSComScore setPublisherSecret:@"b19346c7cb5e521845fb032be24b0154"];
            [CSComScore setLabels:[self.config comScoreGlobalLabels]];
            isComScoreSingletonConfigured = YES;
        }

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sendMetadataUponAppEnteringForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sendMetadataUponMediaPlayerPlaybackStateChange:)
                                                     name:RTSMediaPlayerPlaybackStateDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)sendMetadataUponAppEnteringForeground:(NSNotification *)notification
{
    DDLogInfo(@"Sending comScore metadata upon app entering foreground");
    [CSComScore viewWithLabels:[self.dataSource comScoreLabelsForAppEnteringForeground]];
}

- (void)sendMetadataUponMediaPlayerPlaybackStateChange:(NSNotification *)notification
{
    DDLogInfo(@"Sending comScore and streamSense metadata upon player status did change");
    
    RTSMediaPlayerController *player = [notification object];
    RTSMediaPlaybackState oldState = [notification.userInfo[RTSMediaPlayerPreviousPlaybackStateUserInfoKey] integerValue];
    RTSMediaPlaybackState newState = player.playbackState;

//  *** comScore ***
    
    if (oldState == RTSMediaPlaybackStatePreparing && newState == RTSMediaPlaybackStateReady) {
        NSDictionary *labels = [self.dataSource comScoreReadyToPlayLabelsForIdentifier:player.identifier];
        [CSComScore viewWithLabels:labels];
    }
    
//  *** StreamSense ***
    
    CSStreamSense *streamSense = [self configuredStreamSenseInstance];

    if (oldState == RTSMediaPlaybackStateReady && newState == RTSMediaPlaybackStatePlaying) {
        [[streamSense playlist] setLabels:[self.dataSource streamSensePlaylistMetadataForIdentifier:player.identifier]];
        [[streamSense clip] setLabels:[self.dataSource streamSenseFullLengthClipMetadataForIdentifier:player.identifier]];
        [streamSense notify:CSStreamSensePlay position:0];
    }
    
    BOOL isLive = ([self.dataSource mediaModeForIdentifier:player.identifier] == RTSAnalyticsMediaModeLiveStream);

    CSStreamSenseEventType streamSenseEventType = ^(void) {
        switch (player.playbackState) {
            case RTSMediaPlaybackStatePaused:
                return (isLive) ? CSStreamSenseEnd : CSStreamSensePause;

            case RTSMediaPlaybackStatePlaying:
                return CSStreamSensePlay;

            case RTSMediaPlaybackStateReady:
                return (oldState == RTSMediaPlaybackStatePlaying) ? CSStreamSenseEnd : CSStreamSenseCustom;

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
    
    DDLogInfo(@"Configuring new StreamSense instance with labels: %@", initLabels);
    
    return instance;
}

#pragma mark - Logging

- (void)startLoggingInternalComScoreTasks
{
    if (isComScoreTasksLogginStarted) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(comScoreRequestDidFinish:)
                                                 name:RTSAnalyticsComScoreRequestDidFinishNotification
                                               object:nil];
    
        // +[CSComScore setPixelURL:] is dispatched on an internal comScore queue, so calling +[CSComScore pixelURL] right after doesn’t work, we must also dispatch it on the same queue!
    [[[CSComScore core] taskExecutor] execute:^
    {
        const SEL selectors[] = {
            @selector(appName),
            @selector(pixelURL),
            @selector(publisherSecret),
            @selector(customerC2),
            @selector(version),
            @selector(labels)
        };
         
        NSMutableString *message = [NSMutableString new];
        for (NSUInteger i = 0; i < sizeof(selectors) / sizeof(selectors[0]); i++) {
            SEL selector = selectors[i];
            [message appendFormat:@"%@: %@\n", NSStringFromSelector(selector), [CSComScore performSelector:selector]];
        }
        [message deleteCharactersInRange:NSMakeRange(message.length - 1, 1)];
        DDLogInfo(@"%@", message);
        
     } background:YES];
    
    isComScoreTasksLogginStarted = YES;
}

- (void)stopLoggingInternalComScoreTasks
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RTSAnalyticsComScoreRequestDidFinishNotification object:nil];
    isComScoreTasksLogginStarted = NO;
}

- (void)comScoreRequestDidFinish:(NSNotification *)notification
{
    NSDictionary *labels = notification.userInfo[RTSAnalyticsComScoreRequestLabelsUserInfoKey];
    NSUInteger maxKeyLength = [[[labels allKeys] valueForKeyPath:@"@max.length"] unsignedIntegerValue];
    
    NSMutableString *dictionaryRepresentation = [NSMutableString new];
    for (NSString *key in [[labels allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        [dictionaryRepresentation appendFormat:@"%@ = %@\n", [key stringByPaddingToLength:maxKeyLength withString:@" " startingAtIndex:0], labels[key]];
    }
    
    NSString *ns_st_ev = labels[@"ns_st_ev"];
    NSString *ns_ap_ev = labels[@"ns_ap_ev"];
    NSString *type = labels[@"ns_st_ty"];
    NSString *typeSymbol = @"\U00002753"; // BLACK QUESTION MARK ORNAMENT
    
    if ([type isEqual:@"audio"]) {
        typeSymbol = @"\U0001F4FB"; // RADIO
    }
    else if ([type isEqual:@"video"]) {
        typeSymbol = @"\U0001F4FA"; // TELEVISION
    }
    
    if ([labels[@"ns_st_li"] boolValue]) {
        typeSymbol = [typeSymbol stringByAppendingString:@"\U0001F6A8"];
    }
    
    NSString *event = ns_st_ev ?  [typeSymbol stringByAppendingFormat:@" %@", ns_st_ev] : ns_ap_ev;
    NSString *name = ns_st_ev ? [NSString stringWithFormat:@"%@ / %@", labels[@"ns_st_pl"], labels[@"ns_st_ep"]] : labels[@"name"];
    
    BOOL success = [notification.userInfo[RTSAnalyticsComScoreRequestSuccessUserInfoKey] boolValue];
    if (success) {
        DDLogDebug(@"%@ > %@", event, name);
    }
    else {
        DDLogError(@"ERROR sending %@ > %@", event, name);
    }
    
    DDLogVerbose(@"%@", dictionaryRepresentation);
}


@end
