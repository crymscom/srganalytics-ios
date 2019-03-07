//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SCORStreamingAnalytics+SRGAnalytics.h"

@implementation SCORStreamingAnalytics (SRGAnalytics)

- (BOOL)srg_notifyEvent:(SCORStreamingAnalyticsEvent)event withPosition:(long)position labels:(NSDictionary *)labels
{
    switch (event) {
        case SCORStreamingAnalyticsEventBufferStart: {
            return [self notifyBufferStartWithPosition:position labels:labels];
            break;
        }
            
        case SCORStreamingAnalyticsEventBufferStop: {
            return [self notifyBufferStopWithPosition:position labels:labels];
            break;
        }
            
        case SCORStreamingAnalyticsEventPlay: {
            return [self notifyPlayWithPosition:position labels:labels];
            break;
        }
            
        case SCORStreamingAnalyticsEventPause: {
            return [self notifyPauseWithPosition:position labels:labels];
            break;
        }
            
        case SCORStreamingAnalyticsEventEnd: {
            return [self notifyEndWithPosition:position labels:labels];
            break;
        }
            
        case SCORStreamingAnalyticsEventSeekStart: {
            return [self notifySeekStartWithPosition:position labels:labels];
            break;
        }
            
        default: {
            return NO;
            break;
        }
    }
}

@end
