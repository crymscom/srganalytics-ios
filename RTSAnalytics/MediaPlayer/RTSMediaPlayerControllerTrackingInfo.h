//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

@protocol RTSMediaSegment;

/**
 *  Collect data related to a media player controller being tracked
 */
@interface RTSMediaPlayerControllerTrackingInfo : NSObject

/**
 *  The current segment played by the controller, nil if none
 */
@property (nonatomic) id<RTSMediaSegment> currentSegment;

/**
 * The index of the segment being tracked, NSNotFound if none
 */
@property (nonatomic) NSUInteger currentSegmentIndex;

/**
 *  Set to YES iff the next play / pause events must be skipped
 */
@property (nonatomic, getter=isSkippingNextEvents) BOOL skippingNextEvents;

@end
