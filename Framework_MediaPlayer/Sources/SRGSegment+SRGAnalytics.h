//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGMediaplayer/SRGSegment.h>
#import "SRGAnalyticsMediaPlayerConstants.h"
#import <libextobjc/EXTConcreteProtocol.h>

@protocol SRGAnalyticsSegment <SRGSegment>

@concrete

/**
 *  Analytics labels for the current played URL
 *  @return A dictionnary from userInfo[SRGAnalyticsMediaPlayerDictionnaryKey] value.
 */
@property (nonatomic, readonly) NSDictionary *srg_analyticsLabels;

@end
