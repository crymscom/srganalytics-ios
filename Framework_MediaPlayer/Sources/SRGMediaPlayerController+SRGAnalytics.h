//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface SRGMediaPlayerController (SRGAnalytics)

+ (void)prepareToplayURL:(NSURL *)URL withIdentifier:(NSString *)identifier;

/**
 *  Set an identifier, for analytic metrics
 *
 *  @discussion Use convinience methods
 */
@property (nonatomic, readonly) NSString *identifier;

/**
 *  Set whether a stream tracker must be created for the receiver. The default value is YES.
 *
 *  @discussion If the stream tracker is not created yet and the player is already playing, the stream will be automatically
 *              opened. Conversely, any open stream will automatically be closed when tracking is set to NO.
 */
@property (nonatomic, getter=isTracked) BOOL tracked;

- (void)prepareToPlayURL:(NSURL *)URL atTime:(CMTime)startTime withSegments:(NSArray<id<SRGSegment>> *)segments completionHandler:(void (^)(void))completionHandler NS_UNAVAILABLE;

- (void)prepareToPlayIdentifier:(NSString *)identifier withURL:(NSURL *)URL atTime:(CMTime)startTime withSegments:(NSArray<id<SRGSegment>> *)segments completionHandler:(void (^)(void))completionHandler;

@end
