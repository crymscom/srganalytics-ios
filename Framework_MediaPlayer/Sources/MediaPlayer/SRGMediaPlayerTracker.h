//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <ComScore/ComScore.h>
#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

// Key under which media player labels are stored in the media player controller user information
OBJC_EXTERN NSString * const SRGAnalyticsMediaPlayerLabelsKey;

/**
 *  The media player tracker class internally listens to media player controller notifications to provide automatic
 *  tracking of media consumption. A tracker is automatically associated with a player controller when it prepares
 *  to play, and is removed when the player returns to the idle state
 */
@interface SRGMediaPlayerTracker : CSStreamSense

/**
 *  Return the tracker associated with a media player controller, nil if none
 */
+ (nullable SRGMediaPlayerTracker *)trackerForMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController;

/**
 *  Set to YES to disable (remark: Tracking is still made, but events are not sent)
 */
@property (nonatomic, getter=isEnabled) BOOL enabled;

@end

@interface SRGMediaPlayerTracker (Unavailable)

- (id)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
