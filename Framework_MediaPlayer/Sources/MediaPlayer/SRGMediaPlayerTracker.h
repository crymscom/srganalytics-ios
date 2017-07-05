//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

// Key under which media player labels are stored in the media player controller user information.
OBJC_EXTERN NSString * const SRGAnalyticsMediaPlayerLabelsKey;

// Key under which media player comScore labels are stored in the media player controller user information.
OBJC_EXTERN NSString * const SRGAnalyticsMediaPlayerComScoreLabelsKey;

/**
 *  The media player tracker class internally listens to media player controller notifications to provide automatic
 *  tracking of media consumption. A tracker is automatically associated with a player controller when it prepares
 *  to play, and is removed when the player returns to the idle state.
 */
@interface SRGMediaPlayerTracker : NSObject

@end

@interface SRGMediaPlayerTracker (Unavailable)

- (id)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
