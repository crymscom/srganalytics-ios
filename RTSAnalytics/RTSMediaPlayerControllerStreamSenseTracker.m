//
//  Created by Frédéric Humbert-Droz on 08/04/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import "RTSMediaPlayerControllerStreamSenseTracker.h"

#import "RTSAnalytics.h"

#import <comScore-iOS-SDK/CSStreamSense.h>
#import <comScore-iOS-SDK/CSStreamSensePlaylist.h>
#import <comScore-iOS-SDK/CSStreamSenseClip.h>

#import <RTSMediaPlayer/RTSMediaPlayerView.h>
#import <RTSMediaPlayer/NSBundle+RTSMediaPlayer.h>

#import <CocoaLumberjack/CocoaLumberjack.h>

@interface CSStreamSense ()
- (void)dispatchHeartbeatEvent;
@end

static NSString * const LoggerDomainAnalyticsStreamSense = @"StreamSense";

@interface RTSMediaPlayerControllerStreamSenseTracker ()

@property (nonatomic, strong) RTSMediaPlayerController *mediaPlayerController;
@property (nonatomic, weak) id<RTSAnalyticsMediaPlayerDataSource> dataSource;

@end

@implementation RTSMediaPlayerControllerStreamSenseTracker

- (void)dealloc
{
	_mediaPlayerController = nil;
}

- (id)initWithPlayer:(RTSMediaPlayerController *)mediaPlayerController dataSource:(id<RTSAnalyticsMediaPlayerDataSource>)dataSource
{
	if(!(self = [super init]))
	   return nil;
	
	_mediaPlayerController = mediaPlayerController;
	_dataSource = dataSource;
	
	NSBundle *mediaPlayerBundle = [NSBundle RTSMediaPlayerBundle];
	
	[self setLabel:@"ns_st_mp" value:[mediaPlayerBundle objectForInfoDictionaryKey:@"CFBundleName"]];
	[self setLabel:@"ns_st_pv" value:kRTSAnalyticsVersion];
	[self setLabel:@"ns_st_mv" value:[mediaPlayerBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
	[self setLabel:@"ns_st_it" value:@"c"];
	
	NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];
	NSDictionary *analyticsInfoDictionnary = [mainBundle objectForInfoDictionaryKey:@"RTSAnalytics"];
	NSString *streamSenseVirtualSite = [analyticsInfoDictionnary objectForKey:@"StreamsenseVirtualSite"];
	NSAssert(streamSenseVirtualSite.length > 0, @"You MUST define `RTSAnalytics>StreamsenseVirtualSite` key in your app Info.plist");
	
	[self setLabel:@"ns_vsite" value:streamSenseVirtualSite];
	[self setLabel:@"srg_ptype" value:@"p_app_ios"];
	
	DDLogVerbose(@"%@ : new Streamsense instance with ns_vsite = %@", LoggerDomainAnalyticsStreamSense, streamSenseVirtualSite);

	return self;
}

- (void) notify:(CSStreamSenseEventType)playerEvent
{
	[self updateLabels];
	[self notify:playerEvent position:[self currentPositionInMilliseconds] labels:nil];
}

- (void) dispatchHeartbeatEvent
{
	[self updateLabels];
	[super dispatchHeartbeatEvent];
}

#pragma mark - CSStreamSensePluginProtocol

- (long) currentPositionInMilliseconds
{
	CMTime currentTime = [self.mediaPlayerController.player.currentItem currentTime];
	return (long) floor(CMTimeGetSeconds(currentTime) * 1000);
}

#pragma mark - Private Labels methods

- (void) updateLabels
{
	// Labels
	[self setLabel:@"ns_st_br" value:[self bitRate]];
	[self setLabel:@"ns_st_ws" value:[self windowState]];
	[self setLabel:@"ns_st_vo" value:[self volume]];
	[self setLabel:@"ns_st_sg" value:[self scalingMode]];
	[self setLabel:@"ns_ap_ot" value:[self orientation]];
	[self setLabel:@"ns_st_airplay" value:[self airplay]];
	[self setLabel:@"ns_st_cu" value:[self contentURL]];
	
	if ([self.dataSource respondsToSelector:@selector(streamSenseLabelsMetadataForIdentifier:)]) {
		NSDictionary *dataSourceLabels = [self.dataSource streamSenseLabelsMetadataForIdentifier:self.mediaPlayerController.identifier];
		[dataSourceLabels enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[self setLabel:key value:obj];
		}];
	}
	
	// Playlist
	if ([self.dataSource respondsToSelector:@selector(streamSensePlaylistMetadataForIdentifier:)]) {
		NSDictionary *dataSourcePlaylist = [self.dataSource streamSensePlaylistMetadataForIdentifier:self.mediaPlayerController.identifier];
		[dataSourcePlaylist enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[[self playlist] setLabel:key value:obj];
		}];
	}
	
	// Clips
	[[self clip] setLabel:@"ns_st_cs" value:[self dimensions]];
	[[self clip] setLabel:@"ns_st_cl" value:[self duration]];
	[[self clip] setLabel:@"ns_st_li" value:[self liveStream]];
	
	if ([self.dataSource respondsToSelector:@selector(streamSenseClipMetadataForIdentifier:)]) {
		NSDictionary *dataSourceClip = [self.dataSource streamSenseClipMetadataForIdentifier:self.mediaPlayerController.identifier];
		[dataSourceClip enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[[self clip] setLabel:key value:obj];
		}];
	}
}

