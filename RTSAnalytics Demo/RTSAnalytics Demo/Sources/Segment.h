//
//  Copyright (c) RTS. All rights reserved.
//
//  Licence information is available from the LICENCE file.
//

#import <SRGMediaPlayer/SRGMediaPlayer.h>

@interface Segment : NSObject <RTSMediaSegment>

- (instancetype) initWithTimeRange:(CMTimeRange)timeRange name:(NSString *)name blocked:(BOOL)blocked;

@property (nonatomic, readonly, copy) NSString *name;

@end
