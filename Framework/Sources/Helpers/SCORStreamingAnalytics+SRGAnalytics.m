//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SCORStreamingAnalytics+SRGAnalytics.h"

@implementation SCORStreamingAnalytics (SRGAnalytics)

- (BOOL)srg_notifyEvent:(SCORStreamingAnalyticsEvent)event withPosition:(long)position
{
    // Labels sent with -notify methods are only associated with the event and not persisted for other events (e.g.
    // heartbeats). We therefore must use label-less methods only.
    switch (event) {
        case SCORStreamingAnalyticsEventBufferStart: {
            return [self notifyBufferStartWithPosition:position];
            break;
        }
            
        case SCORStreamingAnalyticsEventBufferStop: {
            return [self notifyBufferStopWithPosition:position];
            break;
        }
            
        case SCORStreamingAnalyticsEventPlay: {
            return [self notifyPlayWithPosition:position];
            break;
        }
            
        case SCORStreamingAnalyticsEventPause: {
            return [self notifyPauseWithPosition:position];
            break;
        }
            
        case SCORStreamingAnalyticsEventEnd: {
            return [self notifyEndWithPosition:position];
            break;
        }
            
        case SCORStreamingAnalyticsEventSeekStart: {
            return [self notifySeekStartWithPosition:position];
            break;
        }
            
        default: {
            return NO;
            break;
        }
    }
}

@end
