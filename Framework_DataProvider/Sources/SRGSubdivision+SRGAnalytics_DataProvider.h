//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreMedia/CoreMedia.h>
#import <SRGDataProvider/SRGDataProvider.h>

@interface SRGSubdivision (SRGAnalytics_DataProvider)

/**
 *  The time range covered by the subdivision in the associated media.
 */
- (CMTimeRange)srg_timeRange;

@end
