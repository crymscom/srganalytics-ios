//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGMediaplayer/SRGSegment.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Protocol for segments conveying analytics information.
 *
 *  For more information, @see SRGMediaPlayerController+SRGAnalytics.h.
 */
@protocol SRGAnalyticsSegment <SRGSegment>

/**
 *  Analytics labels associated with the segments.
 */
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, NSString *> *srg_analyticsLabels;

/**
 *  Analytics ComScore labels associated with the segments.
 */
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, NSString *> *srg_comScoreLabels;

@end

NS_ASSUME_NONNULL_END
