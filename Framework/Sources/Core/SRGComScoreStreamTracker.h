//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGAnalyticsStreamTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface SRGComScoreStreamTracker : NSObject

- (instancetype)initWithStreamType:(SRGAnalyticsStreamType)streamType delegate:(id<SRGAnalyticsStreamTrackerDelegate>)delegate;

- (void)updateWithStreamState:(SRGAnalyticsStreamState)state
                     position:(NSTimeInterval)position
                       labels:(nullable SRGAnalyticsStreamLabels *)labels;

@end

NS_ASSUME_NONNULL_END
