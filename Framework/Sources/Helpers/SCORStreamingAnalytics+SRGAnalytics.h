//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <ComScore/ComScore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SCORStreamingAnalyticsEvent) {
    SCORStreamingAnalyticsEventBufferStart,
    SCORStreamingAnalyticsEventBufferStop,
    SCORStreamingAnalyticsEventPlay,
    SCORStreamingAnalyticsEventPause,
    SCORStreamingAnalyticsEventEnd,
    SCORStreamingAnalyticsEventSeekStart
};

@interface SCORStreamingAnalytics (SRGAnalytics)

- (BOOL)srg_notifyEvent:(SCORStreamingAnalyticsEvent)event withPosition:(long)position;

@end

NS_ASSUME_NONNULL_END