#pragma mark - Private helper methods

- (NSString *) bitRate
{
	AVPlayerItem *currentItem = self.mediaPlayerController.player.currentItem;
	if (currentItem)
	{
		NSArray *events = currentItem.accessLog.events;
		if (events.lastObject) {
			double observedBitrate = [events.lastObject observedBitrate];
			return [@(observedBitrate) stringValue];
		}
	}
	return nil;
}

- (NSString *) windowState
{
	AVPlayerLayer *playerLayer = [(RTSMediaPlayerView *)self.mediaPlayerController.view playerLayer];
	CGSize size = playerLayer.videoRect.size;
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	return round(size.width) == round(screenRect.size.width) && round(size.height) == round(screenRect.size.height)  ? @"full" : @"norm";
}

- (NSString *) volume
{
	if (self.mediaPlayerController.player && self.mediaPlayerController.player.isMuted)
		return @"0";
	
	if (![[AVAudioSession sharedInstance] respondsToSelector:@selector(outputVolume)])
		return @"0";
	
	id instance = [AVAudioSession sharedInstance];
	IMP outputVolumeImp = [instance methodForSelector:@selector(outputVolume)];
	float volume = ((float (*) (id,SEL))outputVolumeImp)(instance,@selector(outputVolume));
	return [NSString stringWithFormat:@"%d", (int) (volume * 100)];
}

- (NSString *) scalingMode
{
	AVPlayerLayer *playerLayer = [(RTSMediaPlayerView *)self.mediaPlayerController.view playerLayer];
	
	NSString *result = @"no";
	if (playerLayer) {
		if ([playerLayer.videoGravity isEqualToString:@"AVLayerVideoGravityResize"])
			result = @"fill";
		else if ([playerLayer.videoGravity isEqualToString:@"AVLayerVideoGravityResizeAspect"])
			result = @"fit-a";
		else if ([playerLayer.videoGravity isEqualToString:@"AVLayerVideoGravityResizeAspectFill"])
			result = @"fill-a";
	}
	return result;
}

- (NSString *) orientation {
	NSString *result = NULL;
	UIDeviceOrientation orient = [[UIDevice currentDevice] orientation];
	switch (orient) {
		case UIDeviceOrientationFaceDown:
			result = @"facedown";
			break;
		case UIDeviceOrientationFaceUp:
			result = @"faceup";
			break;
		case UIDeviceOrientationPortrait:
			result = @"pt";
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			result = @"updown";
			break;
		case UIDeviceOrientationLandscapeLeft:
			result = @"left";
			break;
		case UIDeviceOrientationLandscapeRight:
			result = @"right";
			break;
		default:
			break;
	}
	return result;
}

- (NSString *) airplay
{
	return self.mediaPlayerController.player.isExternalPlaybackActive ? @"1" : @"0";
}

- (NSString *) liveStream
{
	return (CMTimeCompare(self.mediaPlayerController.player.currentItem.duration, kCMTimeIndefinite) == 0) ? @"1" : @"0";
}

- (NSString *) dimensions
{
	AVPlayerLayer *playerLayer = [(RTSMediaPlayerView *)self.mediaPlayerController.view playerLayer];
	CGSize size = playerLayer.videoRect.size;
	return [NSString stringWithFormat:@"%0.0fx%0.0f", size.width, size.height];
}

- (NSString *) duration
{
	if ([self.mediaPlayerController.player currentItem]) {
		if ([self.mediaPlayerController.player status] == AVPlayerItemStatusReadyToPlay) {
			return [NSString stringWithFormat:@"%ld", (long) CMTimeGetSeconds(self.mediaPlayerController.player.currentItem.asset.duration) * 1000];
		}
	}
	return @"0";
}

- (NSString *) contentURL
{
	AVAsset *asset = self.mediaPlayerController.player.currentItem.asset;
	if ([asset isKindOfClass:[AVURLAsset class]]) {
		NSURL *assetURL = [(AVURLAsset *)asset URL];
		NSURL *newURL = [[NSURL alloc] initWithScheme:[assetURL scheme] host:[assetURL host] path:[assetURL path]];
		return newURL.absoluteString;
	}
	return nil;
}

@end
