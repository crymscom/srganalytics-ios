//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

@class SRGMediaPlayerController;
@protocol SRGSegment;

/**
 *  Collect data related to a media player controller being tracked
 */
@interface SRGMediaPlayerControllerTrackingInfo : NSObject

/**
 *  Create a tracking info instance bound to the specified media player controller
 */
- (instancetype)initWithMediaPlayerController:(SRGMediaPlayerController *)mediaPlayerController;

/**
 *  The media player controller to which the information is related to
 */
@property (nonatomic, readonly, weak) SRGMediaPlayerController *mediaPlayerController;

/**
 *  The current segment played by the controller, nil if none
 */
@property (nonatomic) id<SRGSegment> currentSegment;

/**
 *  Set to YES iff the next play / pause events must be skipped
 */
@property (nonatomic, getter=isSkippingNextEvents) BOOL skippingNextEvents;

/**
 *  Set to YES iff the user has selected a segment
 */
@property (nonatomic, getter=isUserSelected) BOOL userSelected;

@end
