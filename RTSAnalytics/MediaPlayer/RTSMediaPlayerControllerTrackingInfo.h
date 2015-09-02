//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/RTSMediaSegment.h>
#import <Foundation/Foundation.h>

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

@end
