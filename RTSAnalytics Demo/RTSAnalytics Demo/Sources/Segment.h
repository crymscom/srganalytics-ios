//
//  Created by Samuel Défago on 12/06/15.
//  Copyright (c) 2015 RTS. All rights reserved.
//

#import <RTSMediaPlayer/RTSMediaPlayer.h>

@interface Segment : NSObject <RTSMediaSegment>

- (instancetype) initWithTimeRange:(CMTimeRange)timeRange;

@end
