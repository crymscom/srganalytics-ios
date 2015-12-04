//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

@protocol RTSMediaSegment;
@class RTSMediaPlayerController;

/**
 *  Collect data related to a media player controller being tracked
 */
@interface RTSMediaPlayerControllerTrackingInfo : NSObject <NSCopying>

/**
 *  Create an instance for the specified player controller (mandatory)
 */
- (instancetype)initWithMediaPlayerController:(RTSMediaPlayerController *)mediaPlayerController NS_DESIGNATED_INITIALIZER;

/**
 *  The media player which the tracking info is related to
 */
@property (nonatomic, readonly, weak) RTSMediaPlayerController *mediaPlayerController;

/**
 *  The current segment played by the controller. Might be set to nil, in which case the currently playing full-length
 *  is considered instead
 */
@property (nonatomic) id<RTSMediaSegment> segment;

/**
 * Custom labels to be sent as well
 */
@property (nonatomic, readonly) NSDictionary *customLabels;

/**
 *  Set to YES iff the next play / pause events must be skipped
 */
@property (nonatomic, getter=isSkippingNextEvents) BOOL skippingNextEvents;

@end
