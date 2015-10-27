//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface Segment : NSObject <RTSMediaSegment>

- (instancetype) initWithTimeRange:(CMTimeRange)timeRange name:(NSString *)name blocked:(BOOL)blocked;

@property (nonatomic, readonly, copy) NSString *name;

// Default is NO
@property (nonatomic, getter=isFullLength) BOOL fullLength;

// Default is YES
@property (nonatomic, getter=isVisible) BOOL visible;


@end
