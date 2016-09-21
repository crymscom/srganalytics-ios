//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGMediaplayer/SRGSegment.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SRGAnalyticsSegment <SRGSegment>

/**
 *  Analytics labels for the current played segment
 */
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *srg_analyticsLabels;

@end

NS_ASSUME_NONNULL_END
