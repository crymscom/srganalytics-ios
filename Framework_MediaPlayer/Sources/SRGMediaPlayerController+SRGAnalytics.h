//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>

static NSString * const SRGAnalyticsIdentifierInfoKey = @"SRGAnalyticsIdentifierInfoKey";

@interface SRGMediaPlayerController (SRGAnalytics)

/**
 *  Get the identifier, for analytic metrics
 *
 *  Use the SRGAnalyticsIdentifierInfoKey object in the userInfo dictionnary.
 #  @see `-prepareToPlayURL:atTime:withSegments:userInfo:completionHandler:` or @see `-playURL:atTime:withSegments:userInfo:completionHandler:`
 *
 *  @discussion Need to be set with the userInfo parameter.
 */
@property (nonatomic, readonly) NSString *identifier;

/**
 *  Set whether a stream tracker must be created for the receiver. The default value is YES.
 *
 *  @discussion If the stream tracker is not created yet and the player is already playing, the stream will be automatically
 *              opened. Conversely, any open stream will automatically be closed when tracking is set to NO.
 */
@property (nonatomic, getter=isTracked) BOOL tracked;

@end
