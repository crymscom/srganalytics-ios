//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

#import "SRGAnalyticsStreamLabels.h"

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class SRGAnalyticsStreamTracker;

/**
 *  @name Stream types
 */
typedef NS_ENUM(NSInteger, SRGAnalyticsStreamType) {
    /**
     *  On-demand stream.
     */
    SRGAnalyticsStreamTypeOnDemand = 1,
    /**
     *  Live stream.
     */
    SRGAnalyticsStreamTypeLive,
    /**
     *  DVR stream.
     */
    SRGAnalyticsStreamTypeDVR
};

/**
 *  @name Stream states
 */
typedef NS_ENUM(NSInteger, SRGAnalyticsStreamState) {
    /**
     *  The stream is currently being buffered (either during initial playback preparation or while re-buffering).
     */
    SRGAnalyticsStreamStateBuffering = 1,
    /**
     *  The stream is currently being played.
     */
    SRGAnalyticsStreamStatePlaying,
    /**
     *  Stream playback is paused.
     */
    SRGAnalyticsStreamStatePaused,
    /**
     *  The stream is being seeked to another location.
     */
    SRGAnalyticsStreamStateSeeking,
    /**
     *  The stream playback has been stopped.
     */
    SRGAnalyticsStreamStateStopped,
    /**
     *  Stream playback ended normally.
     */
    SRGAnalyticsStreamStateEnded
};

/**
 *  Stream tracker delegate.
 */
@protocol SRGAnalyticsStreamTrackerDelegate <NSObject>

/**
 *  The current playback position.
 */
@property (nonatomic, readonly) NSTimeInterval playbackPosition;

/**
 *  Return `YES` iff the stream is being played in live conditions.
 */
@property (nonatomic, readonly, getter=isLive) BOOL live;

/**
 *  Current labels associated with the stream.
 */
@property (nonatomic, readonly, nullable) SRGAnalyticsStreamLabels *labels;

@end

/**
 *  Tracker for stream playback consumption. This tracker is a generic implementation suitable for any kind of media
 *  player for which SRG-compliant analytics should be collected.
 *
 *  When you need to track a new stream playback, simply instantiate an `SRGAnalyticsStreamTracker`, keeping a strong
 *  reference to it, and call the update method when a stream state change must be notified. A delegate is required,
 *  through which instantaneous values can be obtained by the tracker when needed.
 *
 *  The implementation itself only implement the core SRG analytics specifications. Custom players must provide
 *  additional required information as required by SRG specifications. For easy integration you should rely on our
 *  SRG Media Player for your playback purposes, as automatic integration is provided.
 */
@interface SRGAnalyticsStreamTracker : NSObject

/**
 *  Create a tracker instance for the specified kind of stream.
 */
- (instancetype)initWithStreamType:(SRGAnalyticsStreamType)streamType delegate:(id<SRGAnalyticsStreamTrackerDelegate>)delegate;

/**
 *  Update the tracker with the specified stream state and information. Can be used if different position / labels
 *  than the ones obtained from the delegate are required.
 *
 *  @param state    The current player state.
 *  @param position The current player playback position, in milliseconds.
 *  @param labels   Additional detailed information.
 */
- (void)updateWithStreamState:(SRGAnalyticsStreamState)state
                     position:(NSTimeInterval)position
                       labels:(nullable SRGAnalyticsStreamLabels *)labels;

@end

@interface SRGAnalyticsStreamTracker (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
