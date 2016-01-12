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
 *  Set to YES iff the next play / pause events must be skipped
 */
@property (nonatomic, getter=isSkippingNextEvents) BOOL skippingNextEvents;

/**
 *  Set to YES iff the user has selected a segment
 */
@property (nonatomic, getter=isUserSelected) BOOL userSelected;

@end
