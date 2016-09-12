//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGSegment+SRGAnalytics.h"

@concreteprotocol(SRGAnalyticsSegment)

- (NSDictionary *)srg_analyticsLabels
{
   return self.userInfo[SRGAnalyticsMediaPlayerDictionnaryKey]; 
}

@end
